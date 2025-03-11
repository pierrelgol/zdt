// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Optional.zig                                       :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/02/27 01:24:36 by pollivie          #+#    #+#             //
//   Updated: 2025/02/27 01:24:37 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");

pub fn Optional(comptime T: type) type {
    return union(enum) {
        const Self = @This();
        some: T,
        none: ?u0,

        pub fn wrap(res: anyerror!T) Self {
            if (res) |v| {
                return .{ .some = v };
            } else |_| {
                return .{ .none = null };
            }
        }

        pub fn unwrap(self: Self) T {
            std.debug.assert(std.meta.activeTag(self) == .some);
            return self.some;
        }

        pub fn unwrapOrErr(self: Self) !T {
            return if (std.meta.activeTag(self) == .some) self.some else return error.NullValue;
        }

        pub fn unwrapOrNull(self: Self) ?T {
            return if (std.meta.activeTag(self) == .some) self.some else return null;
        }
    };
}

pub const FooError = error{
    oops,
};

pub fn foo(x: u32) Optional(u32) {
    if (x == 4) {
        return .{ .some = 4 };
    } else {
        return .{ .none = null };
    }
}

// test "a" {
//     const x: u32 = 5;
//     const opt = foo(x);

//     switch (opt) {
//         .some => |t| std.debug.print("{d}", .{t}),
//         .none => |n| std.debug.print("{?}", .{n}),
//     }
// }
