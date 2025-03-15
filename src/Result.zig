// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   Result.zig                                         :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2025/02/27 01:22:58 by pollivie          #+#    #+#             //
//   Updated: 2025/02/27 01:22:59 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");

pub fn Result(comptime T: type, comptime E: type) type {
    return union(enum) {
        const Self = @This();
        ok: T,
        err: E,

        pub fn wrap(res: E!T) Self {
            if (res) |v| {
                return .{ .ok = v };
            } else |e| {
                return .{ .err = e };
            }
        }

        pub fn unwrap(self: Self) T {
            std.debug.assert(std.meta.activeTag(self) == .ok);
            return self.ok;
        }

        pub fn unwrapOrErr(self: Self) E!T {
            return if (std.meta.activeTag(self) == .ok) self.ok else return self.err;
        }

        pub fn unwrapOrNull(self: Self) ?T {
            return if (std.meta.activeTag(self) == .ok) self.ok else return null;
        }
    };
}

pub const FooError = error{
    wrong,
};

pub fn foo(x: u32) Result(@TypeOf(x), FooError) {
    if (x == 4) {
        return .{ .ok = x };
    } else {
        return .{ .err = error.wrong };
    }
}

pub fn failingFoo(x: u32) FooError!u32 {
    return if (x == 4) x else error.wrong;
}

test "b" {
    const r = foo(4);

    switch (r) {
        .ok => |v| _ = v,
        .err => |e| return e,
    }
}
