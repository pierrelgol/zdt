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
