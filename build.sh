#!/bin/bash
set -e

YELLOW='\033[1;33m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
NC='\033[0m'

echo -e "${YELLOW}> Cleaning...${NC}"
rm -rf kcall/.zig-cache app/.zig-cache

rm -f app/src/kcall.zig app/src/linkfile.ld
rm -f kcall/src/linkfile.ld kcall/exports.c kcall/kcall.S

find kcall/zig-out -mindepth 1 -not -name "usbhostfs_pc" -delete 2>/dev/null || true
find app/zig-out -mindepth 1 -not -name "usbhostfs_pc" -delete 2>/dev/null || true

echo -e "${BLUE}> Building kcall...${NC}"
cd kcall && zig build && cd ..

echo -e "${BLUE}> Building app...${NC}"
cd app && zig build

echo -e "${GREEN}> Done!${NC}"
