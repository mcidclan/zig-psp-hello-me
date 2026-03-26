const std = @import("std");

pub fn build(b: *std.Build) void {
  const target = getTarget(b);

  const exe = b.addExecutable(.{
    .name = "kcall",
    .root_module = b.createModule(.{
      .root_source_file = b.path("src/main.zig"),
      .target = target,
      .optimize = .ReleaseSmall,
      .strip = false,
    }),
  });
  
  const pspsdk_dep = b.dependency("pspsdk", .{});
  const pspsdk_mod = pspsdk_dep.module("pspsdk");
  exe.root_module.addImport("pspsdk", pspsdk_mod);
  
  exe.setLinkerScript(b.path("src/linkfile.ld"));
  exe.entry = .{ .symbol_name = "module_start" };
  exe.root_module.unwind_tables = .none;
  
  exe.root_module.pic = false;
  exe.link_eh_frame_hdr = false;
  exe.link_emit_relocs = true;
  
  const commands = [4]*std.Build.Step.Run{
    b.addSystemCommand(&.{
      "sh", "-c",
      std.fmt.allocPrint(b.allocator, "psp-build-exports -b {s} > {s}", .{
        b.pathFromRoot("src/exports.exp"),
        b.pathFromRoot("exports.c"),
      }) catch |err| @panic(@errorName(err)),
    }),
    b.addSystemCommand(&.{
        "python3",
        b.pathFromRoot("gen-linkfile.py"),
        pspsdk_dep.path("tools/linkfile.ld").getPath(b),
        b.pathFromRoot("src/linkfile.ld"),
    }),    
    b.addSystemCommand(&.{
      "psp-build-exports",
      "-s",
      b.pathFromRoot("src/exports.exp"),
    }),
    b.addSystemCommand(&.{
      "python3",
      b.pathFromRoot("gen-kcall-zig.py"),
      b.pathFromRoot("src/kcall.zig"),
      b.pathFromRoot("kcall.S"),
      b.pathFromRoot("kcall.zig"),
    })
  };
  
  for (1..commands.len) |i| {
    commands[i].step.dependOn(&commands[i - 1].step);
  }
  exe.step.dependOn(&commands[commands.len - 1].step);

  //const fixup = b.addSystemCommand(&.{ "psp-fixup-imports" });
  //fixup.addArtifactArg(exe);
  //fixup.step.dependOn(&exe.step);
    
  const pspdev = b.graph.environ_map.get("PSPDEV") orelse @panic("PSPDEV not set");
  const inc = std.fs.path.join(
    b.allocator, &.{ pspdev, "psp/sdk/include" }
  ) catch |err| @panic(@errorName(err));
  
  exe.root_module.addCSourceFile(.{
    .file = b.path("exports.c"),
    .flags = &.{ "-G0", "-Os", "-I", inc, "-I", "" },
  });
  
  const prxgen = pspsdk_dep.artifact("zPRXGen");
  const run = b.addRunArtifact(prxgen);
  run.addArtifactArg(exe);
  
  const prx_file = run.addOutputFileArg("kcall.prx");
  const install_prx = b.addInstallBinFile(prx_file, "kcall.prx");
  b.getInstallStep().dependOn(&install_prx.step);
    
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
