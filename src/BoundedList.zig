const std = @import("std");

pub fn BoundedList(comptime T: type, capacity: usize) type {
    return struct {
        pub const Error = error{ Full, Empty };
        const Self = @This();

        nodes: [capacity]Node = undefined,
        len: usize = 0,
        head: ?*Node = null,
        tail: ?*Node = null,

        pub const Node = struct {
            next: ?*Node = null,
            item: T = undefined,

            pub fn init(from: *Node, item: T) void {
                from.* = .{
                    .next = null,
                    .item = item,
                };
            }

            pub fn insertChild(self: *Node, new_node: *Node) void {
                new_node.next = self.next;
                self.next = new_node;
            }

            pub fn removeChild(self: *Node) ?*Node {
                const child = self.next orelse return null;
                self.next = child.next;
                return child;
            }

            pub fn findLast(self: *Node) *Node {
                var current = self;
                while (current.next) |next| {
                    current = next;
                }
                return current;
            }

            pub fn countChildren(self: *const Node) usize {
                var count: usize = 0;
                var current = self.next;
                while (current) |n| {
                    count += 1;
                    current = n.next;
                }
                return count;
            }

            pub fn getNthChildren(self: *const Node, nth: usize) ?*Node {
                var count: usize = 0;
                var current = self.next;
                while (current) |n| {
                    if (count == nth) return current;
                    count += 1;
                    current = n.next;
                }
                return null;
            }

            pub fn reverse(indirect: *?*Node) void {
                if (indirect.* == null) {
                    return;
                }
                var current: *Node = indirect.*.?;
                while (current.next) |next| {
                    current.next = next.next;
                    next.next = indirect.*;
                    indirect.* = next;
                }
            }
        };

        pub const empty: Self = .{
            .nodes = undefined,
            .head = null,
            .tail = null,
            .len = 0,
        };

        fn makeNode(self: *Self, item: T) Error!*Node {
            if (self.len >= self.nodes.len) return error.Full;
            return Node.init(&self.nodes[self.len], item);
        }

        pub fn push(self: *Self, item: T) Error!void {
            if (self.tail) |tail| {
                const node = try self.makeNode(item);
                tail.insertChild(node);
                self.tail = node;
                self.len += 1;
            } else {
                const node = try self.makeNode(item);
                self.head = node;
                self.tail = node;
                node.next = null;
                self.len += 1;
            }
        }

        pub fn pop(self: *Self) ?*Node {
            return switch (self.len) {
                0 => null,
                1 => node: {
                    const n = self.head orelse unreachable;
                    self.head = null;
                    self.tail = null;
                    break :node n;
                },
                else => node: {
                    var curr = self.head orelse unreachable;
                    while (curr.next != self.tail) : (curr = curr.next.?) {}
                    const old = curr.removeChild();
                    self.tail = curr;
                    self.len -= 1;
                    break :node old;
                },
            };
        }
    };
}
