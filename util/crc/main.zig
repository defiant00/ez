const std = @import("std");

const bytes_to_crc = 252;

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena);
    if (args.len != 3) {
        std.debug.print("wrong args\n", .{});
        return error.WrongArgs;
    }

    const io = init.io;
    const cwd = std.Io.Dir.cwd();

    const input = try cwd.readFileAlloc(io, args[1], arena, .unlimited);

    if (input.len < bytes_to_crc + 4) {
        std.debug.print("file must have at least {d} bytes\n", .{bytes_to_crc + 4});
        return error.FileTooSmall;
    }

    if (input[bytes_to_crc] != 0 or input[bytes_to_crc + 1] != 0 or
        input[bytes_to_crc + 2] != 0 or input[bytes_to_crc + 3] != 0)
    {
        std.debug.print("crc placeholder is not empty\n", .{});
        return error.PlaceholderNotEmpty;
    }

    const checksum = std.hash.crc.@"CRC-32/MPEG-2".hash(input[0..bytes_to_crc]);

    const out_file = try cwd.createFile(io, args[2], .{});
    defer out_file.close(io);

    var out_buf: [1024]u8 = undefined;
    var out_writer = out_file.writer(io, &out_buf);
    const output = &out_writer.interface;

    try output.writeAll(input[0..bytes_to_crc]);
    try output.writeInt(u32, checksum, .little);
    try output.writeAll(input[bytes_to_crc + 4 ..]);
    try output.flush();
}
