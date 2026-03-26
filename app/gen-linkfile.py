import sys

src_ld = sys.argv[1]
dst_ld = sys.argv[2]

with open(src_ld) as f:
    lines = f.readlines()

result = []
for line in lines:
    result.append(line)
    if '.text 0 :' in line:
        result.append('   _me_section : { __start__me_section = .; KEEP(*(_me_section)) __stop__me_section = .; }\n')

with open(dst_ld, 'w') as f:
    f.writelines(result)
