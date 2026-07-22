const std = @import("std");

const base_address = 0x10000000; // 0x10000000 for flash, 0x20000000 for sram
const block_bytes = 0x100;
const max_block_bytes = 476;

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
    const out_file = try cwd.createFile(io, args[2], .{});
    defer out_file.close(io);

    var out_buf: [1024]u8 = undefined;
    var out_writer = out_file.writer(io, &out_buf);
    const output = &out_writer.interface;

    var block_buf: [max_block_bytes]u8 = undefined;
    const num_blocks: u32 = @intCast(@divCeil(input.len, block_bytes));
    var block: u32 = 0;
    while (block * block_bytes < input.len) {
        const cur_block_bytes = @min(block_bytes, input.len - (block * block_bytes));
        @memset(&block_buf, 0);
        @memcpy(block_buf[0..cur_block_bytes], input[block * block_bytes ..][0..cur_block_bytes]);

        try output.writeInt(u32, 0x0A324655, .little); // first magic number, "UF2\n"
        try output.writeInt(u32, 0x9E5D5157, .little); // second magic number
        try output.writeInt(u32, 0x00002000, .little); // flags (family ID present)
        try output.writeInt(u32, base_address + (block * block_bytes), .little); // data address
        try output.writeInt(u32, block_bytes, .little); // data size for this block in bytes
        try output.writeInt(u32, block, .little); // sequential block number, starts at 0
        try output.writeInt(u32, num_blocks, .little); // total number of blocks
        try output.writeInt(u32, 0xE48BFF56, .little); // rp2040 board family ID
        try output.writeAll(&block_buf); // data padded with zeros
        try output.writeInt(u32, 0x0AB16F30, .little); // final magic number

        block += 1;
    }
    try output.flush();
}
