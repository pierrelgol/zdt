const std = @import("std");

const LinkedList = @import("LinkedList.zig");
const Optional = @import("Optional.zig");
const Queue = @import("Queue.zig");
const Result = @import("Result.zig");
const Stack = @import("Stack.zig");
const StaticQueue = @import("StaticQueue.zig");
const StaticStack = @import("StaticStack.zig");

comptime {
    std.testing.refAllDeclsRecursive(Result);
    std.testing.refAllDeclsRecursive(Optional);
    std.testing.refAllDeclsRecursive(LinkedList);
    std.testing.refAllDeclsRecursive(Stack);
    std.testing.refAllDeclsRecursive(StaticStack);
    std.testing.refAllDeclsRecursive(Queue);
    std.testing.refAllDeclsRecursive(StaticQueue);
}
