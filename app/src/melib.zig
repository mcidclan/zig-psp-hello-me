const sdk = @import("pspsdk");

extern var __start__me_section: u8;
extern var __stop__me_section: u8;

const ME_HANDLER_BASE: u32 = 0xbfc00000;

pub inline fn hw(addr: u32) *volatile u32 {
  return @ptrFromInt(addr);
}

fn unlockHwUserRegisters() void {
  var r: u32 = 0xbc000030;
  while (r <= 0xbc000044) : (r += 4) {
    hw(r).* = 0xffffffff;
  }
  asm volatile("sync\n");
}

fn unlockMemory() void {
  var r: u32 = 0xbc000000;
  while (r <= 0xbc00002c) : (r += 4) {
    hw(r).* = 0xffffffff;
  }
  asm volatile("sync\n");
}

pub fn dcacheWritebackInvalidateAll() void {
  var i: u32 = 0;
  while (i < 8192) : (i += 64) {
    asm volatile ("cache 0x14, 0(%[i])" : : [i] "r" (i));
    asm volatile ("cache 0x14, 0(%[i])" : : [i] "r" (i));
  }
  asm volatile ("sync");
}

fn meSection() []const u8 {
  const start: [*]const u8 = @ptrCast(&__start__me_section);
  const size = @intFromPtr(&__stop__me_section) - @intFromPtr(&__start__me_section);
  return start[0..size];
}

pub var meProcess: ?*const fn() c_int = null;

pub export fn meLoop() callconv(.c) void {
  unlockHwUserRegisters();
  unlockMemory();
  
  while (true) {
    dcacheWritebackInvalidateAll();
    if (meProcess) |f| {
      if (f() == 0) break;
    }
  }
  
  //halt();
}

pub extern fn meHandler() callconv(.c) void;

comptime {
  asm (
    \\.section _me_section, "ax"
    \\.global meHandler
    \\meHandler:
    \\.set noat
    \\.set noreorder
    \\lui   $v0, 0xbc10
    \\li    $v1, 0x02
    \\sw    $v1, 0x40($v0)
    \\li    $v1, 0x07
    \\sw    $v1, 0x50($v0)
    \\li    $v1, -1
    \\sw    $v1, 0x04($v0)
    \\sync
    \\lui   $k0, 0x3000
    \\mtc0  $k0, $12
    \\sync
    \\lui   $k0, %hi(meLoop)
    \\addiu $k0, $k0, %lo(meLoop)
    \\lui   $k1, 0x8000
    \\or    $k0, $k0, $k1
    \\cache 0x8, 0($k0)
    \\sync
    \\jr    $k0
    \\nop
    \\.set reorder
    \\.set at
  );
}

pub fn init() callconv(.c) c_int {

  const sec = meSection();
  const handler: [*]u8 = @ptrFromInt(ME_HANDLER_BASE);
  for (0..sec.len) |i| handler[i] = sec[i];
  
  sdk.sceKernelDcacheWritebackInvalidateAll();
  sdk.sceKernelIcacheInvalidateAll();
  
  hw(0xbc10004c).* = 0x04;
  hw(0xbc10004c).* = 0x00;
  asm volatile ("sync");
  
  return 0;
}
