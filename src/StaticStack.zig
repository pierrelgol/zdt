const std = @import("std");

pub fn StaticStack(comptime T: type, comptime capacity: usize) type {
    return struct {
        const Self = @This();
        pub const Error = error{ Full, Empty };

        items: [capacity]T = undefined,
        len: usize = 0,

        pub const empty: Self = .{};

        pub fn push(self: *Self, item: T) Error!void {
            if (self.len >= capacity) return error.Full;
            defer self.len += 1;
            self.items[self.len] = item;
        }

        pub fn pop(self: *Self) ?T {
            if (self.len == 0) return null;
            self.len -= 1;
            return self.items[self.len];
        }

        pub fn peek(self: *Self) ?T {
            if (self.len == 0) return null;
            return self.items[self.len - 1];
        }
    };
}

test "Stack push/pop/peek works" {
    var stack = StaticStack(i32, 4).empty;

    try stack.push(10);
    try stack.push(20);
    try stack.push(30);

    try std.testing.expectEqual(30, stack.peek().?);
    try std.testing.expectEqual(30, stack.pop().?);
    try std.testing.expectEqual(20, stack.peek().?);
    try std.testing.expectEqual(20, stack.pop().?);
    try std.testing.expectEqual(10, stack.peek().?);
    try std.testing.expectEqual(10, stack.pop().?);

    try std.testing.expectEqual(null, stack.peek());
    try std.testing.expectEqual(null, stack.pop());
}

test "Stack pop on empty stack returns null" {
    var stack = StaticStack(i32, 1).empty;

    try std.testing.expectEqual(null, stack.pop());
    try std.testing.expectEqual(null, stack.peek());
}

test "Stack deinit cleans up remaining nodes" {
    var stack = StaticStack(i32, 2).empty;

    try stack.push(42);
    try stack.push(99);
    _ = stack.pop();
    _ = stack.pop();

    try std.testing.expectEqual(null, stack.peek());
}
