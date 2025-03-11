const std = @import("std");

const BinaryTree = @import("BinaryTree.zig");
const Optional = @import("Optional.zig");
const Result = @import("Result.zig");
const SlotMap = @import("SlotMap.zig");
const Stack = @import("Stack.zig");

comptime {
    std.testing.refAllDeclsRecursive(BinaryTree);
    std.testing.refAllDeclsRecursive(Stack);
    std.testing.refAllDeclsRecursive(Result);
    std.testing.refAllDeclsRecursive(Optional);
}
