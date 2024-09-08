const std = @import("std");
const LinkedList = @import("linked_list/list.zig").LinkedList;
const LinkedListUnmanaged = @import("linked_list/list.zig").LinkedListUnmanaged;
const Stack = @import("stack/stack.zig").Stack;
const StackUnmanaged = @import("stack/stack.zig").StackUnmanaged;

comptime {
    std.testing.refAllDeclsRecursive(@import("linked_list/list.zig"));
    std.testing.refAllDeclsRecursive(@import("stack/stack.zig"));
}
