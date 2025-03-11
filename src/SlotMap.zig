// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   SlotMap.zig                                        :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/03/11 11:25:09 by pollivie          #+#    #+#             //
//   Updated: 2025/03/11 11:25:10 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const mem = std.mem;
const math = std.math;
const ArrayList = std.ArrayListUnmanaged;
const Stack = @import("Stack.zig").StackUnamanaged;
const debug = std.debug;
const assert = debug.assert;

pub fn SlotMap(comptime T: type) type {
    return struct {
        pub const Error = error{} || mem.Allocator.Error;
        const Self = @This();

        allocator: mem.Allocator,
        objects: ArrayList(T),
        used_slots: ArrayList(Slot),
        free_slots: Stack(SlotIndex),

        pub fn init(allocator: mem.Allocator) Self {
            return .{
                .allocator = allocator,
                .objects = ArrayList(T).empty,
                .used_slots = ArrayList(Slot).empty,
                .free_slots = Stack(SlotIndex).empty,
            };
        }

        pub fn deinit(self: *Self) void {
            defer self.* = undefined;
            self.objects.deinit(self.allocator);
            self.used_slots.deinit(self.allocator);
            self.free_slots.deinit(self.allocator);
        }

        pub fn put(self: *Self, item: T) Error!Handle {
            var index: usize = 0;
            if (self.free_slots.pop()) |slot_idx| {
                self.slotAt(slot_idx).generation += 1;
                self.objectAt(self.slotAt(slot_idx).index).* = item;
                index = slot_idx;
            } else {
                const new_slot: Slot = .{ .generation = 0, .index = self.objectLen() };
                index = self.slotLen();
                try self.objects.append(self.allocator, item);
                try self.used_slots.append(self.allocator, new_slot);
            }
            return .{ .generation = self.slotAt(index).generation, .index = index };
        }

        pub fn get(self: *const Self, handle: Handle) ?*T {
            if (self.isValidHandle(handle)) {
                return self.objectAt(self.slotAt(handle.index).index);
            } else {
                return null;
            }
        }

        pub fn remove(self: *Self, handle: Handle) Error!void {
            if (!self.isValidHandle(handle)) return;

            const curr = self.slotAt(handle.index).index;
            const last = self.objectLen() - 1;

            self.slotAt(handle.index).generation += 1;
            if (curr != last) {
                self.objects.swapRemove(curr);
                self.slotAt(self.slotFromObjectIndex(last)).index = curr;
            } else {
                self.objects.swapRemove(curr);
            }

            try self.free_slots.push(self.allocator, handle.index);
        }

        fn slotFromObjectIndex(self: *Self, index: ObjectIndex) usize {
            return result: for (self.used_slots.items, 0..) |slot, i| {
                if (slot.index == index) break :result i;
            } else unreachable;
        }

        pub fn isValidHandle(self: *const Self, handle: Handle) bool {
            return self.slotAt(handle.index).generation == handle.generation;
        }

        inline fn slotLen(self: *const Self) usize {
            return self.used_slots.items.len;
        }

        inline fn objectLen(self: *const Self) usize {
            return self.objects.items.len;
        }

        inline fn lastSlot(self: *Self) *Slot {
            return &self.used_slots.items[self.used_slots.items.len - 1];
        }

        inline fn slotAt(self: *Self, index: usize) *Slot {
            return &self.used_slots.items[index];
        }

        inline fn objectAt(self: *Self, index: usize) *T {
            return &self.objects.items[index];
        }

        pub const Slot = struct {
            generation: usize = 0,
            index: ObjectIndex = 0,
        };

        pub const Handle = struct {
            generation: usize = 0,
            index: SlotIndex = 0,
        };

        pub const SlotIndex = enum(usize) { _ };
        pub const ObjectIndex = enum(usize) { _ };

        pub const empty: Self = .{
            .objects = .empty,
            .used_slots = .empty,
            .free_slots = .empty,
        };
    };
}

pub fn SlotMapUnamanaged(comptime T: type) type {
    return struct {
        pub const Error = error{} || mem.Allocator.Error;
        const Self = @This();

        objects: ArrayList(T),
        used_slots: ArrayList(Slot),
        free_slots: Stack(SlotIndex),

        pub fn put(self: *Self, allocator: mem.Allocator, item: T) Error!Handle {
            var index: usize = 0;
            if (self.free_slots.pop()) |slot_idx| {
                self.slotAt(slot_idx).generation += 1;
                self.objectAt(self.slotAt(slot_idx).index).* = item;
                index = slot_idx;
            } else {
                const new_slot: Slot = .{ .generation = 0, .index = self.objectLen() };
                index = self.slotLen();
                try self.objects.append(allocator, item);
                try self.used_slots.append(allocator, new_slot);
            }
            return .{ .generation = self.slotAt(index).generation, .index = index };
        }

        pub fn get(self: *const Self, handle: Handle) ?*T {
            if (self.isValidHandle(handle)) {
                return self.objectAt(self.slotAt(handle.index).index);
            } else {
                return null;
            }
        }

        pub fn remove(self: *Self, allocator: mem.Allocator, handle: Handle) Error!void {
            if (!self.isValidHandle(handle)) return;

            const curr = self.slotAt(handle.index).index;
            const last = self.objectLen() - 1;

            self.slotAt(handle.index).generation += 1;
            if (curr != last) {
                self.objects.swapRemove(curr);
                self.slotAt(self.slotFromObjectIndex(last)).index = curr;
            } else {
                self.objects.swapRemove(curr);
            }

            try self.free_slots.push(allocator, handle.index);
        }

        fn slotFromObjectIndex(self: *Self, index: ObjectIndex) usize {
            return result: for (self.used_slots.items, 0..) |slot, i| {
                if (slot.index == index) break :result i;
            } else unreachable;
        }

        pub fn isValidHandle(self: *const Self, handle: Handle) bool {
            return self.slotAt(handle.index).generation == handle.generation;
        }

        inline fn slotLen(self: *const Self) usize {
            return self.used_slots.items.len;
        }

        inline fn objectLen(self: *const Self) usize {
            return self.objects.items.len;
        }

        inline fn lastSlot(self: *Self) *Slot {
            return &self.used_slots.items[self.used_slots.items.len - 1];
        }

        inline fn slotAt(self: *Self, index: usize) *Slot {
            return &self.used_slots.items[index];
        }

        inline fn objectAt(self: *Self, index: usize) *T {
            return &self.objects.items[index];
        }

        pub const Slot = struct {
            generation: usize = 0,
            index: ObjectIndex = 0,
        };

        pub const Handle = struct {
            generation: usize = 0,
            index: SlotIndex = 0,
        };

        pub const SlotIndex = enum(usize) { _ };
        pub const ObjectIndex = enum(usize) { _ };

        pub const empty: Self = .{
            .objects = .empty,
            .used_slots = .empty,
            .free_slots = .empty,
        };
    };
}
