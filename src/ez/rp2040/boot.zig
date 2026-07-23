const ez = @import("../../ez.zig");

// Define necessary register addresses
const resets_reset: *volatile u32 = @ptrFromInt(0x4000_C000);
const resets_reset_done: *volatile u32 = @ptrFromInt(0x4000_C008);

const xip_ctrl_base: *volatile u32 = @ptrFromInt(0x1400_0000);
const xip_ssi_base: *volatile u32 = @ptrFromInt(0x1800_0000);
const xip_ssi_ssi: *volatile u32 = @ptrFromInt(0x1800_0008);
const xip_ssi_baudr: *volatile u32 = @ptrFromInt(0x1800_0014);
const xip_ssi_spi: *volatile u32 = @ptrFromInt(0x1800_00F4);

pub fn boot() linksection(ez.constant.section.boot) callconv(.c) void {
    // Bring IO bank 0 out of reset state
    resets_reset.* &= ~@as(u32, 1 << 5);
    while ((resets_reset_done.* & @as(u32, 1 << 5)) == 0) {}

    // setup flash
    xip_ctrl_base.* = 0; // disable XIP cache
    xip_ssi_ssi.* = 0; // disable SSI
    xip_ssi_baudr.* = 4; // set BAUDR
    xip_ssi_base.* = (31 << 16) | (3 << 8); // set CTRL0
    xip_ssi_spi.* = (3 << 24) | (2 << 8) | (6 << 2); // set SPI CTRL0
    xip_ssi_ssi.* = 1; // enable SSI

    // copy to ram
    const count = 64 * 1024 / 4; // 64kb / 4 bytes per u32
    const source: [*]u32 = @ptrFromInt(0x1000_0100); // skip 256b bootloader
    const dest: [*]u32 = @ptrFromInt(0x2000_0000);
    for (source[0..count], dest) |s, *d| {
        d.* = s;
    }

    // jump to main
    const jump: *const fn () void = @ptrFromInt(0x2000_0001); // LSB is 1 for thumb
    jump();
}
