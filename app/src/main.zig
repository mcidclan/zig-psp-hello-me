const sdk = @import("pspsdk");
const kcall = @import("kcall");
const utils = @import("./utils.zig");
const debug = utils.debug;

comptime {
  asm (sdk.extra.module.module_info("hello-me", .{ .mode = .User }, 1, 1));
}

fn testKernel() callconv(.c) c_int {
  while(true){
    _ = sdk.sceKernelDelayThread(1000);
  }
  //debug.psp.print("Hello From Kernel!\n");
  
  return 0;
}

pub fn main() void {
  debug.psp.screenInit();

  const mod = utils.pspSdkLoadStartModule("host0:/kcall.prx", 1);
  if (mod < 0) {
    debug.printf("Can't load prx, mod: {x}!", .{mod});
    _ = sdk.sceKernelDelayThread(5000000);
    sdk.sceKernelExitGame();
  }
  
  debug.psp.print("Hello From User!\n");
  kcall.kcall(&testKernel);

  _ = sdk.sceKernelDelayThread(5000000);
  sdk.sceKernelExitGame();
}
