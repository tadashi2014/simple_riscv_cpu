# simple_riscv_cpu

Verilog implementation of a simple RISC-V CPU, simulated with [Verilator](https://www.veripool.org/verilator/) and tested with the [riscv-compliance](https://github.com/damdoy/riscv-compliance) test suite.

---

## Quick Start

### Prerequisites

| Tool | Minimum version | Install (macOS Homebrew) | Install (Debian/Ubuntu) |
|------|-----------------|--------------------------|-------------------------|
| Verilator | 5.x | `brew install verilator` | `sudo apt install verilator` |
| GNU Make | 4.x | `brew install make` | `sudo apt install make` |
| Git | any | `brew install git` | `sudo apt install git` |
| C++ compiler | clang 14 / g++ 12 | Xcode CLT: `xcode-select --install` | `sudo apt install build-essential` |
| riscv64-unknown-elf-gcc | any | see below | see below |

> **macOS note:** The system `make` on macOS is BSD make, which is **not** compatible with Verilator's generated `Makefile`. Install GNU Make via Homebrew (`brew install make`) – the script will automatically use `gmake`.

### RISC-V GCC toolchain (needed for compliance tests)

**macOS (Homebrew):**
```bash
brew tap riscv-software-src/riscv
brew install riscv-gnu-toolchain   # provides riscv64-unknown-elf-gcc
```

The build script auto-detects the prefix (`riscv32-unknown-elf-` first, then `riscv64-unknown-elf-`); no extra configuration is needed.

**Linux:**
```bash
# Debian/Ubuntu: pre-built binaries
sudo apt install gcc-riscv64-unknown-elf
# or build from source: https://github.com/riscv-collab/riscv-gnu-toolchain
```

### Clone with submodules

```bash
git clone --recurse-submodules https://github.com/tadashi2014/simple_riscv_cpu.git
cd simple_riscv_cpu
```

If you already cloned without `--recurse-submodules`:

```bash
git submodule update --init --recursive
```

### Build and run compliance tests

```bash
./build_and_run_test.sh
```

The script will:
1. Check that `verilator` and GNU Make are available.
2. Initialise the `riscv-compliance` submodule if necessary.
3. Run Verilator to generate the C++ model.
4. Compile `Vsimple_cpu`.
5. Copy the binary into `riscv-compliance/` and run `make` there.

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `RISCV_PREFIX` | auto-detected | Toolchain prefix (`riscv32-unknown-elf-` or `riscv64-unknown-elf-`) |
| `RISCV_TOOLCHAIN_BIN` | *(unset)* | Path to toolchain `bin/` directory (prepended to `$PATH`) |
| `MAKE` | auto-detected | Override the make command (`gmake`, `make`, …) |

**Examples:**

```bash
# Custom prefix
RISCV_PREFIX=riscv64-unknown-elf- ./build_and_run_test.sh

# Toolchain in a non-standard location
RISCV_TOOLCHAIN_BIN=/opt/riscv/bin ./build_and_run_test.sh

# All in one
RISCV_TOOLCHAIN_BIN=/opt/riscv/bin RISCV_PREFIX=riscv32-unknown-elf- ./build_and_run_test.sh
```

---

## Repository Structure

```
simple_riscv_cpu/
├── simple_cpu/            Verilog source for the CPU
│   ├── simple_cpu.v
│   ├── alu/alu.v
│   └── register_file/register_file.v
├── simulation/
│   └── main.cpp           Verilator testbench (ELF loader + memory model)
├── riscv-compliance/      Git submodule (damdoy/riscv-compliance)
├── build_and_run_test.sh  Main build & test entry point
└── docs/
    └── BUILD_MAC.md       Detailed macOS setup guide
```

---

## macOS-Specific Setup

See **[docs/BUILD_MAC.md](docs/BUILD_MAC.md)** for a step-by-step guide tailored to macOS (Apple Silicon / Intel).
