#!/bin/bash
# tools/ch32-qemu.sh -- run the bare-metal CH32 image under qemu-riscv32.
#
# The same build as tools/ch32-size.sh (same runtime archive, preset, flags
# and board files: tiny stdio, the 56-byte setjmp), linked for qemu's Linux
# user mode (baremetal/qemu: kernel stack, write/exit syscalls, malloc over
# a fixed QEMU_HEAP_KB array, default 16 = what a CH32V203 has left).
# Each app/qemu/*.rb runs and its output is compared with its .expected
# (CRuby's). No MMIO here: the CH32 register blink cannot run.
#
# Usage: RT_DIR=build/rt-riscv32imac-tiny tools/ch32-qemu.sh [app.rb ...]
# Environment: as tools/ch32-size.sh (SPINEL_SRC, SPINEL_PRESET, SPINEL_FLAGS,
#   APP_DEFS, RT_DIR), plus QEMU_HEAP_KB (forces one heap size for all).
# A test declares a bigger heap with `# qemu-heap-kb: N` in its first lines.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
QEMU="${QEMU:-$(command -v qemu-riscv32-static || command -v qemu-riscv32)}"
[[ -x "$QEMU" ]] || { echo "error: no qemu-riscv32" >&2; exit 1; }
[[ $# -gt 0 ]] || set -- "$ROOT"/app/qemu/*.rb
build_one() { # build_one <app.rb> <heap KB>: the image, with the board file for that heap
  local board="$ROOT/build/qemu-board-$2.c"
  mkdir -p "$ROOT/build"
  sed "s/^#define QEMU_HEAP_KB 16$/#define QEMU_HEAP_KB $2/" "$ROOT/baremetal/qemu/board.c" > "$board"
  CRT0=baremetal/qemu/crt0.S LDSCRIPT=baremetal/qemu/qemu.ld \
  EXTRA_SRCS="${EXTRA_SRCS:-baremetal/tinystdio.c baremetal/setjmp.S} build/qemu-board-$2.c" \
  LINK_FLAGS="${LINK_FLAGS:--Wl,-z,muldefs}" TOP=0 \
    "$ROOT/tools/ch32-size.sh" "$1" | grep '^==' | sed 's/^== /   built /'
}
pass=0 fail=0
for rb in "$@"; do
  b="$(basename "$rb" .rb)"
  # a test may ask for more heap than the chip's (`# qemu-heap-kb: N`, first
  # lines); QEMU_HEAP_KB overrides every test
  heap="$(sed -n '1,10s/^# qemu-heap-kb: *\([0-9]*\).*/\1/p' "$rb" | head -1)"
  heap="${QEMU_HEAP_KB:-${heap:-16}}"
  build_one "$rb" "$heap"
  out="$ROOT/build/ch32/$b.qemu.out"
  timeout 60 "$QEMU" "$ROOT/build/ch32/$b.elf" > "$out" 2>&1; rc=$?
  if [[ $rc -eq 0 ]] && cmp -s "$out" "$rb.expected"; then
    echo "PASS $b (heap ${heap} KB)"; pass=$((pass+1))
  else
    echo "FAIL $b (exit $rc, heap ${heap} KB)"; diff "$rb.expected" "$out" | head -8; fail=$((fail+1))
  fi
done
echo "ch32-qemu: $pass pass, $fail fail"
[[ $fail -eq 0 ]]
