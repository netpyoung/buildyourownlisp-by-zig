const std = @import("std");
const module_builtin = @import("builtin");

const c_libedit = if (module_builtin.os.tag != .windows) @cImport({
    // https://salsa.debian.org/debian/libedit/-/blob/master/src/editline/readline.h
    @cInclude("editline/readline.h");
}) else struct {};

pub fn main() void {
    std.debug.print(
        \\ Lispy Version 0.0.0.0.1
        \\ Press Ctrl+c to Exit
        \\
    , .{});

    while (true) {
        const input: [*c]u8 = c_libedit.readline("lispy> ");
        defer std.c.free(input);

        _ = c_libedit.add_history(input);

        std.debug.print("No you're a {s}\n", .{input});
    }
}

test "string test" {
    const expect = std.testing.expect;
    const expectEqual = std.testing.expectEqual;
    const expectEqualStrings = std.testing.expectEqualStrings;

    const allocator = std.testing.allocator;

    const z_str: []const u8 = "asdf";
    const c_str: [:0]u8 = try allocator.dupeZ(u8, z_str);
    defer allocator.free(c_str);

    try expectEqual(4, z_str.len);
    try expectEqual(4, c_str.len);
    try expect(std.mem.eql(u8, z_str, c_str));

    try expectEqual(0, c_str[4]);
    // try expectEqual(0, z_str[4]); // error: index 4 outside slice of length 4
    // try expectEqual(0, c_str[5]); // panic: index out of bounds: index 5, len 4

    try expectEqualStrings(z_str, c_str);
}
