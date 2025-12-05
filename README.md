# UART - Serial Communication Module

## Table of Contents

- [UART - Serial Communication Module](#uart---serial-communication-module)
  - [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Module Architecture](#module-architecture)
  - [HDL Modules](#hdl-modules)
    - [uart\_baud\_rate\_gen](#uart_baud_rate_gen)
    - [uart\_tx\_axis](#uart_tx_axis)
    - [uart\_rx\_axis](#uart_rx_axis)
    - [sbi\_UART](#sbi_uart)
  - [CSR Registers](#csr-registers)
    - [Control Register Fields](#control-register-fields)
  - [Component Verification](#component-verification)
    - [FuseSoC Project Organization](#fusesoc-project-organization)
    - [CSR Register Generation](#csr-register-generation)
    - [Debugging and Validation](#debugging-and-validation)

---

## Introduction

This repository contains the implementation of a basic UART (Universal Asynchronous Receiver-Transmitter) module with AXI-Stream interface for transmission (TX) and reception (RX) operations.

The module provides:
- **AXI-Stream Interface** for data transmission and reception
- **Configurable Baud Rate Generator** allowing custom baud rates
- **Configuration and Status Registers (CSR)** to control UART behavior
- **Parity Support** (even or odd)
- **Flow Control Support** (CTS/RTS - Clear To Send / Request To Send)
- **Interrupt Support** for signaling UART events
- **Loopback Mode** for testing
- **Configurable FIFOs** for TX and RX data

The architecture uses an SBI (Simple Bus Interface) interface for CSR register access via an automatic generation process (regtool).

---

## Module Architecture

The general architecture of the UART module is organized as follows:

- **sbi_UART**: Main wrapper that encapsulates:
  - CSR modules (Configuration and Status Registers)
  - Baud rate generation module
  - Transmission module (uart_tx_axis)
  - Reception module (uart_rx_axis)
  - FIFOs for TX and RX

---

## HDL Modules

### uart_baud_rate_gen

**Description:** Baud rate generator that produces synchronization signals (`baud_tick` and `baud_tick_half`) necessary for sampling and transmitting data at the appropriate speed.

**Generics:**

| Generic | Type | Default Value | Description |
|---------|------|---------------|-------------|
| `BAUD_TICK_CNT_WIDTH` | integer | 16 | Width of the baud rate counter |

**Inputs/Outputs:**

| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk_i` | Input | std_logic | System clock |
| `arst_b_i` | Input | std_logic | Asynchronous reset (active low) |
| `baud_tick_en_i` | Input | std_logic | Baud rate generator enable |
| `cfg_baud_tick_cnt_max_i` | Input | std_logic_vector | Maximum value of baud rate counter |
| `baud_tick_o` | Output | std_logic | Baud rate pulse (1 cycle) |
| `baud_tick_half_o` | Output | std_logic | Mid-baud pulse (for sampling) |

**Operation:**

1. When `baud_tick_en_i` goes to '1', the counter is initialized to `cfg_baud_tick_cnt_max_i`
2. The counter decrements at each clock cycle
3. When the counter reaches zero, a `baud_tick_o` pulse is generated and the counter is reinitialized
4. At mid-count (cfg_baud_tick_cnt_max / 2), a `baud_tick_half_o` pulse is generated for sampling

---

### uart_tx_axis

**Description:** UART transmission module with AXI-Stream slave interface. Accepts data via AXI-Stream interface and transmits it serially on the `uart_tx_o` line.

**Generics:**

| Generic | Type | Default Value | Description |
|---------|------|---------------|-------------|
| `WIDTH` | natural | 8 | Data width in bits |

**Inputs/Outputs:**

| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk_i` | Input | std_logic | System clock |
| `arst_b_i` | Input | std_logic | Asynchronous reset (active low) |
| `s_axis_tdata_i` | Input | std_logic_vector | AXI-Stream data to transmit |
| `s_axis_tvalid_i` | Input | std_logic | Data validity signal |
| `s_axis_tready_o` | Output | std_logic | Ready to receive data signal |
| `uart_tx_o` | Output | std_logic | UART transmission line |
| `uart_cts_b_i` | Input | std_logic | Clear To Send (active low) |
| `baud_tick_i` | Input | std_logic | Baud rate pulse |
| `parity_enable_i` | Input | std_logic | Parity enable |
| `parity_odd_i` | Input | std_logic | Parity selection (1=odd, 0=even) |
| `debug_o` | Output | uart_tx_debug_t | Debug signals |

**Operation:**

1. When both `s_axis_tvalid_i` and `s_axis_tready_o` are '1', data is captured
2. The module builds the transmission frame: START (0) + DATA (8 bits) + PARITY (optional) + STOP (1)
3. At each `baud_tick_i` pulse, one bit is sent on `uart_tx_o`
4. The `s_axis_tready_o` signal remains low during transmission
5. If `parity_enable_i` is activated, a parity bit is calculated and inserted before the STOP bit
6. The `uart_cts_b_i` signal (Clear To Send) can suspend transmission

---

### uart_rx_axis

**Description:** UART reception module with AXI-Stream master interface. Receives data serially on the `uart_rx_i` line and provides it via AXI-Stream interface.

**Generics:**

| Generic | Type | Default Value | Description |
|---------|------|---------------|-------------|
| `WIDTH` | natural | 8 | Data width in bits |

**Inputs/Outputs:**

| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk_i` | Input | std_logic | System clock |
| `arst_b_i` | Input | std_logic | Asynchronous reset (active low) |
| `uart_rx_i` | Input | std_logic | UART reception line |
| `m_axis_tdata_o` | Output | std_logic_vector | Received AXI-Stream data |
| `m_axis_tvalid_o` | Output | std_logic | Data validity signal |
| `m_axis_tready_i` | Input | std_logic | Receiver ready signal |
| `baud_tick_i` | Input | std_logic | Baud rate pulse |
| `baud_tick_half_i` | Input | std_logic | Mid-baud pulse (for sampling) |
| `baud_tick_en_o` | Output | std_logic | Baud rate generator enable |
| `parity_enable_i` | Input | std_logic | Parity enable |
| `parity_odd_i` | Input | std_logic | Parity selection (1=odd, 0=even) |
| `debug_o` | Output | uart_rx_debug_t | Debug signals |

**Operation:**

1. The module starts in IDLE state, waiting for a falling edge on `uart_rx_i` (START bit beginning)
2. Upon edge detection, `baud_tick_en_o` is activated to start the baud generator
3. At each `baud_tick_i` pulse, one bit is received and accumulated
4. Data is sampled in the middle of each bit (thanks to `baud_tick_half_i`)
5. After receiving the STOP bit, data is validated and `m_axis_tvalid_o` is activated
6. The module waits for `m_axis_tready_i` to be '1' to consume the data
7. If `parity_enable_i` is activated, parity is verified

---

### sbi_UART

**Description:** Main wrapper that encapsulates basic UART modules with an SBI interface for CSR register access. This module manages FIFOs, interrupts, and coordinates all sub-modules.

**Generics:**

| Generic | Type | Default Value | Description |
|---------|------|---------------|-------------|
| `BAUD_RATE` | integer | 115200 | Target baud rate in bits/s |
| `CLOCK_FREQ` | integer | 50000000 | Clock frequency in Hz |
| `BAUD_TICK_CNT_WIDTH` | integer | 16 | Width of baud rate counter |
| `UART_TX_ENABLE` | boolean | true | Enable transmission |
| `UART_RX_ENABLE` | boolean | true | Enable reception |
| `USER_DEFINE_BAUD_TICK` | boolean | true | Allow user-defined baud rate configuration |
| `DEPTH_TX` | natural | 0 | TX FIFO depth (0 = no FIFO) |
| `DEPTH_RX` | natural | 0 | RX FIFO depth (0 = no FIFO) |
| `FILENAME_TX` | string | "dump_uart_tx.txt" | TX dump output file (simulation) |
| `FILENAME_RX` | string | "dump_uart_rx.txt" | RX dump output file (simulation) |

**Main Inputs/Outputs:**

| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk_i` | Input | std_logic | System clock |
| `arst_b_i` | Input | std_logic | Asynchronous reset (active low) |
| `sbi_ini_i` | Input | sbi_ini_t | SBI initiator interface (register read/write) |
| `sbi_tgt_o` | Output | sbi_tgt_t | SBI target interface |
| `uart_tx_o` | Output | std_logic | UART transmission line |
| `uart_rx_i` | Input | std_logic | UART reception line |
| `uart_cts_b_i` | Input | std_logic | Clear To Send (active low) |
| `uart_rts_b_o` | Output | std_logic | Request To Send (active low) |
| `it_o` | Output | std_logic | Interrupt signal |
| `debug_o` | Output | uart_debug_t | Debug signals |

**Operation:**

1. The module automatically calculates the baud rate counter value from `CLOCK_FREQ` and `BAUD_RATE` parameters
2. CSR registers allow configuration of:
   - TX and RX activation
   - Parity parameters
   - Loopback mode
   - Flow control (CTS/RTS)
   - Interrupts
   - FIFO depth and status
3. Transmitted and received data pass through FIFOs (if configured)
4. Interrupts can be generated on specific events (FIFO empty, FIFO full, etc.)

---

## CSR Registers

The UART module has several registers accessible via the SBI interface:

| Register | Address | Access | Description |
|----------|---------|--------|-------------|
| `isr` | 0x0 | RW1C | Interrupt Status Register |
| `imr` | 0x1 | RW | Interrupt Mask Register |
| `data` | 0x2 | RW | Data FIFO - TX/RX data |
| `ctrl_tx` | 0x4 | RW | TX Control Register |
| `ctrl_rx` | 0x5 | RW | RX Control Register |
| `baud_tick_cnt_max_lsb` | 0x6 | RW | Baud counter LSB (if USER_DEFINE_BAUD_TICK=true) |
| `baud_tick_cnt_max_msb` | 0x7 | RW | Baud counter MSB (if USER_DEFINE_BAUD_TICK=true) |

### Control Register Fields

**ctrl_tx**:
- Bit 0: `tx_enable` - Transmission enable
- Bit 1: `tx_parity_enable` - Parity enable
- Bit 2: `tx_parity_odd` - Parity selection (0=even, 1=odd)
- Bit 3: `tx_use_loopback` - Loopback mode (RX input → TX output)
- Bit 4: `cts_enable` - CTS control enable

**ctrl_rx**:
- Bit 0: `rx_enable` - Reception enable
- Bit 1: `rx_parity_enable` - Parity enable
- Bit 2: `rx_parity_odd` - Parity selection (0=even, 1=odd)
- Bit 3: `rx_use_loopback` - Loopback mode (TX input → RX output)
- Bit 4: `rts_enable` - RTS control enable

**isr** (Bits 3:0):
- Bit 0: TX Interrupt
- Bit 1: RX Interrupt
- Bit 2: TX FIFO Full Interrupt
- Bit 3: RX FIFO Full Interrupt

**imr** (Bits 3:0):
- Mask for corresponding interrupts

---

## Component Verification

### FuseSoC Project Organization

The project uses FuseSoC for file management and simulation. The `uart.core` file at the root of the project defines:

**Available Targets:**
- `default`: Default target including RTL files and CSR generation

**Generators:**
- `gen_csr`: Automatically generates CSR registers from the `hdl/csr/UART.hjson` file using the `regtool` tool

**Dependencies:**
- `asylum:utils:pkg` - Utility package
- `asylum:system:GIC` - Interrupt controller

### CSR Register Generation

CSR registers are defined in the `hdl/csr/UART.hjson` file and are automatically generated as VHDL and C files:

**Generated Files:**
- `hdl/csr/UART_csr.vhd` - CSR registers in VHDL
- `hdl/csr/UART_csr.h` - Register definitions in C
- `hdl/csr/UART_csr_pkg.vhd` - VHDL package with types and constants

This approach enables consistent register management between firmware and HDL.

### Debugging and Validation

The module provides debug signals exported via the `debug_o` port of type `uart_debug_t` which includes:

- **uart_tx**: TX state machine state
- **uart_rx**: RX state machine state, bit counter, baud_tick_half signal

These signals can be used in simulation to validate the behavior of the module.
