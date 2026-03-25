const sdk = @import("pspsdk");
const k_call = @import("kcall.zig");
pub const KFunc = k_call.KFunc;

comptime {
  asm (
    \\.section .rodata.sceModuleInfo, "a", @progbits
    \\.globl module_info
    \\.p2align 5
    \\module_info:
    \\.hword 0x1006
    \\.byte 1
    \\.byte 1
    \\.ascii "kcall"
    \\.space 22
    \\.byte 0
    \\.word _gp
    \\.4byte __lib_ent_top
    \\.4byte __lib_ent_bottom
    \\.4byte __lib_stub_top
    \\.4byte __lib_stub_bottom
  );
}

pub export fn kcall(func: KFunc) callconv(.c) void {
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
