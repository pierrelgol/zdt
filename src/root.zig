const std = @import("std");
pub const LinkedList = @import("linked_list/list.zig").LinkedList;
pub const LinkedListUnmanaged = @import("linked_list/list.zig").LinkedListUnmanaged;
pub const Stack = @import("stack/stack.zig").Stack;
pub const StackUnmanaged = @import("stack/stack.zig").StackUnmanaged;

comptime {
    std.testing.refAllDeclsRecursive(@import("linked_list/list.zig"));
    std.testing.refAllDeclsRecursive(@import("stack/stack.zig"));
}
