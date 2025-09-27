const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const asciigraph = b.dependency("asciigraph", .{});

    inline for ([_]struct {
        name: []const u8,
        src: []const u8,
    }{
        .{ .name = "basic", .src = "basic/main.zig" },
        .{ .name = "sine", .src = "sine/main.zig" },
    }) |execfg| {
        const exe_name = execfg.name;

        const exe = b.addExecutable(.{
            .name = exe_name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(execfg.src),
                .target = target,
                .optimize = optimize,
            }),
        });

        exe.root_module.addImport("asciigraph", asciigraph.module("asciigraph"));

        b.installArtifact(exe);
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        const step_name = exe_name;
        const run_step = b.step(step_name, "Run the app " ++ exe_name);
        run_step.dependOn(&run_cmd.step);
    }
}
