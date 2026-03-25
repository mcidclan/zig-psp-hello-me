const std = @import("std");

pub fn build(b: *std.Build) void {
  const target = getTarget(b);

  const exe = b.addExecutable(.{
    .name = "kcall",
    .root_module = b.createModule(.{
      .root_source_file = b.path("src/main.zig"),
      .target = target,
      .optimize = .ReleaseSmall,
      //.strip = true,
    }),
  });

  const pspsdk_dep = b.dependency("pspsdk", .{});
  const pspsdk_mod = pspsdk_dep.module("pspsdk");
  exe.root_module.addImport("pspsdk", pspsdk_mod);
  exe.entry = .{ .symbol_name = "module_start" };

  const exports = [2]*std.Build.Step.Run{
    b.addSystemCommand(&.{
      "sh", "-c",
      std.fmt.allocPrint(b.allocator, "psp-build-exports -b {s} > {s}", .{
        b.pathFromRoot("src/exports.exp"),
        b.pathFromRoot("exports.c"),
      }) catch |err| @panic(@errorName(err)),
    }),
    b.addSystemCommand(&.{
      "psp-build-exports",
      "-s",
      b.pathFromRoot("src/exports.exp"),
    }),
  };
  exe.step.dependOn(&exports[0].step);
  exe.step.dependOn(&exports[1].step);

  const pspdev = b.graph.environ_map.get("PSPDEV") orelse @panic("PSPDEV not set");
  const inc = std.fs.path.join(
    b.allocator, &.{ pspdev, "psp/sdk/include" }
  ) catch |err| @panic(@errorName(err));
  
  exe.root_module.addCSourceFile(.{
    .file = b.path("exports.c"),
    .flags = &.{ "-G0", "-Os", "-I", inc, "-I", "" },
  });
  
  b.installArtifact(exe);
}

fn getTarget(b: *std.Build) std.Build.ResolvedTarget {
  var feature_set = std.Target.Cpu.Feature.Set.empty;
  feature_set.addFeature(@intFromEnum(std.Target.mips.Feature.single_float));
  return b.resolveTargetQuery(.{
    .abi = .eabi,
    .cpu_arch = .mipsel,
    .os_tag = .freestanding,
    .cpu_model = .{ .explicit = &std.Target.mips.cpu.mips32r2 },
    .cpu_features_add = feature_set,
  });
}
