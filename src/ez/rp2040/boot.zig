const ezc = @import("../constants.zig");

// Define necessary register addresses
const RESETS_RESET: *volatile u32 = @ptrFromInt(0x4000c000);
const RESETS_RESET_DONE: *volatile u32 = @ptrFromInt(0x4000c008);
const IO_BANK0_GPIO13_CTRL: *volatile u32 = @ptrFromInt(0x4001406c);
const SIO_GPIO_OE_SET: *volatile u32 = @ptrFromInt(0xd0000024);
const SIO_GPIO_OUT_XOR: *volatile u32 = @ptrFromInt(0xd000001c);

pub fn boot() linksection(ezc.boot_section) callconv(.c) void {
    // Bring IO_BANK0 out of reset state
    RESETS_RESET.* &= ~@as(u32, 1 << 5);
    while ((RESETS_RESET_DONE.* & @as(u32, 1 << 5)) == 0) {}

    // Set GPIO 13 function to SIO
    IO_BANK0_GPIO13_CTRL.* = 5;

    // Set output enable for GPIO 13 in SIO
    SIO_GPIO_OE_SET.* |= @as(u32, 1 << 13);

    while (true) {
        // Wait for some time
        for (0..200000) |_| {
            asm volatile ("");
        }

        // Flip output for GPIO 13
        SIO_GPIO_OUT_XOR.* |= @as(u32, 1 << 13);
    }
}
