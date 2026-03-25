const sdk = @import("pspsdk");
const utils = @import("./utils.zig");
const debug = utils.debug;

comptime {
  asm (sdk.extra.module.module_info("hello-me", .{ .mode = .User }, 1, 1));
}

pub fn main() void {
  debug.psp.screenInit();

  const mod = utils.pspSdkLoadStartModule("host0:/kcall.prx", 1);
  if (mod < 0) {
    debug.printf("Can't load prx, mod: {x}!", .{mod});
    _ = sdk.sceKernelDelayThread(5000000);
    sdk.sceKernelExitGame();
  }
  
  debug.psp.print("Hello!");
  
  _ = sdk.sceKernelDelayThread(5000000);
  sdk.sceKernelExitGame();
}
