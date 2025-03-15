const std = @import("std");
const mem = std.mem;
const List = @import("LinkedList.zig").LinkedList;

pub fn Stack(comptime T: type) type {
    return struct {
        const Self = @This();
        const NodeType = List(T).Node;
        pub const Error = error{} || mem.Allocator.Error;

        allocator: mem.Allocator,
        top: List(T),

        pub fn init(allocator: mem.Allocator) Self {
            return .{
                .allocator = allocator,
                .top = List(T).init(),
            };
        }

        pub fn deinit(self: *Self) void {
            while (self.top.removeFront()) |node| {
                self.allocator.destroy(node);
            }
        }

        pub fn push(self: *Self, item: T) Error!void {
            const node = try self.allocator.create(NodeType);
            node.* = NodeType.init(item);
            self.top.insertFront(node);
        }

        pub fn pop(self: *Self) ?T {
            if (self.top.removeFront()) |head| {
                defer self.allocator.destroy(head);
                return head.item;
            } else {
                return null;
            }
        }

        pub fn peek(self: *const Self) ?T {
            if (self.top.head) |head| {
                return head.item;
            } else {
                return null;
            }
        }

        pub fn len(self: *const Self) usize {
            return self.top.len;
        }
    };
}

pub fn StackUnmanaged(comptime T: type) type {
    return struct {
        const Self = @This();
        const NodeType = List(T).Node;
        pub const Error = error{} || mem.Allocator.Error;

        top: List(T),

        pub fn init() Self {
            return .{
                .top = List(T).init(),
            };
        }

        pub fn deinit(self: *Self, allocator: mem.Allocator) void {
            while (self.top.removeFront()) |node| {
                allocator.destroy(node);
            }
        }

        pub fn push(self: *Self, allocator: mem.Allocator, item: T) Error!void {
            const node = try allocator.create(NodeType);
            node.* = NodeType.init(item);
            self.top.insertFront(node);
        }

        pub fn pop(self: *Self, allocator: mem.Allocator) ?T {
            if (self.top.removeFront()) |head| {
                defer allocator.destroy(head);
                return head.item;
            } else {
                return null;
            }
        }

        pub fn peek(self: *const Self) ?T {
            if (self.top.head) |head| {
                return head.item;
            } else {
                return null;
            }
        }

        pub fn len(self: *const Self) usize {
            return self.top.len;
        }
    };
}

test "Stack push/pop/peek works" {
    const allocator = std.testing.allocator;
    var stack = StackUnmanaged(i32).init();
    defer stack.deinit(allocator);

    try stack.push(allocator, 10);
    try stack.push(allocator, 20);
    try stack.push(allocator, 30);

    try std.testing.expectEqual(30, stack.peek().?);
    try std.testing.expectEqual(30, stack.pop(allocator).?);
    try std.testing.expectEqual(20, stack.peek().?);
    try std.testing.expectEqual(20, stack.pop(allocator).?);
    try std.testing.expectEqual(10, stack.peek().?);
    try std.testing.expectEqual(10, stack.pop(allocator).?);

    try std.testing.expectEqual(null, stack.peek());
    try std.testing.expectEqual(null, stack.pop(allocator));
}

test "Stack pop on empty stack returns null" {
    const allocator = std.testing.allocator;
    var stack = StackUnmanaged(i32).init();
    defer stack.deinit(allocator);

    try std.testing.expectEqual(null, stack.pop(allocator));
    try std.testing.expectEqual(null, stack.peek());
}

test "Stack deinit cleans up remaining nodes" {
    const allocator = std.testing.allocator;
    var stack = StackUnmanaged(i32).init();

    try stack.push(allocator, 42);
    try stack.push(allocator, 99);
    stack.deinit(allocator);

    try std.testing.expectEqual(null, stack.peek());
}
