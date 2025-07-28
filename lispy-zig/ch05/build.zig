const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "ch05",
        .root_source_file = b.path("src/ch05.zig"),
        .target = target,
        .optimize = optimize,
    });

    { // library: mpc
        exe.addIncludePath(.{ .cwd_relative = "../mpc" });
        exe.addCSourceFile(.{ .file = b.path("../mpc/mpc.c") });
    }

    exe.linkLibC();

    // zig-out/bin/ 아래에 실행파일을 복사해 줌.
    b.installArtifact(exe);

    // zig build <원하는 스탭이름>을 하면 바이너리를 실행함.
    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_cmd.step);
}
