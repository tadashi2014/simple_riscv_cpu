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
You need a cross-compiler such as `riscv64-unknown-elf-gcc`.

### Option A – Homebrew (recommended, easiest)

```bash
brew tap riscv-software-src/riscv
brew install riscv-gnu-toolchain
```

This installs `riscv64-unknown-elf-gcc`, `riscv64-unknown-elf-objdump`, etc.
under `/opt/homebrew/bin/` (Apple Silicon) or `/usr/local/bin/` (Intel).

The build script detects this toolchain automatically — no extra configuration
is needed.

Verify:

```bash
riscv64-unknown-elf-gcc --version
```

> **Note on older toolchain builds:** some pre-2024 builds of the Homebrew
> formula installed the prefix as `riscv32-unknown-elf-`.  The build script
> auto-detects both prefixes (32-bit takes priority when both are present).

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
| 5.5 | Patches test-suite Makefiles to add `_zicsr_zifencei` (GCC ≥ 12 only) |
| 6 | `gmake RISCV_PREFIX=<auto-detected>` inside `riscv-compliance/` |

### Environment variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `RISCV_PREFIX` | auto-detected (`riscv32-unknown-elf-` → `riscv64-unknown-elf-`) | Toolchain prefix |
| `RISCV_TOOLCHAIN_BIN` | *(unset)* | Prepended to `$PATH` |
| `MAKE` | `gmake` (macOS) / `make` (Linux) | Override make binary |

**Examples:**

```bash
# Toolchain in a non-standard location
RISCV_TOOLCHAIN_BIN=/opt/riscv/bin ./build_and_run_test.sh

# Explicitly force the 64-bit multilib prefix (auto-detected by default)
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

### `riscv64-unknown-elf-gcc: command not found` (or `riscv32-unknown-elf-gcc`)

Install the RISC-V toolchain (see §3) and ensure its `bin/` is on your `PATH`.
The script auto-detects `riscv32-unknown-elf-gcc` first, then `riscv64-unknown-elf-gcc`.

### `extension 'zicsr' required` / `extension 'zifencei' required` assembler errors

GCC 12 removed the Zicsr (CSR instructions such as `csrr`, `csrw`, `csrrw`) and
Zifencei (`fence.i`) sub-extensions from the base `rv32i` / `rv64i` architecture
profiles.  They must now be listed explicitly in `-march=` (for example
`-march=rv32i_zicsr_zifencei`).

`build_and_run_test.sh` detects the GCC major version automatically and patches
the test-suite Makefiles to add `_zicsr_zifencei` when GCC ≥ 12 is found.  No
manual action is required.

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
