-------------------------------------------------------------------------------
-- Title      : tb_UART_echo_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_UART_echo_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario echo of tb_UART, from reset :
--              Echo mode (ctrl_tx.tx_use_loopback) : received bytes sent
--              back on uart_tx_o, not stored, writes to data dropped, byte
--              with a parity error echoed or not by RX_PARITY_ERROR, CTS# =
--              internal RTS# (the CTS# pin ignored), echo blocked while
--              RTS# is inactive, masked sources recorded without interrupt
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (from tb_uart, test 15)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library bitvis_vip_sbi;
use     bitvis_vip_sbi.sbi_bfm_pkg.all;

library asylum;
use     asylum.UART_csr_pkg.all;

library work;
use     work.tb_UART_bfm_pkg.all;

package tb_UART_echo_pkg is

  -- Echo mode (ctrl_tx.tx_use_loopback) : received bytes sent back on
  -- uart_tx_o, not stored, writes to data dropped, byte with a parity error
  -- echoed or not by RX_PARITY_ERROR, CTS# = internal RTS# (the CTS# pin
  -- ignored), echo blocked while RTS# is inactive, masked sources recorded
  -- without interrupt
  procedure run
    (constant policy   : in    string     -- RX_PARITY_ERROR
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   rx       : out   std_logic  -- uart_rx_i
    ;signal   tx       : in    std_logic  -- uart_tx_o
    ;signal   cts_b    : out   std_logic  -- uart_cts_b_i
    ;signal   rts_b    : in    std_logic  -- uart_rts_b_o
    ;signal   it       : in    std_logic  -- it_o
    );

end package tb_UART_echo_pkg;

package body tb_UART_echo_pkg is

  procedure run
    (constant policy   : in    string     -- RX_PARITY_ERROR
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   rx       : out   std_logic  -- uart_rx_i
    ;signal   tx       : in    std_logic  -- uart_tx_o
    ;signal   cts_b    : out   std_logic  -- uart_cts_b_i
    ;signal   rts_b    : in    std_logic  -- uart_rts_b_o
    ;signal   it       : in    std_logic  -- it_o
    ) is
    variable v_isr     : byte_t;
  begin
    -- The received bytes are sent back on uart_tx, nothing reaches the RX
    -- FIFO, the writes to data are accepted and dropped
    wr (UART_CTRL_RX, CTRL_EN_EVEN, "Enable UART RX with even parity", clk, sbi_if);
    wr (UART_CTRL_TX, CTRL_EN_EVEN or CTRL_LOOPBACK, "Enable UART TX with even parity in echo mode", clk, sbi_if);
    wr (UART_ISR    , x"FF", "Clear isr (polling)", clk, sbi_if);
    chk(UART_ISR    , x"01", "isr : TX FIFO empty only", clk, sbi_if);
    -- Echoed frames, every bit checked
    for i in PATTERNS'range loop
      uart_send(PATTERNS(i), C_BIT_PERIOD, rx, PARITY_EVEN);
      uart_expect(PATTERNS(i), PARITY_EVEN, "Echo of 0x" & to_hstring(PATTERNS(i)), tx);
    end loop;
    chk(UART_ISR, x"01", "RX not empty never set in echo mode (RX FIFO empty)", clk, sbi_if);
    -- Writes to data : accepted (more than the TX FIFO depth, none blocks),
    -- dropped, not transmitted
    for i in 0 to C_DEPTH_TX+3 loop
      wr(UART_DATA, byte(16#E0#+i), "Write data in echo mode", clk, sbi_if);
    end loop;
    chk_idle(tx, 2 * 12 * C_BIT_PERIOD, "The bytes written to data are not transmitted in echo mode");
    chk(UART_ISR, x"01", "TX FIFO never full in echo mode", clk, sbi_if);
    -- Byte with a parity error : echoed (the transmitter computes its own
    -- parity bit) with RX_PARITY_ERROR = "keep" and "halt", not echoed
    -- with "drop". Not stored, event recorded. The good byte sent right
    -- after is echoed ; with "halt", only after the clear of isr[6]
    uart_send(x"A5", C_BIT_PERIOD, rx, PARITY_EVEN, true);
    if policy /= "drop"
    then
      uart_expect(x"A5", PARITY_EVEN, "Echo of 0xA5 with a parity error", tx);
    else
      chk_idle(tx, 2 * 12 * C_BIT_PERIOD, "No echo of 0xA5 with a parity error");
    end if;
    if policy = "halt"
    then
      uart_send(x"5A", C_BIT_PERIOD, rx, PARITY_EVEN);
      chk_idle(tx, 2 * 12 * C_BIT_PERIOD, "No echo of 0x5A while RX is halted");
    end if;
    chk(UART_ISR, x"41", "RX parity error event, RX not empty never set", clk, sbi_if);
    wr (UART_ISR, x"40", "Clear RX parity error", clk, sbi_if);
    if policy = "halt"
    then
      uart_expect(x"5A", PARITY_EVEN, "Echo of 0x5A after the clear of isr[6] (RX resumes)", tx);
      chk(UART_ISR, x"01", "RX parity error cleared", clk, sbi_if);
    else
      chk(UART_ISR, x"01", "RX parity error cleared", clk, sbi_if);
      uart_send(x"5A", C_BIT_PERIOD, rx, PARITY_EVEN);
      uart_expect(x"5A", PARITY_EVEN, "Echo of 0x5A after a parity error", tx);
    end if;
    -- cts_enable = 1 : CTS# is the internal RTS#, active with rts_enable = 0,
    -- the inactive uart_cts_b_i pin does not block the echo
    cts_b <= '1';
    wr(UART_CTRL_TX, CTRL_EN_EVEN or CTRL_LOOPBACK or CTRL_FLOW_CTRL, "Enable CTS in echo mode", clk, sbi_if);
    uart_send(x"C3", C_BIT_PERIOD, rx, PARITY_EVEN);
    uart_expect(x"C3", PARITY_EVEN, "Echo of 0xC3 with the CTS# pin inactive", tx);
    -- RTS# deasserted (14 bytes in the RX FIFO, received out of echo mode)
    -- blocks the echo, until a read of data lowers the RX FIFO level
    wr(UART_CTRL_TX, x"00", "Disable UART TX (end of echo mode)", clk, sbi_if);
    for i in 0 to C_DEPTH_RX-3 loop
      uart_send(byte(16#20#+i), C_BIT_PERIOD, rx, PARITY_EVEN);
    end loop;
    wr(UART_CTRL_RX, CTRL_EN_EVEN or CTRL_FLOW_CTRL, "Enable RTS", clk, sbi_if);
    wr(UART_CTRL_TX, CTRL_EN_EVEN or CTRL_LOOPBACK or CTRL_FLOW_CTRL, "Enable UART TX in echo mode with CTS", clk, sbi_if);
    wait until rising_edge(clk);
    chk_bit(rts_b, '1', "RTS# inactive with 14 bytes in the RX FIFO");
    uart_send(x"96", C_BIT_PERIOD, rx, PARITY_EVEN);
    chk_idle(tx, 2 * 12 * C_BIT_PERIOD, "No echo of 0x96 while RTS# (CTS#) is inactive");
    -- Writes to data while the echo is blocked : accepted and dropped too
    for i in 0 to C_DEPTH_TX+3 loop
      wr(UART_DATA, byte(16#E0#+i), "Write data while the echo is blocked", clk, sbi_if);
    end loop;
    wr (UART_ISR, x"FF", "Clear isr (polling)", clk, sbi_if);
    chk(UART_ISR, x"05", "TX FIFO empty (writes dropped), RX FIFO not empty", clk, sbi_if);
    chk(UART_DATA, x"20", "UART RX 0x20 (RX FIFO level 13)", clk, sbi_if);
    uart_expect(x"96", PARITY_EVEN, "Echo of 0x96 after RTS# (CTS#) activation", tx);
    for i in 1 to C_DEPTH_RX-3 loop
      chk(UART_DATA, byte(16#20#+i), "UART RX 0x" & to_hstring(byte(16#20#+i)) & " received out of echo mode", clk, sbi_if);
    end loop;
    cts_b <= '0';
    wr(UART_CTRL_TX, x"00", "Disable UART TX", clk, sbi_if);
    wr(UART_CTRL_RX, CTRL_EN, "Enable UART RX without parity and RTS", clk, sbi_if);
    -- The masked sources were recorded (polling) : RX not empty and TX FIFO
    -- empty, without interrupt. Clear the old events before unmasking : only
    -- the TX FIFO empty level remains
    rd(UART_ISR, v_isr, "Read isr (masked sources)", clk, sbi_if);
    chk_bit(v_isr(2), '1', "RX not empty recorded while masked");
    chk_bit(v_isr(0), '1', "TX FIFO empty recorded while masked");
    chk_bit(it, '0', "No interrupt while masked");
    wr(UART_ISR, x"FF", "Clear the old events", clk, sbi_if);
    wr(UART_IMR, x"04", "Unmask RX not empty interrupt", clk, sbi_if);
    wait until rising_edge(clk);
    chk(UART_ISR, x"01", "RX FIFO empty at the end", clk, sbi_if);
    chk_bit(it, '0', "No pending interrupt at the end");
  end procedure;

end package body tb_UART_echo_pkg;
