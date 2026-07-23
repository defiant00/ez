const std = @import("std");

pub fn build(b: *std.Build) void {
    // flags
    const dump = b.option(bool, "dump", "Dump intermediate files") orelse false;

    // utilities
    const crc_exe = b.addExecutable(.{
        .name = "crc",
        .root_module = b.createModule(.{
            .root_source_file = b.path("util/crc/main.zig"),
            .target = b.graph.host,
        }),
    });

    const uf2_exe = b.addExecutable(.{
        .name = "uf2",
        .root_module = b.createModule(.{
            .root_source_file = b.path("util/uf2/main.zig"),
            .target = b.graph.host,
        }),
    });

    // firmware
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .arm,
        .os_tag = .freestanding,
        .abi = .eabi,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m0plus },
    });
    const optimize = .ReleaseSmall;

    const ez_mod = b.addModule("ez", .{
        .root_source_file = b.path("src/ez.zig"),
        .target = target,
    });

    // ez
    const ez_exe = b.addExecutable(.{
        .name = "ez",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/rp2040_blink.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "ez", .module = ez_mod },
            },
        }),
    });
    ez_exe.setLinkerScript(b.path("src/ez/rp2040/link.ld"));
    ez_exe.entry = .{ .symbol_name = "main" };

    // ez.bin
    const ez_bin = ez_exe.addObjCopy(.{ .format = .binary });

    // ez_crc.bin
    const crc_run = b.addRunArtifact(crc_exe);
    crc_run.addFileArg(ez_bin.getOutput());
    const crc_run_out = crc_run.addOutputFileArg("ez_crc.bin");

    // ez.uf2
    const uf2_run = b.addRunArtifact(uf2_exe);
    uf2_run.addFileArg(crc_run_out);
    const uf2_run_out = uf2_run.addOutputFileArg("ez.uf2");
    const install_uf2_run_out = b.addInstallBinFile(uf2_run_out, "ez.uf2");
    b.getInstallStep().dependOn(&install_uf2_run_out.step);

    if (dump) {
        // ez
        b.installArtifact(ez_exe);

        // ez.bin
        const install_ez_bin = b.addInstallBinFile(ez_bin.getOutput(), "ez.bin");
        b.getInstallStep().dependOn(&install_ez_bin.step);

        // ez_crc.bin
        const install_crc_run = b.addInstallBinFile(crc_run_out, "ez_crc.bin");
        b.getInstallStep().dependOn(&install_crc_run.step);
    }
}
