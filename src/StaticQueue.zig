const std = @import("std");

pub fn StaticQueue(comptime T: type, comptime capacity: usize) type {
    return struct {
        const Self = @This();
        pub const Error = error{ Full, Empty };

        items: [capacity]T = undefined,
        len: usize = 0,

        pub const empty: Self = .{};

        pub fn push(self: *Self, item: T) Error!void {
            if (self.len >= capacity) return error.Full;
            self.items[self.len] = item;
            self.len += 1;
        }

        pub fn pop(self: *Self) ?T {
            if (self.len == 0) return null;
            const result = self.items[0];
            std.mem.copyForwards(T, self.items[0 .. self.len - 1], self.items[1..self.len]);
            self.len -= 1;
            return result;
        }

        pub fn peek(self: *Self) ?T {
            if (self.len == 0) return null;
            return self.items[0];
        }
    };
}

test "Queue push/pop/peek works" {
    var queue = StaticQueue(i32, 4).empty;

    try queue.push(10);
    try queue.push(20);
    try queue.push(30);

    // In a FIFO, the first element pushed (10) should be at the front.
    try std.testing.expectEqual(10, queue.peek().?);
    try std.testing.expectEqual(10, queue.pop().?);
    try std.testing.expectEqual(20, queue.peek().?);
    try std.testing.expectEqual(20, queue.pop().?);
    try std.testing.expectEqual(30, queue.peek().?);
    try std.testing.expectEqual(30, queue.pop().?);

    try std.testing.expectEqual(null, queue.peek());
    try std.testing.expectEqual(null, queue.pop());
}

test "Queue pop on empty queue returns null" {
    var queue = StaticQueue(i32, 1).empty;

    try std.testing.expectEqual(null, queue.pop());
    try std.testing.expectEqual(null, queue.peek());
}

test "Queue deinit cleans up remaining nodes" {
    var queue = StaticQueue(i32, 2).empty;

    try queue.push(42);
    try queue.push(99);
    _ = queue.pop();
    _ = queue.pop();

    try std.testing.expectEqual(null, queue.peek());
}
