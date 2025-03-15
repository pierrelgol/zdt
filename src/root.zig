const std = @import("std");

pub const LinkedList = @import("LinkedList.zig").LinkedList;
pub const Optional = @import("Optional.zig").Optional;
pub const Queue = @import("Queue.zig").Queue;
pub const QueueUnmanaged = @import("Queue.zig").QueueUnmanaged;
pub const Result = @import("Result.zig").Result;
pub const Stack = @import("Stack.zig").Stack;
pub const StackUnmanaged = @import("Stack.zig").StackUnmanaged;
pub const StaticQueue = @import("StaticQueue.zig").StaticQueue;
pub const StaticStack = @import("StaticStack.zig").StaticStack;

comptime {
    std.testing.refAllDeclsRecursive(@import("Result.zig"));
    std.testing.refAllDeclsRecursive(@import("Optional.zig"));
    std.testing.refAllDeclsRecursive(@import("LinkedList.zig"));
    std.testing.refAllDeclsRecursive(@import("Stack.zig"));
    std.testing.refAllDeclsRecursive(@import("StaticStack.zig"));
    std.testing.refAllDeclsRecursive(@import("Queue.zig"));
    std.testing.refAllDeclsRecursive(@import("StaticQueue.zig"));
}
