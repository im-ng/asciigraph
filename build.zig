const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const module = b.addModule("asciigraph", .{
        .root_source_file = b.path("src/asciigraph.zig"),
        .target = target,
        .optimize = optimize,
    });

    const test_module = b.createModule(.{
        .root_source_file = b.path("src/asciigraph.zig"),
        .target = target,
        .optimize = optimize,
    });
    test_module.addImport("asciigraph", module);

    const unit_tests = b.addTest(.{
        .root_module = test_module,
    });

    // A run step that will run the second test executable.
    const run_exe_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_exe_tests.step);
}
