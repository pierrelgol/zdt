const std = @import("std");

const Optional = @import("Optional.zig");
const Result = @import("Result.zig");

comptime {
    std.testing.refAllDeclsRecursive(Result);
    std.testing.refAllDeclsRecursive(Optional);
}
