const sdk = @import("pspsdk");
const k_call = @import("kcall.zig");
pub const KFunc = k_call.KFunc;

pub export fn kCall(func: KFunc) callconv(.c) void {
  _ = func();
}

pub export fn module_start(args: c_int, argp: ?*anyopaque) callconv(.c) c_int {
  _ = args;
  _ = argp;
  var p: ?*anyopaque = null;
  var s: c_int = 0;
  _ = sdk.c.sceSuspendForUser.sceKernelVolatileMemLock(0, @ptrCast(&p), &s);
  return 0;
}

pub export fn module_stop() callconv(.c) c_int {
  return 0;
}
