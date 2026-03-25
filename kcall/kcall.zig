pub const KFunc = *const fn () callconv(.c) c_int;
pub extern fn kcall(func: KFunc) callconv(.c) void;

comptime {
  asm (
    \\.set push
    \\.set noreorder
    \\.section .rodata.sceResident, "a"
    \\__stub_modulestr_kcall:
    \\.asciz "kcall"
    \\.align 2
    \\.section .lib.stub, "a", @progbits
    \\.global __stub_module_kcall
    \\__stub_module_kcall:
    \\.word __stub_modulestr_kcall
    \\.word 0x40090000
    \\.hword 0x5
    \\.hword 1
    \\.word __stub_idtable_kcall
    \\.word __stub_text_kcall
    \\.section .rodata.sceNid, "a"
    \\__stub_idtable_kcall:
    \\.section .sceStub.text, "ax", @progbits
    \\__stub_text_kcall:
    \\.set pop
  );
  asm (
    \\.set push
    \\.set noreorder
    \\.section .sceStub.text, "ax", @progbits
    \\.globl kcall
    \\.type kcall, @function
    \\.ent kcall, 0
    \\kcall:
    \\jr $ra
    \\nop
    \\.end kcall
    \\.size kcall, .-kcall
    \\.section .rodata.sceNid, "a"
    \\.word 0x5AC35241
    \\.set pop
  );
}
