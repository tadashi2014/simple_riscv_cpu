# Building on macOS (Apple Silicon / Intel)

This guide walks through every step required to build `simple_riscv_cpu` and run the `riscv-compliance` test suite on macOS.

Tested on:
- macOS Tahoe 26.x, Apple Silicon (M-series)
- macOS Ventura / Sonoma / Sequoia, Intel

---

## 1. Install Homebrew

If you do not already have [Homebrew](https://brew.sh) installed:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

---

## 2. Install build dependencies

```bash
# C++ compiler (needed for Verilator-generated code)
xcode-select --install   # Installs Xcode Command Line Tools (includes clang)

# Verilator (HDL simulator)
brew install verilator

# GNU Make  – the system 'make' on macOS is BSD make, which is incompatible
#             with Verilator's generated Makefile
brew install make        # installs as 'gmake'

# Git (if not already present)
brew install git
```

---

## 3. Install a RISC-V GCC cross-compiler

The `riscv-compliance` test suite compiles test programs for the RISC-V ISA.
You need a cross-compiler such as `riscv32-unknown-elf-gcc`.

### Option A – Homebrew (recommended, easiest)

```bash
brew tap riscv-software-src/riscv
brew install riscv-gnu-toolchain
```

This installs `riscv32-unknown-elf-gcc`, `riscv32-unknown-elf-objdump`, etc.
under `/opt/homebrew/bin/` (Apple Silicon) or `/usr/local/bin/` (Intel).

Verify:

```bash
riscv32-unknown-elf-gcc --version
```

### Option B – Pre-built binaries from SiFive / GitHub releases

Download a pre-built tarball from  
<https://github.com/sifive/freedom-tools/releases> or  
<https://github.com/riscv-collab/riscv-gnu-toolchain/releases>

Extract it (e.g. to `/opt/riscv`) and add the `bin/` directory to your
shell's `PATH`:

```bash
export PATH="/opt/riscv/bin:$PATH"
```

Or set `RISCV_TOOLCHAIN_BIN` when running the script (see §5).

### Option C – riscv64-unknown-elf (multilib)

If your toolchain uses the `riscv64-unknown-elf-` prefix instead of
`riscv32-unknown-elf-`, pass the prefix explicitly:

```bash
RISCV_PREFIX=riscv64-unknown-elf- ./build_and_run_test.sh
```

---

## 4. Clone the repository with submodules

```bash
git clone --recurse-submodules https://github.com/tadashi2014/simple_riscv_cpu.git
cd simple_riscv_cpu
```

If you already cloned without `--recurse-submodules`:

```bash
git submodule update --init --recursive
```

---

## 5. Build and run compliance tests

```bash
./build_and_run_test.sh
```

### What the script does

| Step | Command |
|------|---------|
| 1 | Checks that `verilator` and `gmake` are available |
| 2 | Inits the `riscv-compliance` submodule if needed |
| 3 | `verilator -Wall --cc simple_cpu/... --exe simulation/main.cpp` |
| 4 | `gmake -j<N> -C obj_dir -f Vsimple_cpu.mk Vsimple_cpu` |
| 5 | Copies `Vsimple_cpu` into `riscv-compliance/` |
| 6 | `gmake RISCV_PREFIX=riscv32-unknown-elf-` inside `riscv-compliance/` |

### Environment variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `RISCV_PREFIX` | `riscv32-unknown-elf-` | Toolchain prefix |
| `RISCV_TOOLCHAIN_BIN` | *(unset)* | Prepended to `$PATH` |
| `MAKE` | `gmake` (macOS) / `make` (Linux) | Override make binary |

**Examples:**

```bash
# Toolchain in a non-standard location
RISCV_TOOLCHAIN_BIN=/opt/riscv/bin ./build_and_run_test.sh

# Use 64-bit multilib toolchain (riscv64-unknown-elf-gcc --march=rv32i)
RISCV_PREFIX=riscv64-unknown-elf- ./build_and_run_test.sh
```

---

## 6. Expected output

A successful run looks like:

```
==> Generating Verilator model ...
==> Compiling Vsimple_cpu ...
==> Running riscv-compliance tests (RISCV_PREFIX=riscv32-unknown-elf-) ...
...
PASS: I-ADD-01 ...
PASS: I-ADDI-01 ...
...
==> All done.
```

Failures are printed as `FAIL: <test-name>`.

---

## 7. Troubleshooting

### `gmake: command not found`

Install GNU Make: `brew install make`.

### `riscv32-unknown-elf-gcc: command not found`

Install the RISC-V toolchain (see §3) and ensure its `bin/` is on your `PATH`.

### Verilator warnings treated as errors

The `-Wall` flag makes Verilator print warnings. They do **not** abort the build unless they are promoted to errors by your Verilator version. If the build fails with a Verilator warning, report an issue.

### Apple Clang linker errors

Ensure Xcode Command Line Tools are up to date:

```bash
softwareupdate --all --install --force
xcode-select --install
```

### `make` (BSD make) errors in `obj_dir/`

Make sure you are using GNU Make (`gmake`). The script auto-detects this on macOS, but you can force it:

```bash
MAKE=gmake ./build_and_run_test.sh
```
