<!--
  README GENERATION INSTRUCTIONS (for the next regeneration run)
  ----------------------------------------------------------------
  This README follows the common Asylum IP model. Regenerate it from the
  sources, never from the previous README text alone.

  Sources of truth (in priority order):
    1. hdl/*.vhd            : entities, generics, ports, packages
    2. hdl/csr/*.hjson      : register map (regtool); *_csr.md/.h are generated
    3. <IP>.core            : VLNV (name), filesets, targets, depends, revisions
    4. mk/targets.txt       : target list shown by `make help`; mk/defs.mk
    5. sim/, syn/, esw/, boards/ : testbenches, constraints, software
  Section order (keep it, same headings in every IP):
    CI badge / Title + one-line description + VLNV / Table of Contents /
    Introduction (Key Features) / Block Diagram / Top-Level (Parameters,
    Ports, Instantiation Example) / HDL Modules / Register Map /
    Verification / Synthesis / Design Notes (optional) /
    Directory Structure / Dependencies
  Rules:
    - Language: English. Tables: Parameters = Name|Type|Default|Description,
      Ports = Name|Direction|Type|Description (grouped by interface).
    - Register Map: link to the generated hdl/csr/<X>_csr.md (plus the
      .hjson source and _csr.h header); never copy register tables here.
    - Top-Level = sbi_* wrapper if present, else the entity used by the
      `default` target, else the main entity (libraries: list packages).
    - Write "This IP has no software-visible registers." / "No dedicated
      synthesis target ..." instead of removing a section.
    - Keep still-accurate hand-written content (ISA tables, results,
      images) in "Design Notes"; drop anything not backed by the sources.
    - Block diagram: doc/<NAME>.drawio (NAME = 4th field of the VLNV),
      top entity box with generics on top, inputs left, outputs right,
      bus interfaces as bold arrows, internal blocks colour-coded
      (CSR yellow, FIFO/memory green, core logic blue, external grey).
      Update it whenever ports/generics/sub-blocks change.
    - Do not edit generated files (hdl/csr/*_csr.*) or the CI badge URL.
-->
[![CI](https://github.com/deuskane/asylum-communication-uart/actions/workflows/ci.yml/badge.svg)](https://github.com/deuskane/asylum-communication-uart/actions/workflows/ci.yml)

# asylum-communication-uart

**UART transmitter / receiver with CSR access over the SBI bus, TX / RX FIFOs, CTS / RTS flow control, loopback modes and an interrupt output.**

VLNV: `asylum:communication:uart:2.0.0`

## Table of Contents

1. [Introduction](#introduction)
2. [Block Diagram](#block-diagram)
3. [Top-Level](#top-level)
4. [HDL Modules](#hdl-modules)
5. [Register Map](#register-map)
6. [Verification](#verification)
7. [Synthesis](#synthesis)
8. [Design Notes](#design-notes)
9. [Directory Structure](#directory-structure)
10. [Dependencies](#dependencies)

## Introduction

This IP is the UART of the Asylum project. Software drives it through a small CSR bank on the SBI bus: bytes written to the `data` register go through a TX FIFO to the transmitter (`uart_tx_axis`), and bytes received by `uart_rx_axis` are pushed into an RX FIFO and read back from the same `data` register. Each direction has its own baud rate generator, enable, parity configuration and loopback option. FIFO status flags are turned into an interrupt by a `GIC_core` instance (ISR / IMR registers in the CSR bank).

### Key Features

- 8-bit frames: 1 start bit, 8 data bits LSB first, optional parity bit (even / odd), 1 stop bit (checked on reception)
- Baud rate set at elaboration from `CLOCK_FREQ` / `BAUD_RATE`, optionally software-writable through a 16-bit counter (`USER_DEFINE_BAUD_TICK = true`)
- Separate TX and RX enables (`ctrl_tx.tx_enable`, `ctrl_rx.rx_enable`), each used as the reset of its path; bytes written while TX is disabled or CTS# is inactive are kept in the TX FIFO (no silent loss)
- Configurable FIFO depths (`DEPTH_TX`, `DEPTH_RX`, 0 = no FIFO), blocking read / write on the `data` register
- Hardware flow control: CTS# (synchronized, `ctrl_tx.cts_enable`) and RTS# deasserted when the RX FIFO is almost full, at `DEPTH_RX - 2` bytes (`ctrl_rx.rts_enable`)
- RX overrun detection: a byte received while the previous one is still pending is dropped (it never overwrites it) and raises an interrupt event
- RX error detection: parity error, framing error (stop bit at 0) and break (all bits of a frame at 0) raise interrupt events; a byte with a parity error is stored in the RX FIFO (as AXI UART Lite) or dropped (`RX_STORE_PARITY_ERROR = false`); after a framing error the receiver waits for the line back to idle (a break gives one byte)
- Two loopback modes: serial loopback TX to RX (`rx_use_loopback`) and echo of received bytes on TX (`tx_use_loopback`)
- 8 interrupt sources (TX FIFO empty / full, RX FIFO not empty / full, RX overrun, framing error, parity error, break) with status and mask registers; the FIFO state is polled in `isr` (write 1 to clear, then read)
- TX or RX path can be removed at elaboration (`UART_TX_ENABLE`, `UART_RX_ENABLE`)
- Debug port with the TX / RX FSM states and the parity error flag of the last received frame
- Simulation-only dump of TX / RX bytes into raw and annotated text files

## Block Diagram

Diagram: [doc/uart.drawio](doc/uart.drawio) (open with diagrams.net or the VS Code Draw.io extension).

- The SBI bus accesses `UART_registers` (generated by regtool from [hdl/csr/UART.hjson](hdl/csr/UART.hjson)).
- The `data` register is a bidirectional `csr_fifo`: writes fill the TX FIFO, reads drain the RX FIFO.
- `uart_tx_axis` and `uart_rx_axis` exchange bytes with the FIFOs as AXI-Stream-like valid/ready channels; each one has its own `uart_baud_rate_gen` (the RX one also provides the mid-bit `baud_tick_half` used for sampling).
- `uart_cts_b_i` and `uart_rx_i` go through a `sync2dffrn` synchronizer (techmap) before reaching the transmitter / receiver (`uart_rx_i` is synchronized inverted, so that its idle level `'1'` is kept during reset).
- The FIFO empty / full / not-empty flags and the RX error pulses of `uart_rx_axis` (overrun, framing, parity, break) feed `GIC_core`, which updates the `isr` register and drives `it_o`.

## Top-Level

Top-level entity: **`sbi_UART`** ([hdl/sbi_uart.vhd](hdl/sbi_uart.vhd)), library `asylum`, component declared in `asylum.uart_pkg`.

### Parameters

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `NAME` | string | `""` | Instance name, forwarded to the CSR block (`MODULE_NAME`, visible in `sbi_tgt_o.info`) |
| `BAUD_RATE` | integer | `115200` | Baud rate (bit/s) used to compute the default baud tick counter |
| `CLOCK_FREQ` | integer | `50000000` | Frequency of `clk_i` in Hz |
| `BAUD_TICK_CNT_WIDTH` | integer | `16` | Width of the counter of `uart_baud_rate_gen`; must stay 16 because `sbi_UART` drives it with the 16-bit `baud_tick_cnt_max_msb & baud_tick_cnt_max_lsb` |
| `UART_TX_ENABLE` | boolean | `true` | `false`: no transmitter (`uart_tx_o = '1'`, bytes written to `data` are accepted and dropped) |
| `UART_RX_ENABLE` | boolean | `true` | `false`: no receiver (RX FIFO never written, `uart_rts_b_o = '0'`) |
| `USER_DEFINE_BAUD_TICK` | boolean | `true` | `true`: `baud_tick_cnt_max_lsb/msb` registers exist and are software-writable; `false`: the counter is fixed to `CLOCK_FREQ / BAUD_RATE - 1` |
| `DEPTH_TX` | natural | `0` | Depth of the TX FIFO (software to hardware, 0 = no FIFO) |
| `DEPTH_RX` | natural | `0` | Depth of the RX FIFO (hardware to software, 0 = no FIFO) |
| `RX_STORE_PARITY_ERROR` | boolean | `true` | `true`: a byte received with a parity error is stored in the RX FIFO (echoed with `tx_use_loopback = 1`); `false`: it is dropped. The parity error event (`isr` bit 6) is raised in both cases |
| `FILENAME_TX` | string | `"dump_uart_tx.txt"` | Simulation only: raw dump of transmitted bytes (annotated copy in `FILENAME_TX & ".dbg"`) |
| `FILENAME_RX` | string | `"dump_uart_rx.txt"` | Simulation only: raw dump of received bytes (annotated copy in `FILENAME_RX & ".dbg"`) |

### Ports

#### Clock & Reset

| Name | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk_i` | in | std_logic | System clock |
| `arst_b_i` | in | std_logic | Asynchronous reset, active low |

#### Bus (SBI)

| Name | Direction | Type | Description |
|------|-----------|------|-------------|
| `sbi_ini_i` | in | sbi_ini_t | SBI request from the initiator (`cs`, `re`, `we`, `addr`, `wdata`) |
| `sbi_tgt_o` | out | sbi_tgt_t | SBI response to the initiator (`ready`, `rdata`, `info`) |

#### UART

| Name | Direction | Type | Description |
|------|-----------|------|-------------|
| `uart_tx_o` | out | std_logic | Serial data output (idle high) |
| `uart_rx_i` | in | std_logic | Serial data input (idle high); synchronized by `sync2dffrn` (2 FF, idle level `'1'` during reset) |
| `uart_cts_b_i` | in | std_logic | Clear To Send, active low; synchronized by `sync2dffrn`, only used when `ctrl_tx.cts_enable = 1` |
| `uart_rts_b_o` | out | std_logic | Request To Send, active low, registered (reset value `'0'`): `'0'` when `ctrl_rx.rts_enable = 0`, else `'1'` when the RX FIFO holds `max(DEPTH_RX - 2, 1)` bytes or more (`DEPTH_RX = 0`: while a received byte is pending) |

#### Interrupts

| Name | Direction | Type | Description |
|------|-----------|------|-------------|
| `it_o` | out | std_logic | Interrupt request: OR of the `isr` bits enabled in `imr` |

#### Debug

| Name | Direction | Type | Description |
|------|-----------|------|-------------|
| `debug_o` | out | uart_debug_t | `uart_tx.state` (TX active), `uart_rx.state` (RX FSM state), `uart_rx.bit_cnt` (4 LSB of the bit counter), `uart_rx.baud_tick_half`, `uart_rx.parity_error` (parity error on the last received frame) |

### Instantiation Example

```vhdl
library asylum;
use     asylum.sbi_pkg.all;
use     asylum.uart_pkg.all;

  ins_uart : entity asylum.sbi_UART
    generic map
    ( NAME                  => "UART0"
     ,BAUD_RATE             => 115200
     ,CLOCK_FREQ            => 50000000
     ,BAUD_TICK_CNT_WIDTH   => 16
     ,UART_TX_ENABLE        => true
     ,UART_RX_ENABLE        => true
     ,USER_DEFINE_BAUD_TICK => true
     ,DEPTH_TX              => 16
     ,DEPTH_RX              => 16
     ,RX_STORE_PARITY_ERROR => true
     ,FILENAME_TX           => "dump_uart0_tx.txt"
     ,FILENAME_RX           => "dump_uart0_rx.txt"
    )
    port map
    ( clk_i        => clk
     ,arst_b_i     => arst_b
     ,sbi_ini_i    => sbi_inis(UART0_ID)  -- sbi_ini_t(addr(2 downto 0), wdata(7 downto 0))
     ,sbi_tgt_o    => sbi_tgts(UART0_ID)  -- sbi_tgt_t(rdata(7 downto 0))
     ,uart_tx_o    => uart_tx
     ,uart_rx_i    => uart_rx
     ,uart_cts_b_i => uart_cts_b
     ,uart_rts_b_o => uart_rts_b
     ,it_o         => it_uart0
     ,debug_o      => uart0_debug          -- uart_debug_t
    );
```

The CSR bank uses 3 address bits (`UART_ADDR_WIDTH = 3`) and 8-bit data (`UART_DATA_WIDTH = 8`), see `asylum.UART_csr_pkg`.

## HDL Modules

| File | Unit | Kind | Role |
|------|------|------|------|
| [hdl/uart_pkg.vhd](hdl/uart_pkg.vhd) | `uart_pkg` | package | Debug record types (`uart_tx_debug_t`, `uart_rx_debug_t`, `uart_debug_t`) and component declarations of `sbi_UART`, `uart_baud_rate_gen`, `uart_rx_axis`, `uart_tx_axis` |
| [hdl/uart_baud_rate_gen.vhd](hdl/uart_baud_rate_gen.vhd) | `uart_baud_rate_gen` | entity | Baud tick and half-baud tick generator |
| [hdl/uart_tx_axis.vhd](hdl/uart_tx_axis.vhd) | `uart_tx_axis` | entity | Transmitter with AXI-Stream-like slave input, parity generation, CTS# gating |
| [hdl/uart_rx_axis.vhd](hdl/uart_rx_axis.vhd) | `uart_rx_axis` | entity | Receiver FSM with false start bit rejection, parity check and AXI-Stream-like master output |
| [hdl/sbi_uart.vhd](hdl/sbi_uart.vhd) | `sbi_UART` | entity | Top-level: CSR + TX / RX paths + loopback / flow control muxes + `GIC_core`, simulation dumps |
| hdl/csr/UART_csr.vhd | `UART_registers` | entity | Generated CSR bank (regtool), TX / RX FIFO included |
| hdl/csr/UART_csr_pkg.vhd | `UART_csr_pkg` | package | Generated types (`UART_sw2hw_t`, `UART_hw2sw_t`), address constants and `UART_registers` component |

### uart_baud_rate_gen

#### Parameters

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `BAUD_TICK_CNT_WIDTH` | integer | `16` | Width of the down counter |

#### Ports

| Name | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk_i` | in | std_logic | System clock |
| `arst_b_i` | in | std_logic | Asynchronous reset, active low (connected to `tx_enable` / `rx_enable` in `sbi_UART`) |
| `baud_tick_en_i` | in | std_logic | Enable; the counter is loaded with `cfg_baud_tick_cnt_max_i` on its rising edge |
| `baud_tick_o` | out | std_logic | One-cycle pulse when the counter reaches 0 (every `cfg_baud_tick_cnt_max_i + 1` cycles) |
| `baud_tick_half_o` | out | std_logic | One-cycle pulse when the counter equals `cfg_baud_tick_cnt_max_i / 2` (mid-bit) |
| `cfg_baud_tick_cnt_max_i` | in | std_logic_vector(BAUD_TICK_CNT_WIDTH-1 downto 0) | Reload value of the counter |

### uart_tx_axis

#### Parameters

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `WIDTH` | natural | `8` | Data width (`sbi_UART` uses 8) |

#### Ports

| Name | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk_i` | in | std_logic | System clock |
| `arst_b_i` | in | std_logic | Asynchronous reset, active low (connected to `tx_enable`) |
| `s_axis_tdata_i` | in | std_logic_vector(WIDTH-1 downto 0) | Byte to transmit |
| `s_axis_tvalid_i` | in | std_logic | Byte valid |
| `s_axis_tready_o` | out | std_logic | Ready: high when the byte is loaded in the shift register, i.e. out of reset (`arst_b_i = 1` for at least one cycle), no frame being sent and `uart_cts_b_i = 0` |
| `uart_tx_o` | out | std_logic | Serial output (reset value `'1'`) |
| `uart_cts_b_i` | in | std_logic | A new frame only starts when `'0'` |
| `baud_tick_i` | in | std_logic | Baud tick: one bit is shifted out per tick |
| `parity_enable_i` | in | std_logic | 1: insert a parity bit before the stop bit |
| `parity_odd_i` | in | std_logic | 0: even parity, 1: odd parity |
| `debug_o` | out | uart_tx_debug_t | `state` = transmitter active |

### uart_rx_axis

#### Parameters

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `WIDTH` | natural | `8` | Data width |
| `STORE_PARITY_ERROR` | boolean | `true` | `true`: a byte with a parity error is delivered on `m_axis`; `false`: it is dropped (`err_parity_o` only). `sbi_UART` connects `RX_STORE_PARITY_ERROR` |

#### Ports

| Name | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk_i` | in | std_logic | System clock |
| `arst_b_i` | in | std_logic | Asynchronous reset, active low (connected to `rx_enable`) |
| `uart_rx_i` | in | std_logic | Serial input |
| `m_axis_tdata_o` | out | std_logic_vector(WIDTH-1 downto 0) | Received byte |
| `m_axis_tvalid_o` | out | std_logic | Received byte valid (cleared when `m_axis_tready_i = 1`) |
| `err_overrun_o` | out | std_logic | One-cycle pulse when a frame is received while the previous byte is still pending on `m_axis` (`m_axis_tvalid_o = 1` and `m_axis_tready_i = 0`): the new byte is dropped, the pending one is kept |
| `m_axis_tready_i` | in | std_logic | Byte accepted |
| `baud_tick_i` | in | std_logic | Baud tick (not used by the FSM, sampling uses `baud_tick_half_i`) |
| `baud_tick_half_i` | in | std_logic | Mid-bit sampling pulse |
| `baud_tick_en_o` | out | std_logic | Enable of the RX baud rate generator (high in START / ACTIVE) |
| `parity_enable_i` | in | std_logic | 1: a parity bit is expected after the data bits |
| `parity_odd_i` | in | std_logic | 0: even parity, 1: odd parity (sampled with `parity_enable_i` at the start of each frame) |
| `err_parity_o` | out | std_logic | One-cycle pulse at the end of a frame with a parity error; the byte is delivered, or dropped with `STORE_PARITY_ERROR = false` |
| `err_framing_o` | out | std_logic | One-cycle pulse at the end of a frame whose stop bit is sampled at 0 (the byte is still delivered); the receiver then waits for the line at 1 before a new start bit |
| `err_break_o` | out | std_logic | One-cycle pulse at the end of a frame with all its bits at 0 (start, data, parity, stop), with `err_framing_o` |
| `parity_error_o` | out | std_logic | Parity status of the last received frame, updated at the end of each frame (0: parity ok or disabled, 1: parity error) |
| `debug_o` | out | uart_rx_debug_t | FSM state, bit counter, `baud_tick_half`, `parity_error` |

## Register Map

The register map is generated by regtool from [hdl/csr/UART.hjson](hdl/csr/UART.hjson):

- Register documentation: **[hdl/csr/UART_csr.md](hdl/csr/UART_csr.md)**
- C header: [hdl/csr/UART_csr.h](hdl/csr/UART_csr.h)

Notes:

- `data` is a FIFO register with blocking read / write: writes go to the TX FIFO (`DEPTH_TX`), reads come from the RX FIFO (`DEPTH_RX`).
- `baud_tick_cnt_max_lsb` / `baud_tick_cnt_max_msb` only exist when `USER_DEFINE_BAUD_TICK = true`; their reset value is `CLOCK_FREQ / BAUD_RATE - 1` (computed in `sbi_UART`). The value must be written as `f_clk / baud - 1`. Write it at setup time, with `ctrl_tx.tx_enable = 0` and `ctrl_rx.rx_enable = 0`: these bits are the reset of the TX / RX baud rate generators and state machines, so the intermediate value `{old MSB, new LSB}` between the two writes is never used. Changing the baud rate while TX or RX is enabled is not supported.
- The meaning of the 8 `isr` / `imr` bits is set by `sbi_UART`: bit 0 = TX FIFO empty (`DEPTH_TX = 0`: the transmitter can accept a byte; up to version 2.0.0 this bit was TX FIFO not empty), bit 1 = TX FIFO full, bit 2 = RX FIFO not empty, bit 3 = RX FIFO full, bit 4 = RX overrun (a received byte was dropped: RX FIFO full, or `DEPTH_RX = 0` and the previous byte not read yet), bit 5 = RX framing error (stop bit at 0), bit 6 = RX parity error (the byte is stored, or dropped with `RX_STORE_PARITY_ERROR = false`), bit 7 = RX break (all bits of a frame at 0, with a framing error).
- `isr` has one read wait state (`rd_wait_state: 1`, a read lasts 2 cycles), so that the FIFO state can be polled in `isr`, see [Interrupts](#interrupts).

## Verification

### Testbenches

| File | DUT | Description |
|------|-----|-------------|
| [sim/tb_uart.vhd](sim/tb_uart.vhd) | `sbi_UART` | UVVM testbench with the SBI VIP (`bitvis_vip_sbi`), 50 MHz / 115200 baud, `DEPTH_TX = DEPTH_RX = 16`, generic `RX_STORE_PARITY_ERROR` forwarded to the DUT, self-checking (647 checks with `RX_STORE_PARITY_ERROR = true`, 648 with `false`). (1-3) RX through a UART BFM on `uart_rx_i` at nominal rate and with a +/-3 % bit period; (4) 1/4-bit glitch rejected, the RX-not-empty event of tests 1-3 and the TX FIFO empty level recorded while masked, the RX-not-empty event cleared before unmasking, then RX-not-empty interrupt (`imr`/`isr`/`it_o`, rw1c clear); (5) RX with even and odd parity: 8 patterns (data bit 0 at 0 and 1) read from `data`, `debug_o.uart_rx.parity_error` checked for correct and corrupted parity bits, a byte with a corrupted parity read back (`RX_STORE_PARITY_ERROR = true`) or dropped (`false`: parity error event in `isr`, RX FIFO empty: `isr` bit 2 cleared then read at 0), the good byte sent right after received, back to no parity; (6) TX without / with even / with odd parity: every bit of the frame on `uart_tx_o` (start, data, parity, stop) checked by a UART monitor, back-to-back frames; (7) internal serial loopback (`rx_use_loopback`) without / with even / with odd parity: frame on the pin and byte read back; (8) loopback with a TX/RX parity mismatch sets the parity error flag, the byte read back or dropped as in 5; (10) bytes written while TX is disabled or while CTS# is inactive are not sent, then sent after TX enable / CTS# activation; (11) blocking read of `data` waiting for a byte in serial loopback, RTS# deasserted at 14 bytes in the RX FIFO, 18 bytes received without reading: the 17 first bytes are read back unchanged, the 18th is dropped and sets the RX overrun event in `isr` (recorded while masked, interrupt when unmasked, rw1c clear), RTS# active again after the FIFO is read; (12) stop bit at 0: framing error event, byte delivered; break of 25 bit periods: one 0x00 byte with framing error and break events, receiver back on the next frame; parity error event and interrupt (`imr`), the byte stored and read back (`true`) or dropped, RX not empty never set (`false`), the good byte sent right after received, no event with a good parity; (13) polling of the FIFO state in `isr`, written 1 to clear then read in the next SBI access (TX FIFO empty, neither empty nor full, full), TX FIFO empty interrupt raised when the last byte leaves the TX FIFO, kept by a clear while the TX FIFO is empty, dropped by `imr`; (14) RTS# (registered) active with an empty RX FIFO, inactive with a full RX FIFO, forced active by `rts_enable = 0`, active again after the FIFO is read; (15) echo mode (`tx_use_loopback`): 8 received bytes echoed on `uart_tx_o` and checked bit by bit, RX not empty never set, 20 writes to `data` accepted without blocking and not transmitted, a byte with a parity error echoed (`true`) or not (`false`) with its parity error event, the next good byte echoed, with `cts_enable = 1` the echo ignores the inactive CTS# pin and is held by the internal RTS# (14 bytes in the RX FIFO) until a read of `data`; at the end the RX not-empty event and the TX FIFO empty level of the masked sources are recorded in `isr` without interrupt |

### Targets

| Target | Toplevel | Description |
|--------|----------|-------------|
| `default` | `sbi_UART` | RTL fileset + CSR generation (not a simulation) |
| `sim_basic` | `tb_uart` | Simulation of basic unit tests (GHDL) |
| `sim_rx_parity_drop` | `tb_uart` | Same scenario with `RX_STORE_PARITY_ERROR=false` (generic set at run time): the bytes received with a parity error are checked dropped |
| `lint_ghdl` | `asylum.sbi_UART_wrapper` | Lint: GHDL `-Wall` analysis and elaboration (empty simulation) of `sbi_UART` in a wrapper with flat SBI ports (`syn/sbi_UART_wrapper.vhd`) |
| `lint_ghdl_synth_default` | `asylum.sbi_UART_wrapper` | Synthesis check (see below), default generics (PicoSoC) |
| `lint_ghdl_synth_fifo16` | `asylum.sbi_UART_wrapper` | Synthesis check, FIFO depths 16 (tb_uart): `DEPTH_TX=16`, `DEPTH_RX=16` |
| `lint_ghdl_synth_tx_only` | `asylum.sbi_UART_wrapper` | Synthesis check, TX only: `UART_RX_ENABLE=false`, `DEPTH_TX=4` |
| `lint_ghdl_synth_rx_only` | `asylum.sbi_UART_wrapper` | Synthesis check, RX only: `UART_TX_ENABLE=false`, `DEPTH_RX=4` |
| `lint_ghdl_synth_fixed_baud` | `asylum.sbi_UART_wrapper` | Synthesis check, fixed baud tick: `USER_DEFINE_BAUD_TICK=false` |
| `lint_ghdl_synth_parity_drop` | `asylum.sbi_UART_wrapper` | Synthesis check, bytes with a parity error dropped: `RX_STORE_PARITY_ERROR=false` |

A `lint_ghdl_synth_*` target is `lint_ghdl` with the generics of its configuration (FuseSoC `parameters`) and a `pre_run` hook, `ghdl_synth.sh` of `asylum:utils:ghdl_synth`, which adds `include ghdl_synth.mk` to the Makefile generated by edalize. The run step (`make run EXTRA_OPTIONS=<generics>`) then runs, in the build directory:

1. `ghdl --synth` of the toplevel (rule `ghdl_synth` of `ghdl_synth.mk`), with the options of the target: `STD`, `ANALYZE_OPTIONS` (`-Wall`), `TOPLEVEL_LIBS`, `TOPLEVEL` and the generics. It writes `sbi_UART_wrapper_synth.vhd` (netlist) and `sbi_UART_wrapper_synth.log`, prints the warnings, and fails on a synthesis error (an inferred latch is one);
2. `ghdl -r --no-run`: elaboration with the same generics, without simulation.

To add a configuration, add a target with its `parameters` (the generics are declared in the `parameters` section of `uart.core`).

### How to Run

The default tool is GHDL (`mk/defs.mk`: `TOOL ?= ghdl`, `TARGET ?= sim_basic`).

```bash
make help                 # variables, rules and target list (mk/targets.txt)
make sim_basic            # run one target (log in log/)
make nonreg_sim           # run every sim_* target
make lint_ghdl            # GHDL -Wall lint (make nonreg_lint: every lint_* target)
make lint_ghdl_synth_default   # GHDL -Wall lint + ghdl --synth -Wall check of one configuration
make clean                # remove build/ and log/
```

Equivalent FuseSoC command:

```bash
fusesoc --cores-root . run --build-root build --target sim_basic asylum:communication:uart:2.0.0
```

The `sim_basic` target runs GHDL with `--fst=dut.fst --ieee-asserts=disable`. CI ([.github/workflows/ci.yml](.github/workflows/ci.yml)) runs `sim_basic` and `sim_rx_parity_drop`.

### Simulation Features

- `sbi_UART` writes every transmitted / received byte to `FILENAME_TX` / `FILENAME_RX` (raw characters) and to `<FILENAME>.dbg` (binary, hexadecimal and character per line); code inside `synthesis translate_off`.
- At elaboration `sbi_UART` reports `CLOCK_FREQ`, `BAUD_RATE` and the computed baud tick counter values.
- `ctrl_rx.rx_use_loopback = 1` loops `uart_tx` back to the receiver for tests without an external device.

## Synthesis

No vendor synthesis target (the `lint_ghdl_synth_*` targets check the RTL with `ghdl --synth`, see [Targets](#targets)). The HDL sources of the `default` target (`hdl/*.vhd` + generated CSR) are synthesizable: the file dumps and reports of `sbi_UART` are enclosed in `synthesis translate_off / translate_on` (only the `textio` `use` clauses remain outside). Resource usage mainly depends on `DEPTH_TX` / `DEPTH_RX` (FIFOs in the CSR bank), `UART_TX_ENABLE` / `UART_RX_ENABLE` and `USER_DEFINE_BAUD_TICK`. The asynchronous inputs `uart_rx_i` and `uart_cts_b_i` are synchronized inside the IP (`sync2dffrn`), they can be connected directly to pads.

## Design Notes

### Baud Rate

`baud_tick_cnt_max = CLOCK_FREQ / BAUD_RATE - 1` (integer division). Each `uart_baud_rate_gen` emits one `baud_tick` every `baud_tick_cnt_max + 1` clock cycles and a `baud_tick_half` when the counter is at `baud_tick_cnt_max / 2`. Example: 50 MHz and 115200 baud give `baud_tick_cnt_max = 433` (actual rate 115207 baud).

### Transmitter

A byte is accepted (`s_axis_tvalid_i = 1` and `s_axis_tready_o = 1`) only when it is loaded in the shift register: transmitter enabled, idle and CTS# low. While `ctrl_tx.tx_enable = 0` (reset of the transmitter) or CTS# is high, `s_axis_tready_o = 0`: the bytes stay in the TX FIFO, and with `DEPTH_TX = 0` a write to `data` is blocked until the byte is accepted (enable TX before writing). The frame `start + 8 data bits (LSB first) + [parity] + stop` is shifted out, one bit per `baud_tick`. With `ctrl_tx.cts_enable = 0` CTS# is forced low (always clear to send).

### Receiver FSM

- **IDLE**: waits for `uart_rx_i = 0` (start bit). In `sbi_UART` the receiver input is the synchronized `uart_rx_i` (2 clock cycles of latency) or `uart_tx` in serial loopback.
- **START**: enables the RX baud generator and samples the start bit at mid-bit; a `'1'` is a false start (glitch) and goes back to IDLE.
- **ACTIVE**: samples one bit per `baud_tick_half` until all bits are received.
- **STOP**: extracts the data byte and the parity bit, checks the parity and the stop bit (`err_parity_o`, `err_framing_o`, `err_break_o`), asserts `m_axis_tvalid_o` (not for a byte with a parity error when `STORE_PARITY_ERROR = false`: it is dropped), back to IDLE. After a framing error, IDLE waits for `uart_rx_i = 1` before looking for a start bit, so a line held at 0 (break) gives one byte. If the previous byte is still pending (`m_axis_tvalid_o = 1`, `m_axis_tready_i = 0`), the new byte is dropped and `err_overrun_o` pulses (overrun).

The frame is shifted into a `WIDTH+3`-bit register (10 samples without parity, 11 with parity) and the data bits are extracted at the position that matches the parity configuration sampled at the start of the frame. With `rx_parity_enable = 1` the received parity bit is checked (even: `xor(data, parity) = 0`, odd: `xor(data, parity) = 1`); the result is available on `parity_error_o` of `uart_rx_axis` and on `debug_o.uart_rx.parity_error` of `sbi_UART` (status of the last received frame). With `RX_STORE_PARITY_ERROR = true` (default, as AXI UART Lite), a byte with a parity error is pushed into the RX FIFO; the parity error event (`isr` bit 6) tells that an error occurred, but not which byte of the RX FIFO had it. With `RX_STORE_PARITY_ERROR = false`, the byte is dropped (not pushed into the RX FIFO, not echoed with `ctrl_tx.tx_use_loopback = 1`), and the event is still raised. A byte with a framing error or a break is pushed into the RX FIFO (unless it also has a parity error and `RX_STORE_PARITY_ERROR = false`, e.g. a break with odd parity), reported by the framing error and break events (`isr` bits 5 and 7). An overrun keeps its priority: a frame received while a byte is pending is dropped with an overrun event (and its parity error event if any).

### Loopback and Flow Control

- `ctrl_rx.rx_use_loopback = 1`: the receiver input is `uart_tx` instead of `uart_rx_i` (serial loopback).
- `ctrl_tx.tx_use_loopback = 1`: received bytes are sent directly to the transmitter (echo; a byte with a parity error is echoed, or dropped with `RX_STORE_PARITY_ERROR = false`); the `data` register then always accepts writes and drops them (not transmitted), and no received byte reaches the RX FIFO. In this mode, with `cts_enable = 1`, CTS# is taken from the internal RTS# (the `uart_cts_b_i` pin is ignored): with `rts_enable = 1`, the echo stops while the RX FIFO holds `DEPTH_RX - 2` bytes or more (bytes received before the echo mode).
- `ctrl_rx.rts_enable = 1`: `uart_rts_b_o` goes high when the RX FIFO holds `DEPTH_RX - 2` bytes or more (at least 1, constant `RX_RTS_MARGIN = 2` in `sbi_UART`), so that the remote transmitter can still send 2 bytes, plus 1 byte pending in `uart_rx_axis`, after RTS# deassertion without overrun. `csr_fifo` exports neither its number of elements nor its pop: `sbi_UART` tracks the RX FIFO level from the push (`uart_rx_axis` handshake) and the pop (SBI read of `data` while the RX FIFO is not empty: the cycle where the access completes, one pop per read even for a blocking read lasting several cycles). With `DEPTH_RX = 0`, RTS# goes high while a received byte is pending. RTS# comes from a flip-flop (one cycle after the level comparison), so the pad does not see its glitches.

### Interrupts

`GIC_core` (`asylum:system:GIC` >= 2.0.0) computes `isr_next = status or isr` every cycle, whatever `imr`, and `it_o = or(isr and imr)`: the masked sources are latched too (they can be polled) and `imr` only masks `it_o`. Software clears the events by writing 1 into `isr` (rw1c), and clears the old events it wants to ignore before unmasking a source (e.g. the RX not-empty event of bytes already read).

Bits 3:0 are levels: bit 0 TX FIFO empty, bit 1 TX FIFO full, bit 2 RX FIFO not empty, bit 3 RX FIFO full. Bits 7:4 are events: bit 4 RX overrun, bit 5 RX framing error, bit 6 RX parity error, bit 7 RX break, one-cycle pulses of `uart_rx_axis`, kept in `isr` until software writes 1 to them (`GIC_core` records them, masked or not: no sticky flags in `sbi_UART`). TX FIFO empty rises when the last byte of the TX FIFO is loaded into the transmitter, while this byte is still being sent: an interrupt-driven TX driver writes its next bytes, and masks bit 0 in `imr` when it has nothing more to send (clearing the bit has no effect while the TX FIFO is empty).

Polling of the FIFO state: there is no status register, software reads the level sources in `isr`. It writes 1 to the bits 3:0 to clear them (and only them: a write of 1 to an event bit can clear an event not seen yet), then reads `isr`: the bit of a source still active is set again. `isr` is a `csr_reg` `rw1c` written by the hardware every cycle, and the software clear wins in the cycle of the write, so the bit comes back one cycle after the clear. The read wait state of `isr` (`rd_wait_state: 1`, `asylum:utils:generators` >= 2.10.0) returns the value of the second cycle of the read: a read issued right after the clear (back-to-back accesses) sees the bit set again.

```c
PORT_WR(UART, UART_ISR, 0x0F);   // clear the FIFO state bits (3:0)
isr = PORT_RD(UART, UART_ISR);   // the bits of the active sources are set again
if (isr & 0x02) { /* TX FIFO full : do not write data */ }
```

## Directory Structure

```
asylum-communication-uart/
├── uart.core               # FuseSoC core (asylum:communication:uart)
├── Makefile                # Common Asylum Makefile (FuseSoC wrapper)
├── mk/
│   ├── defs.mk             # FILE_CORE, default TARGET and TOOL
│   └── targets.txt         # Target list (generated from the .core)
├── .github/workflows/
│   └── ci.yml              # CI jobs (generated by make ci_generate)
├── doc/
│   └── uart.drawio         # Block diagram
├── hdl/
│   ├── uart_pkg.vhd
│   ├── uart_baud_rate_gen.vhd
│   ├── uart_rx_axis.vhd
│   ├── uart_tx_axis.vhd
│   ├── sbi_uart.vhd
│   └── csr/
│       ├── UART.hjson       # Register description (source)
│       ├── UART_csr.vhd     # Generated
│       ├── UART_csr_pkg.vhd # Generated
│       ├── UART_csr.md      # Generated
│       └── UART_csr.h       # Generated
├── sim/
│   └── tb_uart.vhd         # UVVM testbench
└── syn/
    └── sbi_UART_wrapper.vhd    # Lint / synthesis check wrapper (sbi_UART, flat SBI ports)
```

## Dependencies

| Core | Used by (fileset) | Purpose |
|------|-------------------|---------|
| `asylum:utils:pkg` | `rtl` | Common packages (`sbi_pkg`, `math_pkg`, `convert_pkg`, ...) |
| `asylum:component:fifo` | `rtl` | FIFO used by the `csr_fifo` of the `data` register |
| `asylum:system:GIC` (`>=2.0.0`) | `rtl` | `GIC_core` (interrupt status / mask / merge; raw `isr`, `imr` masks `it_o`) |
| `asylum:target:techmap` | `rtl` | `sync2dffrn` synchronizers of `uart_rx_i` and `uart_cts_b_i` (`techmap_pkg`) |
| `asylum:utils:generators` (`>=2.10.0`) | `rtl` | regtool generator (`gen_csr`) and CSR building blocks (read wait state of `isr`) |
| `asylum:utils:ghdl_synth` | `syn` | `ghdl_synth.sh` / `ghdl_synth.mk` (`pre_run` hook of `lint_ghdl_synth_*`) |
| `bitvis:verification:uvvm` | `sim_basic` | UVVM utility library and SBI VIP |
