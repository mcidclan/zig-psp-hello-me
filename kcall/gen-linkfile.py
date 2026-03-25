import sys
import re

src_ld = sys.argv[1]
dst_ld = sys.argv[2]

remove_patterns = [
  '.lib.ent.top',
  '.lib.ent.btm',
  '.lib.stub.top',
  '.lib.stub.btm',
  '.lib.ent        :',
  '.lib.stub       :',
]

new_sections = """
  .lib.ent.top    : { KEEP(*(.lib.ent.top)) }
  .lib.ent        : { __lib_ent_top = .; KEEP(*(.lib.ent)) __lib_ent_bottom = .; }
  .lib.ent.btm    : { KEEP(*(.lib.ent.btm)) }
  .lib.stub.top   : { KEEP(*(.lib.stub.top)) }
  .lib.stub       : { __lib_stub_top = .; KEEP(*(.lib.stub)) __lib_stub_bottom = .; }
  .lib.stub.btm   : { KEEP(*(.lib.stub.btm)) }
"""

new_discard = """
/DISCARD/ : {
  *(.MIPS.abiflags)
  *(.reginfo)
  *(.comment)
  *(.pdr)
  *(.note.GNU-stack)
  *(.eh_frame)
  *(.eh_frame_hdr)
  *(.got)
}
"""

with open(src_ld) as f:
  content = f.read()

content = re.sub(r'\s*/DISCARD/\s*:\s*\{[^}]*\}', '', content, flags=re.DOTALL)

content = re.sub(
  r'(\.rodata\.sceModuleInfo\s*):(\s*\{)',
  r'\1 : ALIGN(32)\2',
  content
)

content = re.sub(
  r'\s*__eh_frame_hdr_start\s*=\s*\.\s*;.*?\.eh_frame\s*:\s*\{[^}]*\}',
  '',
  content,
  flags=re.DOTALL
)

lines = content.splitlines(keepends=True)
result = []
inserted = False
for line in lines:
  if any(p in line for p in remove_patterns):
    if not inserted:
      result.append(new_sections)
      inserted = True
    continue
  result.append(line)

final = ''.join(result)
last_brace = final.rfind('}')
final = final[:last_brace] + new_discard + final[last_brace:]

with open(dst_ld, 'w') as f:
  f.write(final)
