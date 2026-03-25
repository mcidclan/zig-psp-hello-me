const sdk = @import("pspsdk");
const debug = sdk.extra.debug;

comptime {
  asm (sdk.extra.module.module_info("meds", .{ .mode = .User }, 1, 1));
}

pub fn main() void {
  debug.screenInit();
  debug.print("Hello!\n");
  
  _ = sdk.sceKernelDelayThread(5000000);
  sdk.sceKernelExitGame();
}
