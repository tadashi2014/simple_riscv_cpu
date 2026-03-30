#!/usr/bin/env bash
# build_and_run_test.sh – Build Vsimple_cpu with Verilator and run riscv-compliance tests.
#
# Environment variables (all optional):
#   RISCV_PREFIX          Toolchain prefix, e.g. riscv32-unknown-elf-  (default: riscv32-unknown-elf-)
#   RISCV_TOOLCHAIN_BIN   Directory that contains the RISC-V toolchain binaries.
#                         When set, it is prepended to PATH before make is invoked.
#   MAKE                  Override the make command (default: auto-detected).
#
# macOS quick-start (Homebrew):
#   brew install verilator make riscv-gnu-toolchain
#   ./build_and_run_test.sh

set -euo pipefail

# ---------------------------------------------------------------------------
# Helper: print a message and exit with failure
# ---------------------------------------------------------------------------
die() { echo "ERROR: $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Detect operating system
# ---------------------------------------------------------------------------
OS="$(uname -s)"

# ---------------------------------------------------------------------------
# Detect the right 'make' to use.
# On macOS, 'make' is BSD make which is not compatible with the Verilator
# generated Makefile. Prefer 'gmake' (GNU Make) when available.
# ---------------------------------------------------------------------------
if [ -z "${MAKE:-}" ]; then
  if [ "$OS" = "Darwin" ]; then
    if command -v gmake >/dev/null 2>&1; then
      MAKE=gmake
    else
      # Fall back to 'make' but warn if it is BSD make
      if make --version 2>/dev/null | grep -q "GNU Make"; then
        MAKE=make
      else
        echo "ERROR: 'gmake' (GNU Make) not found." >&2
        echo "  Install it with: brew install make" >&2
        echo "  Then re-run:     MAKE=gmake $0" >&2
        exit 1
      fi
    fi
  else
    MAKE=make
  fi
fi
export MAKE

# ---------------------------------------------------------------------------
# Check required tools
# ---------------------------------------------------------------------------
check_tool() {
  local cmd="$1"; shift
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: '$cmd' not found." >&2
    echo "  $*" >&2
    exit 1
  fi
}

check_tool verilator \
  "Install with: brew install verilator  (macOS) or  sudo apt install verilator  (Debian/Ubuntu)"

check_tool "$MAKE" \
  "Install GNU Make with: brew install make  (macOS) or  sudo apt install make  (Debian/Ubuntu)"

# ---------------------------------------------------------------------------
# Prepend optional toolchain bin directory to PATH
# ---------------------------------------------------------------------------
if [ -n "${RISCV_TOOLCHAIN_BIN:-}" ]; then
  export PATH="${RISCV_TOOLCHAIN_BIN}:${PATH}"
fi

# ---------------------------------------------------------------------------
# Determine RISC-V toolchain prefix
# ---------------------------------------------------------------------------
RISCV_PREFIX="${RISCV_PREFIX:-riscv32-unknown-elf-}"

# Check that the compiler is reachable – print a friendly hint if not.
if ! command -v "${RISCV_PREFIX}gcc" >/dev/null 2>&1; then
  cat >&2 <<EOF
WARNING: '${RISCV_PREFIX}gcc' not found in PATH.
  The compliance-test step will likely fail.
  On macOS (Homebrew) you can install a RISC-V toolchain with:
    brew tap riscv-software-src/riscv
    brew install riscv-gnu-toolchain
  If your toolchain uses a different prefix, set RISCV_PREFIX before running:
    RISCV_PREFIX=riscv64-unknown-elf- $0
  If your toolchain binaries are in a non-standard directory, set RISCV_TOOLCHAIN_BIN:
    RISCV_TOOLCHAIN_BIN=/opt/riscv/bin $0
EOF
fi

# ---------------------------------------------------------------------------
# Ensure riscv-compliance submodule is present
# ---------------------------------------------------------------------------
if [ ! -f "riscv-compliance/Makefile" ]; then
  echo "INFO: riscv-compliance submodule not initialized – running 'git submodule update --init --recursive' ..."
  git submodule update --init --recursive
fi

if [ ! -f "riscv-compliance/Makefile" ]; then
  die "riscv-compliance submodule still missing after submodule init. Check your .gitmodules."
fi

# ---------------------------------------------------------------------------
# Step 1: Generate Verilator C++ model
# ---------------------------------------------------------------------------
echo "==> Generating Verilator model ..."

if [ -d "obj_dir" ]; then
  rm -rf obj_dir
fi

verilator -Wall --cc \
  simple_cpu/simple_cpu.v \
  simple_cpu/register_file/register_file.v \
  simple_cpu/alu/alu.v \
  --exe simulation/main.cpp

# ---------------------------------------------------------------------------
# Step 2: Compile the simulator binary
# ---------------------------------------------------------------------------
echo "==> Compiling Vsimple_cpu ..."
"$MAKE" -j "$(nproc 2>/dev/null || sysctl -n hw.logicalcpu 2>/dev/null || echo 1)" \
  -C obj_dir -f Vsimple_cpu.mk Vsimple_cpu

# ---------------------------------------------------------------------------
# Step 3: Copy the simulator into the riscv-compliance tree
# ---------------------------------------------------------------------------
cp obj_dir/Vsimple_cpu riscv-compliance/

# ---------------------------------------------------------------------------
# Step 4: Run riscv-compliance tests
# ---------------------------------------------------------------------------
echo "==> Running riscv-compliance tests (RISCV_PREFIX=${RISCV_PREFIX}) ..."
pushd riscv-compliance/ >/dev/null
  "$MAKE" RISCV_PREFIX="${RISCV_PREFIX}"
popd >/dev/null

echo "==> All done."
