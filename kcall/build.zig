const std = @import("std");

pub fn build(b: *std.Build) void {
  const target = getTarget(b);

  const exe = b.addExecutable(.{
    .name = "kcall",
    .root_module = b.createModule(.{
      .root_source_file = b.path("src/main.zig"),
      .target = target,
      .optimize = .ReleaseSmall, // .Debug
      //.strip = true,
    }),
  });

  exe.entry = .{ .symbol_name = "module_start" };

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
