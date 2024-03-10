// ****************************************************************************//
//                                                                             //
//                                                         :::      ::::::::   //
//    stack.zig                                          :+:      :+:    :+:   //
//                                                     +:+ +:+         +:+     //
//    By: pollivie <pollivie@student.42.fr>          +#+  +:+       +#+        //
//                                                 +#+#+#+#+#+   +#+           //
//    Created: 2024/03/10 19:28:42 by pollivie          #+#    #+#             //
//    Updated: 2024/03/10 19:28:43 by pollivie         ###   ########.fr       //
//                                                                             //
// ****************************************************************************//

const std = @import("std");
const testing = std.testing;
const testing_allocator = testing.allocator;
const failing_allocator = testing.failing_allocator;
const expect = testing.expect;
const expectError = testing.expectError;
const assert = std.debug.assert;
const LinkListUnmanaged = @import("../linked_list/list.zig").LinkedListUnmanaged;
const LinkList = @import("../linked_list/list.zig").LinkedList;

pub fn StackUnmanaged(comptime T: type) type {
    return struct {
        const Self = @This();
        const Data = T;

        len: usize,
        size: ?usize,
        top: LinkListUnmanaged(T),

        pub const Node = LinkListUnmanaged(T).Node;

        pub fn create(allocator: std.mem.Allocator) !*Self {
            var stack = try allocator.create(Self);
            errdefer allocator.destroy(stack);
            stack.len = 0;
            stack.size = 0;
            stack.top = try LinkListUnmanaged(T).create(allocator);
            return (stack);
        }

        pub fn setMaxSize(self: *Self, max_size: ?usize) void {
            if (max_size) |limit| {
                self.size = limit;
            } else {
                self.size == null;
            }
        }

        pub fn destroy(self: *Self, allocator: std.mem.Allocator) void {
            self.top.destroy(allocator);
            allocator.destroy(self);
        }

        pub fn isEmtpy(self: *Self) bool {
            return (self.len == 0);
        }

        pub fn isFull(self: *Self) bool {
            const limit = self.size orelse return (false);
            return (self.len == limit);
        }

        pub fn push(self: *Self, allocator: std.mem.Allocator, item: T) !void {
            self.top.insertFront(try Node.create(allocator, item));
            self.len += 1;
        }

        pub fn pop(self: *Self, allocator: std.mem.Allocator, item: T) ?item {
            const node = self.top.removeFront() orelse return (null);
            const value: T = node.item;
            defer node.destroy(allocator);
            self.len -= 1;
            return (value);
        }
    };
}
