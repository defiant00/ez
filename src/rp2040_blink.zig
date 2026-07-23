const std = @import("std");

const ez = @import("ez");
export const boot = ez.rp2040.boot.boot;

// Define necessary register addresses
const io_bank0_gpio13_ctrl: *volatile u32 = @ptrFromInt(0x4001406c);
const sio_gpio_oe_set: *volatile u32 = @ptrFromInt(0xd0000024);
const sio_gpio_out_xor: *volatile u32 = @ptrFromInt(0xd000001c);

export fn main() linksection(ez.constant.section.main) void {
    // Set GPIO 13 function to SIO
    io_bank0_gpio13_ctrl.* = 5;

    // Set output enable for GPIO 13 in SIO
    sio_gpio_oe_set.* |= @as(u32, 1 << 13);

    while (true) {
        // Wait for some time
        for (0..200000) |_| {
            asm volatile ("");
        }

        // Flip output for GPIO 13
        sio_gpio_out_xor.* |= @as(u32, 1 << 13);
    }

    // 0x2004_2000
    //  | bank 5 (4k)
    // 0x2004_1000
    //  | bank 4 (4k)
    // 0x2004_0000
    //  | sram (banks 0-3) (256k)
    // 0x2000_0000
    //
    // 0x1080_0000
    //  | flash (8m)
    // 0x1000_0000
}
