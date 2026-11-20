-------------------------------------------------------------------------------
-- Title      : tb_UART_rx_glitch_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_UART_rx_glitch_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario rx_glitch of tb_UART, from reset :
--              A byte received while masked is recorded in isr without
--              interrupt, a glitch shorter than half a bit is not a start
--              bit, RX FIFO not empty interrupt (it_o) on the next byte,
--              cleared by masking and clearing isr
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (from tb_uart, test 4)
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

package tb_UART_rx_glitch_pkg is

  -- A byte received while masked is recorded in isr without interrupt, a
  -- glitch shorter than half a bit is not a start bit, RX FIFO not empty
  -- interrupt (it_o) on the next byte, cleared by masking and clearing isr
  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   rx       : out   std_logic  -- uart_rx_i
    ;signal   it       : in    std_logic  -- it_o
    );

end package tb_UART_rx_glitch_pkg;

package body tb_UART_rx_glitch_pkg is

  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   rx       : out   std_logic  -- uart_rx_i
    ;signal   it       : in    std_logic  -- it_o
    ) is
  begin
    wr(UART_CTRL_RX, CTRL_EN, "Enable UART RX", clk, sbi_if);
    -- isr records the sources masked by imr (polling), it_o stays at 0
    uart_send(x"A5", C_BIT_PERIOD, rx);
    wait until rising_edge(clk);
    chk(UART_ISR, x"05", "isr : RX FIFO not empty and TX FIFO empty recorded while masked", clk, sbi_if);
    chk_bit(it, '0', "No interrupt while masked");
    chk(UART_DATA, x"A5", "UART RX 0xA5", clk, sbi_if);
    wr(UART_ISR, x"04", "Clear the old RX not empty event", clk, sbi_if);
    wr(UART_IMR, x"04", "Unmask RX not empty interrupt", clk, sbi_if);
    -- Glitch shorter than half a bit period : not a start bit
    rx <= '0';
    wait for C_BIT_PERIOD / 4;
    rx <= '1';
    wait for 10 * C_BIT_PERIOD;
    wait until rising_edge(clk);
    chk(UART_ISR, x"01", "RX FIFO still empty after the glitch", clk, sbi_if);
    chk_bit(it, '0', "No interrupt after the glitch");
    uart_send(x"C6", C_BIT_PERIOD, rx);
    cycles(2, clk);
    chk(UART_ISR, x"05", "RX not empty interrupt", clk, sbi_if);
    chk_bit(it, '1', "it_o after the reception");
    chk(UART_DATA, x"C6", "UART RX after the glitch", clk, sbi_if);
    wr(UART_IMR, x"00", "Mask RX not empty interrupt", clk, sbi_if);
    wr(UART_ISR, x"04", "Clear RX not empty interrupt", clk, sbi_if);
    chk(UART_ISR, x"01", "Interrupt cleared", clk, sbi_if);
    chk_bit(it, '0', "it_o cleared");
  end procedure;

end package body tb_UART_rx_glitch_pkg;
