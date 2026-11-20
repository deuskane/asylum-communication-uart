-------------------------------------------------------------------------------
-- Title      : tb_UART_rx_pending_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_UART_rx_pending_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario rx_pending of tb_UART, from reset :
--              Internal loopback, RX FIFO full and one byte waiting in the
--              receiver : a read of data during the next frame lets the
--              waiting byte in the RX FIFO, then the next byte waits, no
--              overrun, no duplicate, order kept
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created
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

package tb_UART_rx_pending_pkg is

  -- Internal loopback, RX FIFO full and one byte waiting in the receiver : a
  -- read of data during the next frame lets the waiting byte in the RX FIFO,
  -- then the next byte waits, no overrun, no duplicate, order kept
  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    );

end package tb_UART_rx_pending_pkg;

package body tb_UART_rx_pending_pkg is

  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ) is
  begin
    wr(UART_CTRL_TX, CTRL_EN                 , "Enable UART TX", clk, sbi_if);
    wr(UART_CTRL_RX, CTRL_EN or CTRL_LOOPBACK, "Enable UART RX in loopback", clk, sbi_if);
    -- Back to back frames of 10 bits : 0x40 to 0x4F fill the RX FIFO, 0x50
    -- waits in the receiver, 0x51 (written when the TX FIFO has room) is
    -- the 18th frame
    for i in 0 to C_DEPTH_TX loop
      wr(UART_DATA, byte(16#40#+i), "Write UART TX", clk, sbi_if);
    end loop;
    wait for 12 * C_BIT_PERIOD;
    wr(UART_DATA, byte(16#40#+C_DEPTH_TX+1), "Write UART TX", clk, sbi_if);
    -- Read during the 18th frame : 0x50 enters the RX FIFO
    wait for (17 * 10 + 5 - 12) * C_BIT_PERIOD;
    chk(UART_DATA, x"40", "UART RX 0x40 during the 18th frame", clk, sbi_if);
    -- End of the 18th frame : 0x51 waits for room, no overrun
    wait for 10 * C_BIT_PERIOD;
    chk(UART_ISR, x"0F", "No RX overrun (TX FIFO empty, full recorded, RX FIFO not empty and full)", clk, sbi_if);
    for i in 1 to C_DEPTH_RX+1 loop
      chk(UART_DATA, byte(16#40#+i), "UART RX 0x" & to_hstring(byte(16#40#+i)) & " in order, no duplicate", clk, sbi_if);
    end loop;
    wr (UART_ISR, x"0F", "Clear the FIFO state bits (polling)", clk, sbi_if);
    chk(UART_ISR, x"01", "RX FIFO empty", clk, sbi_if);
  end procedure;

end package body tb_UART_rx_pending_pkg;
