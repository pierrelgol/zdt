const std = @import("std");
const math = std.math;
const Order = math.Order;
const mem = std.mem;
const Allocator = mem.Allocator;
const assert = std.debug.assert;

pub fn PriorityQueueUnmanaged(comptime T: type, comptime Context: type, comptime compareFn: fn (context: Context, a: T, b: T) Order) type {
    return struct {
        const Self = @This();

        items: []T,
        cap: usize,
        context: Context,

        pub fn init(context: Context) Self {
            return Self{
                .items = &[_]T{},
                .cap = 0,
                .context = context,
            };
        }

        pub fn deinit(self: *Self, gpa: Allocator) void {
            defer self.* = undefined;
            gpa.free(self.allocatedSlice());
        }

        pub fn push(self: *Self, elem: T) !void {
            try self.ensureUnusedCapacity(1);
            pushAndBubbleUp(self, elem);
        }

        fn pushAndBubbleUp(self: *Self, elem: T) void {
            self.items.len += 1;
            self.items[self.items.len - 1] = elem;
            bubbleUp(self, self.items.len - 1);
        }

        fn bubbleUp(self: *Self, start_index: usize) void {
            const child = self.items[start_index];
            var child_index = start_index;
            while (child_index > 0) {
                const parent_index = ((child_index - 1) >> 1);
                const parent = self.items[parent_index];
                if (compareFn(self.context, child, parent) != .lt) break;
                self.items[child_index] = parent;
                child_index = parent_index;
            }
            self.items[child_index] = child;
        }

        pub fn addSlice(self: *Self, items: []const T) !void {
            try self.ensureUnusedCapacity(items.len);
            for (items) |e| {
                self.pushAndBubbleUp(e);
            }
        }

        pub fn peek(self: *Self) ?T {
            return if (self.items.len > 0) self.items[0] else null;
        }

        pub fn popOrNull(self: *Self) ?T {
            return if (self.items.len > 0) self.pop() else null;
        }

        pub fn pop(self: *Self) T {
            return self.popAndUpdate(0);
        }

        pub fn popAndUpdate(self: *Self, index: usize) T {
            assert(self.items.len > index);
            const last = self.items[self.items.len - 1];
            const item = self.items[index];
            self.items[index] = last;
            self.items.len -= 1;

            if (index == self.items.len) {} else if (index == 0) {
                bubbleDown(self, index);
            } else {
                const parent_index = ((index - 1) >> 1);
                const parent = self.items[parent_index];
                if (compareFn(self.context, last, parent) == .gt) {
                    bubbleDown(self, index);
                } else {
                    bubbleUp(self, index);
                }
            }

            return item;
        }

        pub fn count(self: Self) usize {
            return self.items.len;
        }

        pub fn capacity(self: Self) usize {
            return self.cap;
        }

        fn allocatedSlice(self: Self) []T {
            return self.items.ptr[0..self.cap];
        }

        fn bubbleDown(self: *Self, target_index: usize) void {
            const target_element = self.items[target_index];
            var index = target_index;
            while (true) {
                var lesser_child_i = (std.math.mul(usize, index, 2) catch break) | 1;
                if (!(lesser_child_i < self.items.len)) break;

                const next_child_i = lesser_child_i + 1;
                if (next_child_i < self.items.len and compareFn(self.context, self.items[next_child_i], self.items[lesser_child_i]) == .lt) {
                    lesser_child_i = next_child_i;
                }

                if (compareFn(self.context, target_element, self.items[lesser_child_i]) == .lt) break;

                self.items[index] = self.items[lesser_child_i];
                index = lesser_child_i;
            }
            self.items[index] = target_element;
        }

        pub fn fromOwnedSlice(items: []T, context: Context) Self {
            var self = Self{
                .items = items,
                .cap = items.len,
                .allocator = allocator,
                .context = context,
            };

            var i = self.items.len >> 1;
            while (i > 0) {
                i -= 1;
                self.bubbleDown(i);
            }
            return self;
        }

        pub fn ensureTotalCapacity(self: *Self, new_capacity: usize) !void {
            var better_capacity = self.cap;
            if (better_capacity >= new_capacity) return;
            while (true) {
                better_capacity += better_capacity / 2 + 8;
                if (better_capacity >= new_capacity) break;
            }
            try self.ensureTotalCapacityPrecise(better_capacity);
        }

        pub fn ensureTotalCapacityPrecise(self: *Self, new_capacity: usize) !void {
            if (self.capacity() >= new_capacity) return;

            const old_memory = self.allocatedSlice();
            const new_memory = try self.allocator.realloc(old_memory, new_capacity);
            self.items.ptr = new_memory.ptr;
            self.cap = new_memory.len;
        }

        pub fn ensureUnusedCapacity(self: *Self, additional_count: usize) !void {
            return self.ensureTotalCapacity(self.items.len + additional_count);
        }

        pub fn shrinkAndFree(self: *Self, new_capacity: usize) void {
            assert(new_capacity <= self.cap);

            assert(new_capacity >= self.items.len);

            const old_memory = self.allocatedSlice();
            const new_memory = self.allocator.realloc(old_memory, new_capacity) catch |e| switch (e) {
                error.OutOfMemory => {
                    return;
                },
            };

            self.items.ptr = new_memory.ptr;
            self.cap = new_memory.len;
        }

        pub fn clearRetainingCapacity(self: *Self) void {
            self.items.len = 0;
        }

        pub fn clearAndFree(self: *Self) void {
            self.allocator.free(self.allocatedSlice());
            self.items.len = 0;
            self.cap = 0;
        }

        pub fn update(self: *Self, elem: T, new_elem: T) !void {
            const update_index = blk: {
                var idx: usize = 0;
                while (idx < self.items.len) : (idx += 1) {
                    const item = self.items[idx];
                    if (compareFn(self.context, item, elem) == .eq) break :blk idx;
                }
                return error.ElementNotFound;
            };
            const old_elem: T = self.items[update_index];
            self.items[update_index] = new_elem;
            switch (compareFn(self.context, new_elem, old_elem)) {
                .lt => bubbleUp(self, update_index),
                .gt => bubbleDown(self, update_index),
                .eq => {},
            }
        }

        pub const Iterator = struct {
            queue: *Self,
            count: usize,

            pub fn next(it: *Iterator) ?T {
                if (it.count >= it.queue.items.len) return null;
                const out = it.count;
                it.count += 1;
                return it.queue.items[out];
            }

            pub fn reset(it: *Iterator) void {
                it.count = 0;
            }
        };

        pub fn iterator(self: *Self) Iterator {
            return Iterator{
                .queue = self,
                .count = 0,
            };
        }
    };
}
