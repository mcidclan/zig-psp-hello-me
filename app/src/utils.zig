const std = @import("std");
const sdk = @import("pspsdk");

const types = sdk.c.types;
const user = sdk.c.ModuleMgrForUser;

const MAX_ARGS = 2048;

pub fn pspSdkLoadStartModule(path: [*:0]const u8, mpid: c_int) c_int {
  
  var apos: usize = 0;
  var args = std.mem.zeroes([MAX_ARGS]u8);

  const len = std.mem.len(path);
  @memcpy(args[0..len], path[0..len]);
  apos = len + 1;

  var option = std.mem.zeroInit(types.SceKernelLMOption, .{
    .size = @sizeOf(types.SceKernelLMOption),
    .mpidtext = mpid,
    .mpiddata = mpid,
    .position = 0,
    .access = 1,
  });

  const mod = user.sceKernelLoadModule(@ptrCast(path), 0, &option);
  if (mod < 0) return mod;

  var res: c_int = 0;
  const ret = user.sceKernelStartModule(mod, @intCast(apos), @ptrCast(&args[0]), &res, null);
  if (ret < 0) return ret;

  return mod;
}

pub const debug = struct {
  pub const psp = sdk.extra.debug;
  
  pub fn printf(comptime fmt: []const u8, args: anytype) void {
    var buf: [256]u8 = undefined;
    const s = std.fmt.bufPrint(&buf, fmt, args) catch unreachable;
    sdk.extra.debug.print(s);
  }
};

