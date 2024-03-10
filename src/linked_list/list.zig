const std = @import("std");
const testing = std.testing;
const testing_allocator = testing.allocator;
const failing_allocator = testing.failing_allocator;
const expect = testing.expect;
const expectError = testing.expectError;
const assert = std.debug.assert;

pub fn LinkedList(comptime T: type) type {
    return struct {
        const Self = @This();
        list: LinkedListUnmanaged(T),
        allocator: std.mem.Allocator,
        size: usize,

        pub const Node = LinkedListUnmanaged(T).Node;

        pub fn init(allocator: std.mem.Allocator) !Self {
            return Self{
                .list = try LinkedListUnmanaged(T).create(allocator),
                .allocator = allocator,
                .size = 0,
            };
        }

        pub fn create(allocator: std.mem.Allocator) !*Self {
            var self = try allocator.create(Self);
            self.list = try LinkedListUnmanaged(T).create(allocator);
            errdefer allocator.destroy(self);
            self.allocator = allocator;
            self.size = 0;
            return (self);
        }

        pub fn deinit(self: *Self) void {
            self.list.destroy(self.allocator);
        }

        pub fn destroy(self: *Self) void {
            self.list.destroy(self.allocator);
        }

        pub fn insertFront(self: *Self, item: T) !void {
            self.list.insertFront(try Node.create(self.allocator, item));
            self.size += 1;
        }

        pub fn insertBack(self: *Self, item: T) !void {
            self.list.insertBack(try Node.create(self.allocator, item));
            self.size += 1;
        }

        pub fn insertAt(self: *Self, item: T, index: usize) !void {
            self.list.insertAt(try Node.create(self.allocator, item), index);
            self.size += 1;
        }

        pub fn removeFront(self: *Self) ?*Node {
            if (self.list.removeFront()) |node| {
                self.size -= 1;
                return (node);
            } else {
                return (null);
            }
        }

        pub fn removeBack(self: *Self) ?*Node {
            if (self.list.removeBack()) |node| {
                self.size -= 1;
                return (node);
            } else {
                return (null);
            }
        }

        pub fn removeAt(self: *Self, index: usize) ?*Node {
            if (self.list.removeAt(index)) |node| {
                self.size -= 1;
                return (node);
            } else {
                return (null);
            }
        }

        pub fn getHead(self: *Self) ?*Node {
            return (self.list.maybe_head);
        }

        pub fn getTail(self: *Self) ?*Node {
            return (self.list.maybe_tail);
        }

        pub fn getAt(self: *Self, index: usize) ?*Node {
            if (self.list.maybe_head) |head| {
                return (head.getNthChild(index));
            }
            return (null);
        }

        pub fn getFirstMatch(self: *Self, elem: T, compare: fn (a: T, b: T) bool) ?*Node {
            if (self.list.maybe_head) |head| {
                var temp = head;
                while (temp) |node| : (temp = node) {
                    if (compare(elem, node.item) == true)
                        return (node);
                }
            }
            return (null);
        }

        pub fn getLastMatch(self: *Self, elem: T, compare: fn (a: T, b: T) bool) ?*Node {
            var result: ?*Node = null;
            if (self.list.maybe_head) |head| {
                var temp = head;
                while (temp) |node| : (temp = node) {
                    if (compare(elem, node.item) == true)
                        result = node;
                }
            }
            return (result);
        }

        pub fn getNthMatch(self: *Self, elem: T, compare: fn (a: T, b: T) bool, nth: usize) ?*Node {
            var result: ?*Node = null;
            if (self.list.maybe_head) |head| {
                var temp = head;
                var count: usize = 0;
                while (temp) |node| : (temp = node) {
                    if (compare(elem, node.item) == true) {
                        result = node;
                        count += 1;
                        if (count == nth) return (result);
                    }
                }
            }
            return (result);
        }

        pub fn getCount(self: *Self, elem: T, compare: fn (a: T, b: T) bool) usize {
            var result: usize = 0;
            var temp = self.list.maybe_head orelse return (0);
            while (temp) |node| : (temp = node.next()) {
                if (compare(elem, node.item) == true)
                    result += 1;
            }
            return (result);
        }

        pub fn push(self: *Self, node: *Node) void {
            self.list.insertFront(node);
            self.size += 1;
        }

        pub fn pop(self: *Self) ?*Node {
            const node = self.list.removeFront() orelse return (null);
            self.size -= 1;
            return (node);
        }

        pub fn enqueue(self: *Self, node: *Node) void {
            self.list.insertBack(node);
            self.size += 1;
        }

        pub fn dequeue(self: *Self) ?*Node {
            const node = self.list.removeFront() orelse return (null);
            self.size -= 1;
            return (node);
        }

        pub fn reverse(self: *Self) void {
            const prev = &self.list.maybe_head;
            var current: *Node = prev.*.?;
            while (current.next) |next| {
                current.next = next.next;
                next.next = prev.*;
                prev.* = next;
            }
        }

        pub fn rotateLeft(self: *Self, left_rotation: usize) void {
            return self.list.rotateLeft(left_rotation);
        }

        pub fn rotateRight(self: *Self, right_rotation: usize) void {
            return self.list.rotateRight(right_rotation);
        }
    };
}

pub fn LinkedListUnmanaged(comptime T: type) type {
    return struct {
        const Self = @This();
        const Data = T;
        maybe_head: ?*Node,
        maybe_tail: ?*Node,
        size: usize,

        pub const Node = struct {
            maybe_next: ?*Node,
            item: Data,

            pub fn create(allocator: std.mem.Allocator, item: Data) !*Node {
                var node: *Node = undefined;

                node = try allocator.create(Node);
                node.maybe_next = null;
                node.item = item;
                return (node);
            }

            pub fn destroy(node: *Node, allocator: std.mem.Allocator) void {
                allocator.destroy(node);
            }

            pub fn insertChild(node: *Node, child: *Node) void {
                child.maybe_next = node.maybe_next;
                node.maybe_next = child;
            }

            pub fn removeChild(node: *Node) ?*Node {
                const child = node.maybe_next orelse return (null);
                node.maybe_next = child.maybe_next;
                return (child);
            }

            pub fn countChild(node: *Node) usize {
                var count: usize = 0;
                var temp = node;
                while (temp.maybe_next) |child| : (count += 1) {
                    temp = child;
                }
                return (count);
            }

            pub fn next(node: *Node) ?*Node {
                return (node.maybe_next);
            }

            pub fn getNthChild(node: *Node, nth: usize) *Node {
                if (nth == 0) return (node);
                var temp = node.maybe_next orelse return (node);
                for (0..nth - 1) |_| {
                    temp = temp.maybe_next orelse return (temp);
                }
                return (temp);
            }
        };

        pub fn create(allocator: std.mem.Allocator) !*Self {
            var list: *Self = try allocator.create(Self);
            list.maybe_head = null;
            list.maybe_tail = null;
            list.size = 0;
            return (list);
        }

        pub fn destroy(list: *Self, allocator: std.mem.Allocator) void {
            while (list.maybe_head) |node| {
                const temp = node;
                list.maybe_head = node.maybe_next;
                list.size -= 1;
                allocator.destroy(temp);
            }
            allocator.destroy(list);
        }

        pub fn insertFront(list: *Self, new_head: *Node) void {
            if (list.maybe_head == null and list.maybe_tail == null) {
                list.maybe_tail = new_head;
                list.maybe_head = new_head;
            } else if (list.maybe_head) |head| {
                new_head.maybe_next = head;
                list.maybe_head = new_head;
                if (list.size == 1)
                    list.maybe_tail = head;
            }
            list.size += 1;
        }

        pub fn insertBack(list: *Self, new_tail: *Node) void {
            if (list.maybe_head == null and list.maybe_tail == null) {
                list.maybe_tail = new_tail;
                list.maybe_head = new_tail;
            } else if (list.maybe_tail) |tail| {
                tail.maybe_next = new_tail;
                list.maybe_tail = new_tail;
                if (list.size == 1) {
                    if (list.maybe_head) |head| {
                        head.maybe_next = new_tail;
                    }
                }
            }
            list.size += 1;
        }

        pub fn insertAt(list: *Self, child: *Node, index: usize) void {
            if (index == 0 or list.size == 0) return (list.insertFront(child));
            if (index >= list.size) return (list.insertBack(child));
            if (list.maybe_head) |head| {
                const parent = head.getNthChild(index - 1);
                parent.insertChild(child);
                list.size += 1;
            }
        }

        pub fn removeFront(list: *Self) ?*Node {
            if (list.size == 1) {
                const last_node = list.maybe_head;
                list.maybe_head = null;
                list.maybe_tail = null;
                list.size -= 1;
                return (last_node);
            }
            const old_head = list.maybe_head orelse return null;
            list.maybe_head = old_head.maybe_next;
            list.size -= 1;
            return (old_head);
        }

        pub fn removeBack(list: *Self) ?*Node {
            if (list.size == 1) {
                const last_node = list.maybe_head;
                list.maybe_head = null;
                list.maybe_tail = null;
                list.size -= 1;
                return (last_node);
            } else if (list.maybe_head) |head| {
                var temp = head;
                while (temp.next()) |child| : (temp = child) {
                    if (child == list.maybe_tail) break;
                }
                const tail = temp.removeChild();
                list.maybe_tail = temp;
                temp.maybe_next = null;
                list.size -= 1;
                return (tail);
            } else {
                assert(list.size == 0);
                return (null);
            }
        }

        pub fn removeAt(list: *Self, index: usize) ?*Node {
            if (index == 0) return (list.removeFront());
            if (index >= list.size) return (list.removeBack());
            const temp = list.maybe_head orelse return (null);
            const parent = temp.getNthChild(index - 1);
            const child = parent.removeChild();
            list.size -= 1;
            return (child);
        }

        fn sortedMerge(left: ?*Node, right: ?*Node, is_sorted: fn (v1: T, v2: T) bool) ?*Node {
            var result: ?*Node = null;
            if (left == null) {
                return (right);
            } else if (right == null) {
                return (left);
            }
            if (is_sorted(left.?.item, right.?.item) == true) {
                result = left;
                result.?.maybe_next = sortedMerge(left.?.maybe_next, right, is_sorted);
            } else {
                result = right;
                result.?.maybe_next = sortedMerge(left, right.?.maybe_next, is_sorted);
            }
        }

        fn findMiddle(maybe_head: ?*Node, start: *?*Node, end: *?*Node) void {
            if (maybe_head) |head| {
                var maybe_slow_ptr: ?*Node = maybe_head;
                var maybe_fast_ptr: ?*Node = head.maybe_next;

                while (maybe_fast_ptr) |fast| {
                    maybe_fast_ptr = fast.maybe_next orelse null;
                    if (fast) {
                        maybe_slow_ptr = maybe_slow_ptr.maybe_next.?;
                        fast = fast.maybe_next orelse null;
                    }
                }
                start.* = head;
                end.* = maybe_slow_ptr.maybe_next orelse null;
                maybe_slow_ptr.maybe_next = 0;
            }
        }

        pub fn sort(maybe_head_ptr: *?*Node, is_sorted: fn (v1: T, v2: T) bool) void {
            if (maybe_head_ptr.*) |head| {
                var a: ?*Node = null;
                var b: ?*Node = null;
                findMiddle(head, &a, &b);
                sort(&a, is_sorted);
                sort(&b, is_sorted);
                maybe_head_ptr.* = sortedMerge();
            }
        }

        pub fn rotate(list: *Self, maybe_left: ?usize, maybe_right: ?usize) void {
            if (maybe_left) |left| {
                for (0..left) |_| {
                    if (list.removeFront()) |node| {
                        node.maybe_next = null;
                        list.insertBack(node);
                    } else break;
                }
            } else if (maybe_right) |right| {
                for (0..right) |_| {
                    if (list.removeFront()) |node| {
                        node.maybe_next = null;
                        list.insertBack(node);
                    } else break;
                }
            }
        }

        fn rotateLeft(list: *Self, left_rotation: usize) void {
            return (list.rotate(left_rotation, null));
        }

        fn rotateRight(list: *Self, right_rotation: usize) void {
            return (list.rotate(null, right_rotation));
        }
    };
}

test "Node.create() Ok" {
    const allocator = testing_allocator;

    const node = try LinkedListUnmanaged(usize).Node.create(allocator, 42);
    defer node.destroy(allocator);

    try expect(node.maybe_next == null);
    try expect(node.item == 42);
}

test "Node.create() Err" {
    const allocator = failing_allocator;

    const expected_error = std.mem.Allocator.Error.OutOfMemory;

    try expectError(expected_error, LinkedListUnmanaged(usize).Node.create(allocator, 42));
}

test "Node.destroy()" {
    const allocator = testing_allocator;

    const node = try LinkedListUnmanaged(usize).Node.create(allocator, 42);

    try expect(node.maybe_next == null);
    try expect(node.item == 42);

    node.destroy(allocator);
}

test "Node.insertChild()" {
    const allocator = testing_allocator;

    const parent = try LinkedListUnmanaged(usize).Node.create(allocator, 42);
    defer parent.destroy(allocator);

    const child = try LinkedListUnmanaged(usize).Node.create(allocator, 41);
    defer child.destroy(allocator);

    try expect(parent.maybe_next == null);
    try expect(parent.item == 42);
    try expect(child.maybe_next == null);
    try expect(child.item == 41);

    parent.insertChild(child);
    try expect(parent.maybe_next != null);
    if (parent.maybe_next) |next| {
        try expect(next.item == 41);
    }
}

test "Node.removeChild()" {
    const allocator = testing_allocator;

    const parent = try LinkedListUnmanaged(usize).Node.create(allocator, 42);
    defer parent.destroy(allocator);

    const child = try LinkedListUnmanaged(usize).Node.create(allocator, 41);
    defer child.destroy(allocator);

    try expect(parent.maybe_next == null);
    try expect(parent.item == 42);
    try expect(child.maybe_next == null);
    try expect(child.item == 41);

    parent.insertChild(child);
    try expect(parent.maybe_next != null);
    if (parent.maybe_next) |next| {
        try expect(next.item == 41);
    }
    const ref = parent.removeChild();
    try expect(ref != null);
}

test "Node.countChild()" {
    const allocator = testing_allocator;

    const parent = try LinkedListUnmanaged(usize).Node.create(allocator, 42);
    defer parent.destroy(allocator);

    const child1 = try LinkedListUnmanaged(usize).Node.create(allocator, 41);
    defer child1.destroy(allocator);

    const child2 = try LinkedListUnmanaged(usize).Node.create(allocator, 41);
    defer child2.destroy(allocator);

    const child3 = try LinkedListUnmanaged(usize).Node.create(allocator, 41);
    defer child3.destroy(allocator);

    parent.insertChild(child1);
    child1.insertChild(child2);
    child2.insertChild(child3);

    try expect(parent.countChild() == 3);
    try expect(child1.countChild() == 2);
    try expect(child2.countChild() == 1);
    try expect(child3.countChild() == 0);
}

test "Node.next()" {
    const allocator = testing_allocator;

    const parent = try LinkedListUnmanaged(usize).Node.create(allocator, 42);
    defer parent.destroy(allocator);

    const child1 = try LinkedListUnmanaged(usize).Node.create(allocator, 41);
    defer child1.destroy(allocator);

    const child2 = try LinkedListUnmanaged(usize).Node.create(allocator, 41);
    defer child2.destroy(allocator);

    const child3 = try LinkedListUnmanaged(usize).Node.create(allocator, 41);
    defer child3.destroy(allocator);

    parent.insertChild(child1);
    child1.insertChild(child2);
    child2.insertChild(child3);

    try expect(parent.next() == child1);
    try expect(child1.next() == child2);
    try expect(child2.next() == child3);
    try expect(child3.next() == null);
}

test "Node.getNthChild()" {
    const allocator = testing_allocator;

    const parent = try LinkedListUnmanaged(usize).Node.create(allocator, 42);
    defer parent.destroy(allocator);

    const child1 = try LinkedListUnmanaged(usize).Node.create(allocator, 41);
    defer child1.destroy(allocator);

    const child2 = try LinkedListUnmanaged(usize).Node.create(allocator, 41);
    defer child2.destroy(allocator);

    const child3 = try LinkedListUnmanaged(usize).Node.create(allocator, 41);
    defer child3.destroy(allocator);

    parent.insertChild(child1);
    child1.insertChild(child2);
    child2.insertChild(child3);

    try expect(parent.getNthChild(0) == parent);
    try expect(parent.getNthChild(1) == child1);
    try expect(parent.getNthChild(2) == child2);
    try expect(parent.getNthChild(3) == child3);
    try expect(parent.getNthChild(4) == child3);

    _ = child2.removeChild();
    _ = child1.removeChild();
    _ = parent.removeChild();

    try expect(parent.getNthChild(1) == parent);
    try expect(parent.getNthChild(2) == parent);
    try expect(parent.getNthChild(3) == parent);
}

test "LinkedListUnmanaged.create() ok" {
    const allocator = testing_allocator;
    const List = LinkedListUnmanaged(usize);

    const list = try List.create(allocator);
    defer list.destroy(allocator);
    try expect(list.maybe_head == null);
    try expect(list.maybe_tail == null);
    try expect(list.size == 0);
}

test "LinkedListUnmanaged.create() err" {
    const allocator = failing_allocator;
    const List = LinkedListUnmanaged(usize);
    const expected_error = std.mem.Allocator.Error.OutOfMemory;

    try expectError(expected_error, List.create(allocator));
}

test "LinkedListUnmanaged.destroy()" {
    const allocator = testing_allocator;
    const List = LinkedListUnmanaged(usize);

    const list = try List.create(allocator);
    list.destroy(allocator);
}

test "LinkedListUnmanaged.insertFront() : 1" {
    const allocator = testing_allocator;
    const List = LinkedListUnmanaged(usize);

    const list = try List.create(allocator);
    defer list.destroy(allocator);

    const new_head = try List.Node.create(allocator, 0);
    list.insertFront(new_head);

    try expect(list.maybe_head != null);
    try expect(list.maybe_tail != null);
    try expect(list.size == 1);
    if (list.maybe_head) |head| {
        try expect(head.maybe_next == null);
        try expect(head.item == 0);
    }
}

test "LinkedListUnmanaged.insertFront() : 2" {
    const allocator = testing_allocator;
    const List = LinkedListUnmanaged(usize);

    const list = try List.create(allocator);
    defer list.destroy(allocator);

    const new_head1 = try List.Node.create(allocator, 3);
    const new_head2 = try List.Node.create(allocator, 2);
    const new_head3 = try List.Node.create(allocator, 1);
    const new_head4 = try List.Node.create(allocator, 0);

    try expect(list.size == 0);
    list.insertFront(new_head1);
    try expect(list.size == 1);
    list.insertFront(new_head2);
    try expect(list.size == 2);
    list.insertFront(new_head3);
    try expect(list.size == 3);
    list.insertFront(new_head4);
    try expect(list.size == 4);

    var node = list.maybe_head;
    if (node) |n| {
        try expect(n.maybe_next != null);
        try expect(n.item == 0);
        node = n.maybe_next;
    }
    if (node) |n| {
        try expect(n.maybe_next != null);
        try expect(n.item == 1);
        node = n.maybe_next;
    }
    if (node) |n| {
        try expect(n.maybe_next != null);
        try expect(n.item == 2);
        node = n.maybe_next;
    }
    if (node) |n| {
        try expect(n.maybe_next == null);
        try expect(list.maybe_tail == node);
        try expect(n.item == 3);
        node = n.maybe_next;
    }
}

test "LinkedListUnamanaged.insertBack() : 1" {
    const allocator = testing_allocator;
    const List = LinkedListUnmanaged(usize);

    const list = try List.create(allocator);
    defer list.destroy(allocator);

    const new_tail = try List.Node.create(allocator, 0);

    list.insertBack(new_tail);
    try expect(list.maybe_head != null);
    try expect(list.maybe_tail != null);
    try expect(list.size == 1);

    if (list.maybe_tail) |tail| {
        try expect(tail.maybe_next == null);
        try expect(tail.item == 0);
    }
}

test "LinkedListUnamanaged.insertBack() : 2" {
    const allocator = testing_allocator;
    const List = LinkedListUnmanaged(usize);

    const list = try List.create(allocator);
    defer list.destroy(allocator);

    const new_tail1 = try List.Node.create(allocator, 3);
    const new_tail2 = try List.Node.create(allocator, 2);
    const new_tail3 = try List.Node.create(allocator, 1);
    const new_tail4 = try List.Node.create(allocator, 0);

    list.insertBack(new_tail1);
    list.insertBack(new_tail2);
    list.insertBack(new_tail3);
    list.insertBack(new_tail4);

    try expect(list.maybe_head != null);
    try expect(list.maybe_tail != null);
    try expect(list.size == 4);

    var node = list.maybe_head;
    if (node) |n| {
        try expect(n.maybe_next != null);
        try expect(list.maybe_head == node);
        try expect(n.item == 3);
        node = n.maybe_next;
    }
    if (node) |n| {
        try expect(n.maybe_next != null);
        try expect(n.item == 2);
        node = n.maybe_next;
    }
    if (node) |n| {
        try expect(n.maybe_next != null);
        try expect(n.item == 1);
        node = n.maybe_next;
    }
    if (node) |n| {
        try expect(n.maybe_next == null);
        try expect(list.maybe_tail == node);
        try expect(n.item == 0);
    }
}

test "LinkedListUnmanaged.inserAt() : 1" {
    const allocator = testing_allocator;
    const List = LinkedListUnmanaged(usize);

    const list = try List.create(allocator);
    defer list.destroy(allocator);

    const new_head1 = try List.Node.create(allocator, 3);
    const new_head2 = try List.Node.create(allocator, 2);
    const new_head3 = try List.Node.create(allocator, 1);
    const new_head4 = try List.Node.create(allocator, 0);

    list.insertAt(new_head1, 0);
    list.insertAt(new_head2, 0);
    list.insertAt(new_head3, 0);
    list.insertAt(new_head4, 0);

    var node = list.maybe_head;
    if (node) |n| {
        try expect(n.maybe_next != null);
        try expect(n.item == 0);
        node = n.maybe_next;
    }
    if (node) |n| {
        try expect(n.maybe_next != null);
        try expect(n.item == 1);
        node = n.maybe_next;
    }
    if (node) |n| {
        try expect(n.maybe_next != null);
        try expect(n.item == 2);
        node = n.maybe_next;
    }
    if (node) |n| {
        try expect(n.maybe_next == null);
        try expect(list.maybe_tail == node);
        try expect(n.item == 3);
        node = n.maybe_next;
    }
}

test "LinkedListUnmanaged.inserAt() : 2" {
    const allocator = testing_allocator;
    const List = LinkedListUnmanaged(usize);

    const list = try List.create(allocator);
    defer list.destroy(allocator);

    const new_head1 = try List.Node.create(allocator, 3);
    const new_head2 = try List.Node.create(allocator, 2);
    const new_head3 = try List.Node.create(allocator, 1);
    const new_head4 = try List.Node.create(allocator, 0);

    list.insertAt(new_head1, 0);
    list.insertAt(new_head2, 1);
    list.insertAt(new_head3, 2);
    list.insertAt(new_head4, 3);

    var node = list.maybe_head;
    if (node) |n| {
        try expect(n.maybe_next != null);
        try expect(n.item == 3);
        node = n.maybe_next;
    }
    if (node) |n| {
        try expect(n.maybe_next != null);
        try expect(n.item == 2);
        node = n.maybe_next;
    }
    if (node) |n| {
        try expect(n.maybe_next != null);
        try expect(n.item == 1);
        node = n.maybe_next;
    }
    if (node) |n| {
        try expect(n.maybe_next == null);
        try expect(list.maybe_tail == node);
        try expect(n.item == 0);
        node = n.maybe_next;
    }
}

test "LinkedListUnmanaged.inserAt() : 3" {
    const allocator = testing_allocator;
    const List = LinkedListUnmanaged(usize);

    const list = try List.create(allocator);
    defer list.destroy(allocator);

    const new_head1 = try List.Node.create(allocator, 3);
    const new_head2 = try List.Node.create(allocator, 2);
    const new_head3 = try List.Node.create(allocator, 1);
    const new_head4 = try List.Node.create(allocator, 0);

    list.insertAt(new_head1, 1);
    list.insertAt(new_head2, 1);
    list.insertAt(new_head3, 1);
    list.insertAt(new_head4, 1);

    var node = list.maybe_head;
    if (node) |n| {
        try expect(n.maybe_next != null);
        try expect(n.item == 3);
        node = n.maybe_next;
    }
    if (node) |n| {
        try expect(n.maybe_next != null);
        try expect(n.item == 0);
        node = n.maybe_next;
    }
    if (node) |n| {
        try expect(n.maybe_next != null);
        try expect(n.item == 1);
        node = n.maybe_next;
    }
    if (node) |n| {
        try expect(n.maybe_next == null);
        try expect(list.maybe_tail == node);
        try expect(n.item == 2);
        node = n.maybe_next;
    }
}

test "LinkedListUnamanaged.removeFront() : 1" {
    const allocator = testing_allocator;
    const List = LinkedListUnmanaged(usize);

    const list = try List.create(allocator);
    defer list.destroy(allocator);

    const null_result = list.removeFront();
    try expect(null_result == null);
}

test "LinkedListUnamanaged.removeFront() : 2" {
    const allocator = testing_allocator;
    const List = LinkedListUnmanaged(usize);

    const list = try List.create(allocator);
    defer list.destroy(allocator);
    const new_head = try List.Node.create(allocator, 0);
    defer new_head.destroy(allocator);

    list.insertFront(new_head);
    const maybe_head = list.removeFront();
    if (maybe_head) |head| {
        try expect(head.maybe_next == null);
        try expect(head.item == 0);
        try expect(list.maybe_head == null);
        try expect(list.maybe_tail == null);
        try expect(list.size == 0);
    } else {
        @panic("The removeFront() Node(0) failed!\n");
    }
}

test "LinkedListUnamanaged.removeFront() : 3" {
    const allocator = testing_allocator;
    const List = LinkedListUnmanaged(usize);

    const list = try List.create(allocator);
    defer list.destroy(allocator);

    const new_head = try List.Node.create(allocator, 0);
    defer new_head.destroy(allocator);

    const new_node1 = try List.Node.create(allocator, 1);
    defer new_node1.destroy(allocator);

    const new_node2 = try List.Node.create(allocator, 2);
    defer new_node2.destroy(allocator);

    list.insertAt(new_head, 0);
    list.insertAt(new_node1, 1);
    list.insertAt(new_node2, 2);

    var maybe_head = list.removeFront();
    if (maybe_head) |head| {
        try expect(head.maybe_next != null);
        try expect(head.item == 0);
        try expect(list.maybe_head != null);
        try expect(list.maybe_tail != null);
        try expect(list.size == 2);
    } else {
        @panic("The removeFront() : Node(0) failed!\n");
    }

    maybe_head = list.removeFront();
    if (maybe_head) |head| {
        try expect(head.maybe_next != null);
        try expect(head.item == 1);
        try expect(list.maybe_head != null);
        try expect(list.maybe_tail != null);
        try expect(list.size == 1);
    } else {
        @panic("The removeFront() : Node(1) failed!\n");
    }

    maybe_head = list.removeFront();
    if (maybe_head) |head| {
        try expect(head.maybe_next == null);
        try expect(head.item == 2);
        try expect(list.maybe_head == null);
        try expect(list.maybe_tail == null);
        try expect(list.size == 0);
    } else {
        @panic("The removeFront() : Node(2) failed!\n");
    }
}

test "LinkedListUnamanaged.removeBack() : 1" {
    const allocator = testing_allocator;
    const List = LinkedListUnmanaged(usize);

    const list = try List.create(allocator);
    defer list.destroy(allocator);

    const null_result = list.removeBack();
    try expect(null_result == null);
}

test "LinkedListUnamanaged.removeBack() : 2" {
    const allocator = testing_allocator;
    const List = LinkedListUnmanaged(usize);

    const list = try List.create(allocator);
    defer list.destroy(allocator);

    const new_head = try List.Node.create(allocator, 0);
    defer new_head.destroy(allocator);

    const new_node1 = try List.Node.create(allocator, 1);
    defer new_node1.destroy(allocator);

    const new_node2 = try List.Node.create(allocator, 2);
    defer new_node2.destroy(allocator);

    list.insertAt(new_head, 0);
    list.insertAt(new_node1, 1);
    list.insertAt(new_node2, 2);

    var maybe_tail = list.removeBack();
    if (maybe_tail) |tail| {
        try expect(tail.maybe_next == null);
        try expect(tail.item == 2);
        try expect(list.maybe_head != null);
        try expect(list.maybe_tail != null);
        try expect(list.size == 2);
    } else {
        @panic("The removeBack() : Node(0) failed!\n");
    }

    maybe_tail = list.removeBack();
    if (maybe_tail) |tail| {
        try expect(tail.maybe_next == null);
        try expect(tail.item == 1);
        try expect(list.maybe_head != null);
        try expect(list.maybe_tail != null);
        try expect(list.size == 1);
    } else {
        @panic("The removeBack() : Node(1) failed!\n");
    }

    maybe_tail = list.removeBack();
    if (maybe_tail) |tail| {
        try expect(tail.maybe_next == null);
        try expect(tail.item == 0);
        try expect(list.maybe_head == null);
        try expect(list.maybe_tail == null);
        try expect(list.size == 0);
    } else {
        @panic("The removeBack() : Node(2) failed!\n");
    }
}

test "LinkedListUnmanaged.removeAt() : 1" {
    const allocator = testing_allocator;
    const List = LinkedListUnmanaged(usize);

    const list = try List.create(allocator);
    defer list.destroy(allocator);

    const new_head = try List.Node.create(allocator, 0);
    defer new_head.destroy(allocator);

    const new_node1 = try List.Node.create(allocator, 1);
    defer new_node1.destroy(allocator);

    const new_node2 = try List.Node.create(allocator, 2);
    defer new_node2.destroy(allocator);

    const new_node3 = try List.Node.create(allocator, 3);
    defer new_node3.destroy(allocator);

    list.insertAt(new_head, 0);
    list.insertAt(new_node1, 1);
    list.insertAt(new_node2, 2);
    list.insertAt(new_node3, 3);

    var maybe_head = list.removeAt(0);
    if (maybe_head) |head| {
        try expect(head.maybe_next != null);
        try expect(head.item == 0);
        try expect(list.maybe_head != null);
        try expect(list.maybe_tail != null);
        try expect(list.size == 3);
    } else {
        @panic("The removeAt() : Node(0) failed!\n");
    }
    maybe_head = list.removeAt(0);
    if (maybe_head) |head| {
        try expect(head.maybe_next != null);
        try expect(head.item == 1);
        try expect(list.maybe_head != null);
        try expect(list.maybe_tail != null);
        try expect(list.size == 2);
    } else {
        @panic("The removeAt() : Node(1) failed!\n");
    }
    maybe_head = list.removeAt(0);
    if (maybe_head) |head| {
        try expect(head.maybe_next != null);
        try expect(head.item == 2);
        try expect(list.maybe_head != null);
        try expect(list.maybe_tail != null);
        try expect(list.size == 1);
    } else {
        @panic("The removeAt() : Node(2) failed!\n");
    }

    maybe_head = list.removeAt(0);
    if (maybe_head) |head| {
        try expect(head.maybe_next == null);
        try expect(head.item == 3);
        try expect(list.maybe_head == null);
        try expect(list.maybe_tail == null);
        try expect(list.size == 0);
    } else {
        @panic("The removeAt() : Node(3) failed!\n");
    }
}

test "LinkedListUnmanaged.removeAt() : 2" {
    const allocator = testing_allocator;
    const List = LinkedListUnmanaged(usize);

    const list = try List.create(allocator);
    defer list.destroy(allocator);

    const new_head = try List.Node.create(allocator, 0);
    defer new_head.destroy(allocator);

    const new_node1 = try List.Node.create(allocator, 1);
    defer new_node1.destroy(allocator);

    const new_node2 = try List.Node.create(allocator, 2);
    defer new_node2.destroy(allocator);

    const new_node3 = try List.Node.create(allocator, 3);
    defer new_node3.destroy(allocator);

    list.insertAt(new_head, 0);
    list.insertAt(new_node1, 1);
    list.insertAt(new_node2, 2);
    list.insertAt(new_node3, 3);

    var maybe_head = list.removeAt(4);
    if (maybe_head) |head| {
        try expect(head.maybe_next == null);
        try expect(head.item == 3);
        try expect(list.maybe_head != null);
        try expect(list.maybe_tail != null);
        try expect(list.size == 3);
    } else {
        @panic("The removeAt() : Node(3) failed!\n");
    }
    maybe_head = list.removeAt(3);
    if (maybe_head) |head| {
        try expect(head.maybe_next == null);
        try expect(head.item == 2);
        try expect(list.maybe_head != null);
        try expect(list.maybe_tail != null);
        try expect(list.size == 2);
    } else {
        @panic("The removeAt() : Node(2) failed!\n");
    }
    maybe_head = list.removeAt(2);
    if (maybe_head) |head| {
        try expect(head.maybe_next == null);
        try expect(head.item == 1);
        try expect(list.maybe_head != null);
        try expect(list.maybe_tail != null);
        try expect(list.size == 1);
    } else {
        @panic("The removeAt() : Node(1) failed!\n");
    }

    maybe_head = list.removeAt(1);
    if (maybe_head) |head| {
        try expect(head.maybe_next == null);
        try expect(head.item == 0);
        try expect(list.maybe_head == null);
        try expect(list.maybe_tail == null);
        try expect(list.size == 0);
    } else {
        @panic("The removeAt() : Node(0) failed!\n");
    }
}

test "LinkedListUnmanaged.removeAt() : 3" {
    const allocator = testing_allocator;
    const List = LinkedListUnmanaged(usize);

    const list = try List.create(allocator);
    defer list.destroy(allocator);

    const new_head = try List.Node.create(allocator, 0);
    defer new_head.destroy(allocator);

    const new_node1 = try List.Node.create(allocator, 1);
    defer new_node1.destroy(allocator);

    const new_node2 = try List.Node.create(allocator, 2);
    defer new_node2.destroy(allocator);

    const new_node3 = try List.Node.create(allocator, 3);
    defer new_node3.destroy(allocator);

    list.insertAt(new_head, 0);
    list.insertAt(new_node1, 1);
    list.insertAt(new_node2, 2);
    list.insertAt(new_node3, 3);

    var maybe_head = list.removeAt(1);
    if (maybe_head) |head| {
        try expect(head.maybe_next != null);
        try expect(head.item == 1);
        try expect(list.maybe_head != null);
        try expect(list.maybe_tail != null);
        try expect(list.size == 3);
    } else {
        @panic("The removeAt() : Node(1) failed!\n");
    }
    maybe_head = list.removeAt(1);
    if (maybe_head) |head| {
        try expect(head.maybe_next != null);
        try expect(head.item == 2);
        try expect(list.maybe_head != null);
        try expect(list.maybe_tail != null);
        try expect(list.size == 2);
    } else {
        @panic("The removeAt() : Node(2) failed!\n");
    }
    maybe_head = list.removeAt(1);
    if (maybe_head) |head| {
        try expect(head.maybe_next == null);
        try expect(head.item == 3);
        try expect(list.maybe_head != null);
        try expect(list.maybe_tail != null);
        try expect(list.size == 1);
    } else {
        @panic("The removeAt() : Node(1) failed!\n");
    }

    maybe_head = list.removeAt(1);
    if (maybe_head) |head| {
        try expect(head.maybe_next == null);
        try expect(head.item == 0);
        try expect(list.maybe_head == null);
        try expect(list.maybe_tail == null);
        try expect(list.size == 0);
    } else {
        @panic("The removeAt() : Node(0) failed!\n");
    }
}
