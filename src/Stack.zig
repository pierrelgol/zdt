const std = @import("std");
const math = std.math;
const mem = std.mem;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayListUnmanaged;
const assert = std.debug.assert;

pub fn StackUnmanaged(comptime T: type) type {
    return StackAlignedUnmanaged(T, null);
}

pub fn StackAlignedUnmanaged(comptime T: type, comptime alignment: ?u29) type {
    if (alignment) |a| {
        if (a == @alignOf(T)) {
            return StackAlignedUnmanaged(T, null);
        }
    }
    return struct {
        const Self = @This();

        items: Slice = &[_]T{},
        capacity: usize = 0,

        pub const Slice = if (alignment) |a| ([]align(a) T) else []T;

        pub const empty: Self = .{
            .items = &.{},
            .capacity = 0,
        };

        pub fn initCapacity(gpa: Allocator, capacity: usize) Allocator.Error!Self {
            var self: Self = .empty;
            try self.ensureTotalCapacityPrecise(gpa, capacity);
            return self;
        }

        pub fn initBuffer(buffer: Slice) Self {
            return .{
                .items = buffer[0..0],
                .capacity = buffer.len,
            };
        }

        pub fn deinit(self: *Self, gpa: Allocator) void {
            gpa.free(self.allocatedSlice());
            self.* = undefined;
        }

        pub fn push(self: *Self, item: T) Allocator.Error!void {
            const new_item_ptr = try self.addOne();
            new_item_ptr.* = item;
        }

        pub fn pop(self: *Self) ?T {
            if (self.items.len == 0) return null;
            const val = self.items[self.items.len - 1];
            self.items.len -= 1;
            return val;
        }

        pub fn top(self: *Self) ?T {
            if (self.items.len == 0) return null;
            return self.items[self.items.len - 1];
        }

        pub fn clone(self: Self, gpa: Allocator) Allocator.Error!Self {
            var cloned = try Self.initCapacity(gpa, self.capacity);
            cloned.appendSliceAssumeCapacity(self.items);
            return cloned;
        }

        pub fn appendSlice(self: *Self, gpa: Allocator, items: []const T) Allocator.Error!void {
            try self.ensureUnusedCapacity(gpa, items.len);
            self.appendSliceAssumeCapacity(items);
        }

        pub fn appendSliceAssumeCapacity(self: *Self, items: []const T) void {
            const old_len = self.items.len;
            const new_len = old_len + items.len;
            assert(new_len <= self.capacity);
            self.items.len = new_len;
            @memcpy(self.items[old_len..][0..items.len], items);
        }

        pub fn addOne(self: *Self, gpa: Allocator) Allocator.Error!*T {
            const newlen = self.items.len + 1;
            try self.ensureTotalCapacityPrecise(gpa, newlen);
            return self.addOneAssumeCapacity();
        }

        pub fn addOneAssumeCapacity(self: *Self) *T {
            assert(self.items.len < self.capacity);

            self.items.len += 1;
            return &self.items[self.items.len - 1];
        }

        pub fn ensureTotalCapacityPrecise(self: *Self, gpa: Allocator, new_capacity: usize) Allocator.Error!void {
            if (@sizeOf(T) == 0) {
                self.capacity = math.maxInt(usize);
                return;
            }

            if (self.capacity >= new_capacity) return;

            const old_memory = self.allocatedSlice();
            if (gpa.remap(old_memory, new_capacity)) |new_memory| {
                self.items.ptr = new_memory.ptr;
                self.capacity = new_memory.len;
            } else {
                const new_memory = try gpa.alignedAlloc(T, alignment, new_capacity);
                @memcpy(new_memory[0..self.items.len], self.items);
                gpa.free(old_memory);
                self.items.ptr = new_memory.ptr;
                self.capacity = new_memory.len;
            }
        }

        pub fn resize(self: *Self, gpa: Allocator, new_len: usize) Allocator.Error!void {
            try self.ensureTotalCapacityPrecise(gpa, new_len);
            self.items.len = new_len;
        }

        pub fn shrinkAndFree(self: *Self, gpa: Allocator, new_len: usize) void {
            assert(new_len <= self.items.len);

            if (@sizeOf(T) == 0) {
                self.items.len = new_len;
                return;
            }

            const old_memory = self.allocatedSlice();
            if (gpa.remap(old_memory, new_len)) |new_items| {
                self.capacity = new_items.len;
                self.items = new_items;
                return;
            }

            const new_memory = gpa.alignedAlloc(T, alignment, new_len) catch |e| switch (e) {
                error.OutOfMemory => {
                    self.items.len = new_len;
                    return;
                },
            };

            @memcpy(new_memory, self.items[0..new_len]);
            gpa.free(old_memory);
            self.items = new_memory;
            self.capacity = new_memory.len;
        }

        pub fn clearRetainingCapacity(self: *Self) void {
            self.items.len = 0;
        }

        pub fn clearAndFree(self: *Self, gpa: Allocator) void {
            gpa.free(self.allocatedSlice());
            self.items.len = 0;
            self.capacity = 0;
        }

        pub fn shrinkRetainingCapacity(self: *Self, new_len: usize) void {
            assert(new_len <= self.items.len);
            self.items.len = new_len;
        }

        pub fn toOwnedSlice(self: *Self, gpa: Allocator) Allocator.Error!Slice {
            const old_memory = self.allocatedSlice();
            if (gpa.remap(old_memory, self.items.len)) |new_items| {
                self.* = .empty;
                return new_items;
            }

            const new_memory = try gpa.alignedAlloc(T, alignment, self.items.len);
            @memcpy(new_memory, self.items);
            self.clearAndFree(gpa);
            return new_memory;
        }

        pub fn fromOwnedSlice(slice: Slice) Self {
            return Self{
                .items = slice,
                .capacity = slice.len,
            };
        }

        pub fn allocatedSlice(self: *const Self) []T {
            return self.items.ptr[0..self.capacity];
        }

        fn growCapacity(current: usize, minimum: usize) usize {
            var new = current;
            while (true) {
                new +|= new / 2 + init_capacity;
                if (new >= minimum)
                    return new;
            }
        }

        const init_capacity = @as(comptime_int, @max(1, std.atomic.cache_line / @sizeOf(T)));
    };
}
