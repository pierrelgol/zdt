const std = @import("std");
const mem = std.mem;
const heap = std.heap;
const math = std.math;
const testing = std.testing;
const debug = std.debug;
const assert = std.debug.assert;

pub fn LinkedList(comptime T: type) type {
    return struct {
        const Self = @This();

        head: ?*Node = null,
        tail: ?*Node = null,
        len: usize = 0,

        pub fn init() Self {
            return .{
                .head = null,
                .tail = null,
                .len = 0,
            };
        }

        pub fn isEmpty(self: *Self) bool {
            return self.len == 0;
        }

        pub fn insertFront(self: *Self, node: *Node) void {
            if (self.head) |_| {
                node.next = self.head;
                self.head = node;
            } else {
                self.head = node;
                self.tail = node;
                node.next = null;
            }
            self.len += 1;
        }

        pub fn insertBack(self: *Self, node: *Node) void {
            if (self.tail) |tail| {
                tail.insertChild(node);
                self.tail = node;
                self.len += 1;
            } else {
                self.insertFront(node);
            }
        }

        pub fn insertAt(self: *Self, node: *Node, index: usize) void {
            if (index == 0) {
                return self.insertFront(node);
            } else if (index >= self.len) {
                return self.insertBack(node);
            } else {
                var current = self.head.?;
                var i: usize = 0;
                while (i < index - 1) : (i += 1) {
                    current = current.next.?;
                }
                current.insertChild(node);
                self.len += 1;
            }
        }

        pub fn removeFront(self: *Self) ?*Node {
            if (self.isEmpty()) {
                return null;
            } else {
                const node = self.head.?;
                self.head = node.next;
                node.next = null;
                self.len -= 1;
                if (self.len == 0) {
                    self.tail = null;
                }
                return node;
            }
        }

        pub fn removeBack(self: *Self) ?*Node {
            if (self.isEmpty()) {
                return null;
            } else if (self.len == 1) {
                const node = self.head.?;
                self.head = null;
                self.tail = null;
                self.len = 0;
                return node;
            } else {
                var current = self.head.?;
                while (current.next != self.tail) : (current = current.next.?) {}
                const old_tail = current.removeChild() orelse null;
                self.tail = current;
                self.len -= 1;
                return old_tail;
            }
        }

        pub fn removeAt(self: *Self, index: usize) ?*Node {
            if (index == 0) return self.removeFront();
            if (index >= self.len) return null;
            var current = self.head.?;
            var i: usize = 0;
            while (i < index - 1) : (i += 1) {
                current = current.next.?;
            }
            const removed = current.removeChild() orelse null;
            self.len -= 1;
            if (current.next == null) {
                self.tail = current;
            }
            return removed;
        }

        pub const Node = struct {
            next: ?*Node = null,
            item: T,

            pub fn init(item: T) Node {
                return .{
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

        pub const Iterator = struct {
            curr: ?*Node,

            pub fn init(node: ?*Node) Iterator {
                return .{
                    .curr = node,
                };
            }

            pub fn next(self: *Iterator) ?T {
                if (self.curr) |node| {
                    defer self.curr = node.next;
                    return node.item;
                } else {
                    return null;
                }
            }
        };

        pub fn iterator(self: *Self) Iterator {
            return Iterator.init(self.head);
        }
    };
}

test "simple" {
    var gpa: heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();

    var list = LinkedList(u8).init();
    const Node = LinkedList(u8).Node;

    var n1 = Node.init('a');
    var n2 = Node.init('b');
    var n3 = Node.init('c');
    var n4 = Node.init('d');
    var n5 = Node.init('e');

    list.insertFront(&n1);
    list.insertFront(&n2);
    list.insertFront(&n3);
    list.insertFront(&n4);
    list.insertFront(&n5);

    const test_case = [_]u8{ 'e', 'd', 'c', 'b', 'a' };
    var it = list.iterator();
    for (test_case) |case| {
        if (it.next()) |v| {
            try testing.expect(v == case);
        }
    }
}

test "insertBack and iterator" {
    var list = LinkedList(u8).init();
    const Node = LinkedList(u8).Node;

    var n1 = Node.init('x');
    var n2 = Node.init('y');
    var n3 = Node.init('z');

    list.insertBack(&n1);
    list.insertBack(&n2);
    list.insertBack(&n3);

    const expected = [_]u8{ 'x', 'y', 'z' };
    var it = list.iterator();
    for (expected) |ch| {
        try testing.expect(it.next() orelse ' ' == ch);
    }
}

test "removeFront" {
    var list = LinkedList(u8).init();
    const Node = LinkedList(u8).Node;

    var n1 = Node.init('1');
    var n2 = Node.init('2');
    var n3 = Node.init('3');

    list.insertBack(&n1);
    list.insertBack(&n2);
    list.insertBack(&n3);

    var removed = list.removeFront() orelse unreachable;
    try testing.expect(removed.item == '1');

    removed = list.removeFront() orelse unreachable;
    try testing.expect(removed.item == '2');

    removed = list.removeFront() orelse unreachable;
    try testing.expect(removed.item == '3');

    try testing.expect(list.isEmpty());
}

test "removeBack" {
    var list = LinkedList(u8).init();
    const Node = LinkedList(u8).Node;

    var n1 = Node.init('1');
    var n2 = Node.init('2');
    var n3 = Node.init('3');

    list.insertBack(&n1);
    list.insertBack(&n2);
    list.insertBack(&n3);

    var removed = list.removeBack() orelse unreachable;
    try testing.expect(removed.item == '3');

    removed = list.removeBack() orelse unreachable;
    try testing.expect(removed.item == '2');

    removed = list.removeBack() orelse unreachable;
    try testing.expect(removed.item == '1');

    try testing.expect(list.isEmpty());
}

test "insertAt" {
    var list = LinkedList(u8).init();
    const Node = LinkedList(u8).Node;

    var n1 = Node.init('a');
    var n2 = Node.init('b');
    var n3 = Node.init('c');
    var n4 = Node.init('d');

    list.insertBack(&n1);
    list.insertAt(&n2, 0);
    list.insertAt(&n3, 1);
    list.insertAt(&n4, 10);

    const expected = [_]u8{ 'b', 'c', 'a', 'd' };
    var it = list.iterator();
    for (expected) |ch| {
        try testing.expect(it.next() orelse ' ' == ch);
    }
}

test "removeAt" {
    var list = LinkedList(u8).init();
    const Node = LinkedList(u8).Node;

    var n1 = Node.init('a');
    var n2 = Node.init('b');
    var n3 = Node.init('c');
    var n4 = Node.init('d');

    list.insertBack(&n1);
    list.insertBack(&n2);
    list.insertBack(&n3);
    list.insertBack(&n4);

    var removed = list.removeAt(1) orelse unreachable;
    try testing.expect(removed.item == 'b');

    removed = list.removeAt(2) orelse unreachable;
    try testing.expect(removed.item == 'd');

    removed = list.removeAt(1) orelse unreachable;
    try testing.expect(removed.item == 'c');

    var it = list.iterator();
    try testing.expect(it.next() orelse ' ' == 'a');
    try testing.expect(it.next() == null);
}

test "reverse" {
    var list = LinkedList(u8).init();
    const Node = LinkedList(u8).Node;

    var n1 = Node.init('1');
    var n2 = Node.init('2');
    var n3 = Node.init('3');

    list.insertBack(&n1);
    list.insertBack(&n2);
    list.insertBack(&n3);

    Node.reverse(&list.head);
    if (list.head) |head| {
        list.tail = head.findLast();
    }

    const expected = [_]u8{ '3', '2', '1' };
    var it = list.iterator();
    for (expected) |ch| {
        try testing.expect(it.next() orelse ' ' == ch);
    }
}

test "remove from empty list" {
    var list = LinkedList(u8).init();
    try testing.expect(list.removeFront() == null);
    try testing.expect(list.removeBack() == null);
    try testing.expect(list.removeAt(0) == null);
}
