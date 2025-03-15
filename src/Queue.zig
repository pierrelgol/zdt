const std = @import("std");
const mem = std.mem;
const List = @import("LinkedList.zig").LinkedList;

pub fn Queue(comptime T: type) type {
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
            self.top.insertBack(node);
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

pub fn QueueUnmanaged(comptime T: type) type {
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
            self.top.insertBack(node);
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

test "QueueUnmanaged push/pop/peek works" {
    const allocator = std.testing.allocator;
    var queue = QueueUnmanaged(i32).init();
    try queue.push(allocator, 10);
    try queue.push(allocator, 20);
    try queue.push(allocator, 30);

    // FIFO: first pushed (10) should be at the front.
    try std.testing.expectEqual(10, queue.peek().?);
    try std.testing.expectEqual(10, queue.pop(allocator).?);
    try std.testing.expectEqual(20, queue.peek().?);
    try std.testing.expectEqual(20, queue.pop(allocator).?);
    try std.testing.expectEqual(30, queue.peek().?);
    try std.testing.expectEqual(30, queue.pop(allocator).?);

    try std.testing.expectEqual(null, queue.peek());
    try std.testing.expectEqual(null, queue.pop(allocator));
}

test "QueueUnmanaged pop on empty queue returns null" {
    const allocator = std.testing.allocator;
    var queue = QueueUnmanaged(i32).init();
    try std.testing.expectEqual(null, queue.pop(allocator));
    try std.testing.expectEqual(null, queue.peek());
}

test "QueueUnmanaged deinit cleans up remaining nodes" {
    const allocator = std.testing.allocator;
    var queue = QueueUnmanaged(i32).init();
    try queue.push(allocator, 42);
    try queue.push(allocator, 99);
    // Instead of popping all elements, we call deinit to clean up.
    queue.deinit(allocator);
    try std.testing.expectEqual(null, queue.peek());
}
