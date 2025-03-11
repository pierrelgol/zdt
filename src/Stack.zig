// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Stack.zig                                          :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/03/11 12:33:20 by pollivie          #+#    #+#             //
//   Updated: 2025/03/11 12:33:21 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const mem = std.mem;
const math = std.math;
const debug = std.debug;
const assert = debug.assert;

pub fn Stack(comptime T: type) type {
    return struct {
        const Self = @This();
        allocator: mem.Allocator,
        items: []T,
        capacity: usize,

        pub const Error = error{} || mem.Allocator.Error;

        pub fn init(allocator: mem.Allocator) Self {
            return .{
                .allocator = allocator,
                .items = &[_]T{},
                .capacity = 0,
            };
        }

        pub fn deinit(self: *Self) void {
            defer self.* = undefined;
            self.allocator.free(self.allocatedSlice());
        }

        pub fn push(self: *Self, item: T) Error!void {
            const ptr = try self.addOne();
            ptr.* = item;
        }

        pub fn pop(self: *Self) ?T {
            if (self.items.len == 0) return null;
            const val = self.items[self.items.len - 1];
            self.items.len -= 1;
            return val;
        }

        fn addOne(self: *Self) Error!*T {
            const newlen = self.items.len + 1;
            try self.ensureTotalCapacity(newlen);
            return self.addOneAssumeCapacity();
        }

        fn addOneAssumeCapacity(self: *Self) *T {
            assert(self.items.len < self.capacity);

            self.items.len += 1;
            return &self.items[self.items.len - 1];
        }

        fn allocatedSlice(self: *const Self) []T {
            return self.items[0..self.capacity];
        }

        fn ensureTotalCapacity(self: *Self, new_capacity: usize) Error!void {
            if (self.capacity >= new_capacity) return;
            return self.ensureTotalCapacityPrecise(growCapacity(self.capacity, new_capacity));
        }

        fn ensureTotalCapacityPrecise(self: *Self, new_capacity: usize) Error!void {
            if (@sizeOf(T) == 0) {
                self.capacity = math.maxInt(usize);
                return;
            }

            if (self.capacity >= new_capacity) return;

            const old_memory = self.allocatedSlice();
            if (self.allocator.remap(old_memory, new_capacity)) |new_memory| {
                self.items.ptr = new_memory.ptr;
                self.capacity = new_memory.len;
            } else {
                const new_memory = try self.allocator.alloc(T, new_capacity);
                @memcpy(new_memory[0..self.items.len], self.items);
                self.allocator.free(old_memory);
                self.items.ptr = new_memory.ptr;
                self.capacity = new_memory.len;
            }
        }

        const init_capacity = @as(comptime_int, @max(1, std.atomic.cache_line / @sizeOf(T)));

        fn growCapacity(current: usize, minimum: usize) usize {
            var new = current;
            while (true) {
                new +|= new / 2 + init_capacity;
                if (new >= minimum)
                    return new;
            }
        }
    };
}

pub fn StackUnamanaged(comptime T: type) type {
    return struct {
        const Self = @This();
        items: []T = undefined,
        capacity: usize = 0,

        pub const empty: Self = .{
            .items = undefined,
            .index = 0,
            .capacity = 0,
        };

        pub const Error = error{} || mem.Allocator.Error;

        pub fn deinit(self: *Self, allocator: mem.Allocator) void {
            defer self.* = undefined;
            allocator.free(self.allocatedSlice());
        }

        pub fn push(self: *Self, allocator: mem.Allocator, item: T) Error!void {
            const ptr = try self.addOne(allocator);
            ptr.* = item;
        }

        pub fn pop(self: *Self) ?T {
            if (self.items.len == 0) return null;
            const val = self.items[self.items.len - 1];
            self.items.len -= 1;
            return val;
        }

        fn addOne(self: *Self, gpa: mem.Allocator) Error!*T {
            const newlen = self.items.len + 1;
            try self.ensureTotalCapacity(gpa, newlen);
            return self.addOneAssumeCapacity();
        }

        fn addOneAssumeCapacity(self: *Self) *T {
            assert(self.items.len < self.capacity);

            self.items.len += 1;
            return &self.items[self.items.len - 1];
        }

        fn allocatedSlice(self: *const Self) []T {
            return self.items[0..self.capacity];
        }

        fn ensureTotalCapacity(self: *Self, gpa: mem.Allocator, new_capacity: usize) Error!void {
            if (self.capacity >= new_capacity) return;
            return self.ensureTotalCapacityPrecise(gpa, growCapacity(self.capacity, new_capacity));
        }

        fn ensureTotalCapacityPrecise(self: *Self, gpa: mem.Allocator, new_capacity: usize) Error!void {
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
                const new_memory = try gpa.alloc(T, new_capacity);
                @memcpy(new_memory[0..self.items.len], self.items);
                gpa.free(old_memory);
                self.items.ptr = new_memory.ptr;
                self.capacity = new_memory.len;
            }
        }

        const init_capacity = @as(comptime_int, @max(1, std.atomic.cache_line / @sizeOf(T)));

        fn growCapacity(current: usize, minimum: usize) usize {
            var new = current;
            while (true) {
                new +|= new / 2 + init_capacity;
                if (new >= minimum)
                    return new;
            }
        }
    };
}
