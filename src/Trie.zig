const std = @import("std");
const mem = std.mem;
const heap = std.heap;
const testing = std.testing;
const debug = std.debug;
const ArrayList = std.ArrayListUnmanaged;

pub const TrieUnmanaged = struct {
    pub const Error = error{} || mem.Allocator.Error;

    root: Node,

    pub fn init(allocator: mem.Allocator) Error!TrieUnmanaged {
        return .{
            .root = try Node.init(allocator),
        };
    }

    pub fn insert(self: *TrieUnmanaged, allocator: mem.Allocator, string: []const u8) Error!void {
        return try self.root.insert(allocator, string);
    }

    pub fn deinit(self: *TrieUnmanaged, allocator: mem.Allocator) void {
        _ = allocator;
        _ = self;
    }

    pub const Node = struct {
        is_final: bool,
        children: ArrayList(?Node),

        pub fn init(allocator: mem.Allocator) Error!Node {
            return .{
                .is_final = false,
                .children = try ArrayList(?Node).initCapacity(allocator, 26),
            };
        }

        pub fn deinit(self: *Node, allocator: mem.Allocator) void {
            self.children.deinit(allocator);
        }

        pub fn hasChild(self: *Node, item: u8) !?*Node {
            if ((item | 32) >= 'a' and (item | 32) <= 'z') {
                return self.children[(item | 32) - 'a'];
            } else {
                return Error.WrongElem;
            }
        }

        pub fn insert(self: *Node, allocator: mem.Allocator, string: []const u8) Error!void {
            if (string.len == 0) {
                self.is_final = true;
            } else {
                if (try self.hasChild(string[0])) |child| {
                    try child.insert(allocator, string[1..]);
                } else {
                    const char = (string[0] | 32);
                    if (char >= 'a' and char <= 'z') {
                        self.children[char - ('a' | 32)] = try Node.init(allocator);
                        try self.children[char - ('a' | 32)].?.insert(allocator, string[1..]);
                    }
                }
            }
        }
    };
};
