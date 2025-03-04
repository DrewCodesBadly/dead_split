const std = @import("std");

// TODO: Make real
pub fn build(b: *std.Build) !void {
    // const dir = try b.build_root.handle.openDir("zig-autosplitters").iterate();
    // while (try dir.next()) |file| {
    //     const exe = b.addWe
    // }

    const exe = b.addExecutable(.{ 
        .name = "hyper-light-drifter", 
        .root_source_file = b.path("zig-autosplitters/hyper-light-drifter.zig"), 
        .target = b.resolveTargetQuery(.{ .cpu_arch = .wasm32, .os_tag = .freestanding }), 
        .optimize = .ReleaseFast });
    exe.entry =  .enabled; // TODO: Consider enabling
    exe.rdynamic = true;

    b.installArtifact(exe);
}