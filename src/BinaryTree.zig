// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   BinaryTree.zig                                     :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/02/26 19:42:21 by pollivie          #+#    #+#             //
//   Updated: 2025/02/26 19:42:22 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn BinaryTreeUnmanaged(comptime T: type) type {
    return struct {
        pub const Error = error{} || Allocator.Error;
        const Self = @This();
        const CompareFn = fn (a: T, b: T) std.math.Order;

        maybe_root: ?*Node = null,

        pub fn init() Self {
            return .{
                .maybe_root = null,
            };
        }

        pub fn deinit(self: *Self, allocator: Allocator) void {
            if (self.maybe_root) |root| {
                root.destroy(allocator);
            }
        }

        pub fn append(self: *Self, allocator: Allocator, compare: *const CompareFn, item: T) Error!void {
            if (self.maybe_root) |root| {
                try root.append(allocator, compare, item);
            } else {
                self.maybe_root = try Node.create(allocator, null, item);
            }
        }

        pub fn contains(self: *Self, compare: *const CompareFn, item: T) bool {
            const root = self.maybe_root orelse return false;
            switch (compare(root.item, item)) {
                .eq => return true,
                else => return root.contains(compare, item),
            }
        }

        pub fn remove(self: *Self, allocator: Allocator, compare: *const CompareFn, item: T) void {
            if (self.maybe_root) |root| {
                switch (compare(root.item, item)) {
                    .eq => {
                        defer allocator.destroy(root);
                        if (root.lhs) |lhs| {
                            lhs.parent = null;
                            self.maybe_root = lhs;
                        } else if (root.rhs) |rhs| {
                            rhs.parent = null;
                            self.maybe_root = rhs;
                        } else {
                            self.maybe_root = null;
                        }
                    },
                    else => root.remove(allocator, compare, item),
                }
            }
        }

        pub fn print(self: *Self, print_item: fn (T) void) void {
            if (self.maybe_root) |root| {
                root.print(0, print_item);
            } else {
                std.debug.print("Empty tree\n", .{});
            }
        }

        pub const Node = struct {
            item: T = undefined,
            lhs: ?*Node = null,
            rhs: ?*Node = null,
            parent: ?*Node = null,

            pub fn create(allocator: Allocator, parent: ?*Node, item: T) Error!*Node {
                const self = try allocator.create(Node);
                self.* = .{
                    .item = item,
                    .lhs = null,
                    .rhs = null,
                    .parent = parent,
                };
                return self;
            }

            pub fn destroy(self: *Node, allocator: Allocator) void {
                if (self.lhs) |lhs| {
                    lhs.destroy(allocator);
                    self.lhs = null;
                }
                if (self.rhs) |rhs| {
                    rhs.destroy(allocator);
                    self.rhs = null;
                }
                if (self.lhs == null and self.rhs == null) {
                    allocator.destroy(self);
                }
            }

            pub fn append(node: *Node, allocator: Allocator, compare: *const CompareFn, item: T) !void {
                switch (compare(node.item, item)) {
                    .eq, .lt => {
                        if (node.lhs) |lhs| {
                            try lhs.append(allocator, compare, item);
                        } else {
                            node.lhs = try Node.create(allocator, node, item);
                        }
                    },
                    .gt => {
                        if (node.rhs) |rhs| {
                            try rhs.append(allocator, compare, item);
                        } else {
                            node.rhs = try Node.create(allocator, node, item);
                        }
                    },
                }
            }

            pub fn remove(node: *Node, allocator: Allocator, compare: *const CompareFn, item: T) !void {
                switch (compare(node.item, item)) {
                    .eq => {
                        defer allocator.destroy(node);
                        const parent = node.parent orelse return;
                        if (parent.lhs != null and parent.lhs.? == node) {
                            parent.lhs = null;
                        } else if (parent.rhs != null and parent.rhs.? == node) {
                            parent.rhs = null;
                        }
                    },
                    .lt => {
                        if (node.lhs) |lhs| {
                            try lhs.remove(allocator, compare, item);
                        }
                    },
                    .gt => {
                        if (node.rhs) |rhs| {
                            try rhs.remove(allocator, compare, item);
                        }
                    },
                }
            }

            pub fn contains(node: *Node, compare: *const CompareFn, item: T) bool {
                switch (compare(node.item, item)) {
                    .eq => return true,
                    .lt => return if (node.lhs) |lhs| lhs.contains(compare, item) else false,
                    .gt => return if (node.rhs) |rhs| rhs.contains(compare, item) else false,
                }
            }

            /// Recursively prints the tree.
            /// Each level of depth adds indentation so the tree structure is visible.
            pub fn print(self: *Node, indent: usize, print_item: fn (T) void) void {
                // Print right subtree first for a sideways view.
                if (self.rhs) |rhs| {
                    rhs.print(indent + 1, print_item);
                }
                var i: usize = 0;
                while (i < indent) : (i += 1) {
                    std.debug.print(" ", .{});
                }
                print_item(self.item);
                std.debug.print("\n", .{});
                // Print left subtree.
                if (self.lhs) |lhs| {
                    lhs.print(indent + 1, print_item);
                }
            }
        };
    };
}

fn printU8(char: u8) void {
    std.debug.print("{d}", .{char});
}

fn cmp(a: u8, b: u8) std.math.Order {
    return if (a == b) .eq else if (a < b) .gt else .lt;
}

// test "basic" {
//     const allocator = std.testing.allocator;

//     var tree = BinaryTreeUnmanaged(u8).init();
//     defer tree.deinit(allocator);

//     var rng = std.Random.DefaultPrng.init(0);
//     const random = rng.random();
//     for (0..32) |i| {
//         try tree.append(allocator, cmp, random.uintAtMost(u8, 255 - @as(u8, @truncate(i))));
//     }
//     // Example print using a simple print_item callback.
//     tree.print(printU8);
// }
