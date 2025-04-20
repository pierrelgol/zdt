const std = @import("std");
const ArrayList = std.ArrayListUnmanaged;
const HashMap = std.AutoArrayHashMapUnmanaged;
const Allocator = std.mem.Allocator;

pub fn RefPool(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: Allocator,
        objects: ArrayList(T),
        slots: HashMap(Slot, Slot),
        empty: ArrayList(Slot),

        pub const Ref = usize;

        pub const Slot = struct {
            generation: usize = 0,
            object: usize = 0,
        };

        pub fn init(allocator: Allocator) Self {
            return .{
                .allocator = allocator,
                .objects = ArrayList(T).empty,
                .slots = HashMap(Slot, Slot).empty,
                .empty = ArrayList(Slot).empty,
            };
        }

        pub fn deinit(self: *Self) void {
            self.objects.deinit(self.allocator);
            self.empty.deinit(self.allocator);
            self.slots.deinit(self.allocator);
        }

        pub const AllocResult = struct {
            slot: Slot,
            ptr: *T,
        };

        pub fn alloc(self: *Self) AllocResult {
            if (self.empty.pop()) |free_slot| {
                if (self.slots.getEntry(free_slot)) |slot| {
                    slot.value_ptr.generation += 1;
                    slot.key_ptr.* = slot.value_ptr.*;
                    return .{
                        .slot = slot.key_ptr.*,
                        .ptr = &self.objects.items[slot.value_ptr.object],
                    };
                }
            }
        }

        pub fn free(self: *Self, slot: Slot) ?*T {
            if (self.slots.getEntry(slot)) |used_slot| {
                if (slot.generation == used_slot.value_ptr.generation) {
                    used_slot.value_ptr.generation += 1;
                    self.empty.append(self.allocator, slot);
                    return &self.objects.items[used_slot.value_ptr.object];
                }
            } else {
                return null;
            }
        }
    };
}
