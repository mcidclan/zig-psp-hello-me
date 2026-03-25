# generate kcall.zig to be used by the elf app
import sys
import re
melib_path = sys.argv[1]
stubs_path = sys.argv[2]
out_path = sys.argv[3]
with open(melib_path) as f:
  melib = f.read()

modules = {}
current_module = None
with open(stubs_path) as f:
  for line in f:
    m = re.search(r'STUB_START\s+"(\w+)"', line)
    if m:
      current_module = m.group(1)
      if current_module not in modules:
        modules[current_module] = []
    m = re.search(r'STUB_FUNC\s+(0x[0-9A-Fa-f]+),(\w+)', line)
    if m and current_module:
      modules[current_module].append((m.group(1), m.group(2)))

comptime = 'comptime {\n'

for mod, funcs in modules.items():
  count = len(funcs)
  comptime += f'''  asm (
    \\\\.set push
    \\\\.set noreorder
    \\\\.section .rodata.sceResident, "a"
    \\\\__stub_modulestr_{mod}:
    \\\\.asciz "{mod}"
    \\\\.align 2
    \\\\.section .lib.stub, "a", @progbits
    \\\\.global __stub_module_{mod}
    \\\\__stub_module_{mod}:
    \\\\.word __stub_modulestr_{mod}
    \\\\.word 0x40090000
    \\\\.hword 0x5
    \\\\.hword {count}
    \\\\.word __stub_idtable_{mod}
    \\\\.word __stub_text_{mod}
    \\\\.section .rodata.sceNid, "a"
    \\\\__stub_idtable_{mod}:
    \\\\.section .sceStub.text, "ax", @progbits
    \\\\__stub_text_{mod}:
    \\\\.set pop
  );\n'''

  for nid, func in funcs:
    comptime += f'''  asm (
    \\\\.set push
    \\\\.set noreorder
    \\\\.section .sceStub.text, "ax", @progbits
    \\\\.globl {func}
    \\\\.type {func}, @function
    \\\\.ent {func}, 0
    \\\\{func}:
    \\\\jr $ra
    \\\\nop
    \\\\.end {func}
    \\\\.size {func}, .-{func}
    \\\\.section .rodata.sceNid, "a"
    \\\\.word {nid}
    \\\\.set pop
  );\n'''

comptime += '}\n'

with open(out_path, 'w') as f:
  f.write(melib)
  f.write('\n')
  f.write(comptime)
