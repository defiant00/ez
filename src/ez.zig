pub const constant = struct {
    pub const section = struct {
        pub const boot = "ez.boot";
        pub const main = "ez.main";
    };
};

pub const rp2040 = @import("ez/rp2040.zig");
