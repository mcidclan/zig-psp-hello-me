const sdk = @import("pspsdk");
const kcall = @import("kcall");
const utils = @import("./utils.zig");
const melib = @import("./melib.zig");
const debug = utils.debug;

comptime {
  asm (sdk.extra.module.module_info("hello-me", .{ .mode = .User }, 1, 1));
}

var mePoc: u32 = 0;
fn meProcess() c_int {
  
  mePoc = 0x12345678;
  // todo:
  return 1;
}

// const BASE_SHARED_MEM: u32 = 0x48400000;

pub fn main() void {
  debug.psp.screenInit();

  const mod = utils.pspSdkLoadStartModule("host0:/kcall.prx", 1);
  if (mod < 0) {
    debug.printf("Can't load prx, mod: {x}!", .{mod});
    _ = sdk.sceKernelDelayThread(2000000);
    sdk.sceKernelExitGame();
  }
  
  //_ = sdk.sceDisplaySetFrameBuf(
  //  @ptrFromInt(BASE_SHARED_MEM),
  //  512,
  //  .Format8888,
  //  .NextVSync,
  //);
  
  debug.psp.print("Hello From User!\n");
  melib.meProcess = &meProcess;
  kcall.kcall(&melib.init);
  
  _ = sdk.sceKernelDelayThread(1000);
  debug.printf("meCount: {x}\n", .{mePoc});

  _ = sdk.sceKernelDelayThread(3000000);
  sdk.sceKernelExitGame();
}
