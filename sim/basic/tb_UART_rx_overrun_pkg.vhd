-------------------------------------------------------------------------------
-- Title      : tb_UART_rx_overrun_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_UART_rx_overrun_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario rx_overrun of tb_UART, from reset :
--              A blocking read of data counts as one read of the RX FIFO,
--              RTS# deasserted at DEPTH_RX-2 bytes in the RX FIFO, overrun
--              of the byte received while the RX FIFO is full and a byte is
--              pending : event and interrupt, the pending byte is kept
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (from tb_uart, test 11)
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

package tb_UART_rx_overrun_pkg is

  -- A blocking read of data counts as one read of the RX FIFO, RTS# deasserted
  -- at DEPTH_RX-2 bytes in the RX FIFO, overrun of the byte received while the
  -- RX FIFO is full and a byte is pending : event and interrupt, the pending
  -- byte is kept
  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   rx       : out   std_logic  -- uart_rx_i
    ;signal   tx       : in    std_logic  -- uart_tx_o
    ;signal   rts_b    : in    std_logic  -- uart_rts_b_o
    ;signal   it       : in    std_logic  -- it_o
    );

end package tb_UART_rx_overrun_pkg;

package body tb_UART_rx_overrun_pkg is

  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   rx       : out   std_logic  -- uart_rx_i
    ;signal   tx       : in    std_logic  -- uart_tx_o
    ;signal   rts_b    : in    std_logic  -- uart_rts_b_o
    ;signal   it       : in    std_logic  -- it_o
    ) is
  begin
    -- Blocking read of data (an SBI access of several cycles, waiting for the
    -- byte in loopback) : one read of the RX FIFO level that sbi_UART tracks
    -- for RTS#
    wr(UART_CTRL_TX, CTRL_EN                 , "Enable UART TX", clk, sbi_if);
    wr(UART_CTRL_RX, CTRL_EN or CTRL_LOOPBACK, "Enable UART RX in loopback", clk, sbi_if);
    wr(UART_DATA   , x"5B"                   , "Write UART TX 0x5B", clk, sbi_if);
    chk_blocking(x"5B", "Blocking read of UART RX 0x5B (loopback)", clk, sbi_if);
    wr(UART_CTRL_TX, x"00", "Disable UART TX", clk, sbi_if);
    -- RTS# is deasserted at DEPTH_RX-2 = 14 bytes in the RX FIFO. 16 bytes
    -- fill the RX FIFO, the 17th stays pending in uart_rx_axis, the 18th is
    -- an overrun : dropped, the pending byte is not overwritten
    wr (UART_CTRL_RX, CTRL_EN or CTRL_FLOW_CTRL, "Enable UART RX with RTS", clk, sbi_if);
    wr (UART_ISR    , x"FF", "Clear isr (polling)", clk, sbi_if);
    chk(UART_ISR    , x"01", "isr : TX FIFO empty only, no RX overrun", clk, sbi_if);
    for i in 0 to C_DEPTH_RX+1 loop
      if i <= C_DEPTH_RX-3
      then
        chk_bit(rts_b, '0', "RTS# active with " & integer'image(i) & " bytes in the RX FIFO");
      else
        chk_bit(rts_b, '1', "RTS# inactive with " & integer'image(i) & " bytes received");
      end if;
      uart_send(byte(16#40#+i), C_BIT_PERIOD, rx);
    end loop;
    wait until rising_edge(clk);
    chk_bit(rts_b, '1', "RTS# inactive after the overrun");
    -- The overrun is an event recorded in isr, masked or not
    chk(UART_ISR, x"1D", "RX overrun in isr (TX FIFO empty, RX FIFO not empty and full)", clk, sbi_if);
    chk_bit(it, '0', "No interrupt while masked");
    wr(UART_IMR, x"10", "Unmask RX overrun interrupt", clk, sbi_if);
    wait until rising_edge(clk);
    chk_bit(it, '1', "RX overrun interrupt");
    -- 0x40 to 0x50 read back unchanged, 0x51 dropped
    for i in 0 to C_DEPTH_RX loop
      chk(UART_DATA, byte(16#40#+i), "UART RX 0x" & to_hstring(byte(16#40#+i)) & " after the overrun", clk, sbi_if);
    end loop;
    cycles(2, clk);
    chk_bit(rts_b, '0', "RTS# active after the RX FIFO is read");
    -- Event : cleared by writing 1, not set again (unlike a level)
    wr (UART_ISR, x"10", "Clear RX overrun interrupt", clk, sbi_if);
    chk(UART_ISR, x"0D", "RX overrun cleared (RX FIFO events kept)", clk, sbi_if);
    chk_bit(it, '0', "it_o cleared");
    wr (UART_IMR, x"00", "Mask RX overrun interrupt", clk, sbi_if);
    wr (UART_ISR, x"FF", "Clear the old events", clk, sbi_if);
    chk(UART_ISR, x"01", "isr : TX FIFO empty only", clk, sbi_if);
  end procedure;

end package body tb_UART_rx_overrun_pkg;
