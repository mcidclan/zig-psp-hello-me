const std = @import("std");

pub fn build(b: *std.Build) void {
  const target = getTarget(b);

  const exe = b.addExecutable(.{
    .name = "hello-from-me",
    .root_module = b.createModule(.{
      .root_source_file = b.path("src/main.zig"),
      .target = target,
      .optimize = .ReleaseSafe, // .Debug,
    }),
  });

  const pspsdk_dep = b.dependency("pspsdk", .{});
  const pspsdk_mod = pspsdk_dep.module("pspsdk");
  
  const commands = [2]*std.Build.Step.Run{
    b.addSystemCommand(&.{
      "python3",
      b.pathFromRoot("gen-linkfile.py"),
      pspsdk_dep.path("tools/linkfile.ld").getPath(b),
      b.pathFromRoot("src/linkfile.ld"),
    }),
    
    b.addSystemCommand(&.{
      "cp",
      b.pathFromRoot("../kcall/kcall.zig"),
      b.pathFromRoot("src/kcall.zig"),
    }),
  };
  
  for (1..commands.len) |i| {
    commands[i].step.dependOn(&commands[i - 1].step);
  }
  for (commands) |cmd| exe.step.dependOn(&cmd.step);

  const kcall_mod = b.createModule(.{
    .root_source_file = b.path("src/kcall.zig"),
  });
  
  exe.root_module.addImport("kcall", kcall_mod);
  exe.root_module.addImport("pspsdk", pspsdk_mod);
  
  exe.setLinkerScript(b.path("src/linkfile.ld"));
  exe.entry = .{ .symbol_name = "module_start" };
  exe.link_eh_frame_hdr = true;
  exe.link_emit_relocs = true;
    
  const prxgen = pspsdk_dep.artifact("zPRXGen");
  const prx = b.addRunArtifact(prxgen);
  prx.addArtifactArg(exe);
  
  const prx_file = prx.addOutputFileArg("app.prx");
  const install_prx = b.addInstallBinFile(prx_file, "app.prx");
  b.getInstallStep().dependOn(&install_prx.step);
  
  const install_kcall = b.addInstallBinFile(
    b.path("../kcall/zig-out/bin/kcall.prx"),
    "kcall.prx",
  );
  b.getInstallStep().dependOn(&install_kcall.step);
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
