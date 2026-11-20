-------------------------------------------------------------------------------
-- Title      : tb_UART_rx_errors_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_UART_rx_errors_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario rx_errors of tb_UART, from reset :
--              Framing error (stop bit at 0, byte delivered), break (one
--              0x00 byte, then wait for the line at 1), parity error event
--              and interrupt (byte kept, dropped or RX halted by
--              RX_PARITY_ERROR), no event with a good parity
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (from tb_uart, test 12)
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

package tb_UART_rx_errors_pkg is

  -- Framing error (stop bit at 0, byte delivered), break (one 0x00 byte, then
  -- wait for the line at 1), parity error event and interrupt (byte kept,
  -- dropped or RX halted by RX_PARITY_ERROR), no event with a good parity
  procedure run
    (constant policy   : in    string     -- RX_PARITY_ERROR
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   rx       : out   std_logic  -- uart_rx_i
    ;signal   it       : in    std_logic  -- it_o
    ;signal   par_err  : in    std_logic  -- debug_o.uart_rx.parity_error
    );

end package tb_UART_rx_errors_pkg;

package body tb_UART_rx_errors_pkg is

  procedure run
    (constant policy   : in    string     -- RX_PARITY_ERROR
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   rx       : out   std_logic  -- uart_rx_i
    ;signal   it       : in    std_logic  -- it_o
    ;signal   par_err  : in    std_logic  -- debug_o.uart_rx.parity_error
    ) is
  begin
    wr (UART_CTRL_RX, CTRL_EN, "Enable UART RX without parity", clk, sbi_if);
    wr (UART_ISR    , x"FF", "Clear isr (polling)", clk, sbi_if);
    chk(UART_ISR    , x"01", "isr : TX FIFO empty only, no RX error", clk, sbi_if);
    -- Stop bit at 0 : framing error, the byte is still delivered
    uart_send(x"A5", C_BIT_PERIOD, rx, PARITY_NONE, false, '0');
    rx <= '1';
    wait for 2 * C_BIT_PERIOD;
    chk(UART_ISR , x"25", "RX framing error in isr (TX FIFO empty, RX FIFO not empty)", clk, sbi_if);
    chk(UART_DATA, x"A5", "UART RX 0xA5 with a framing error", clk, sbi_if);
    wr (UART_ISR , x"24", "Clear RX framing error and RX not empty", clk, sbi_if);
    chk(UART_ISR , x"01", "RX framing error cleared", clk, sbi_if);
    -- Break (line at 0 during 25 bit periods) : one 0x00 byte with a framing
    -- error and a break, then the receiver waits for the line back to 1
    rx <= '0';
    wait for 25 * C_BIT_PERIOD;
    rx <= '1';
    wait for 2 * C_BIT_PERIOD;
    chk(UART_ISR , x"A5", "RX break and framing error in isr", clk, sbi_if);
    chk(UART_DATA, x"00", "UART RX 0x00 of the break", clk, sbi_if);
    wr (UART_ISR , x"A4", "Clear RX break, framing error and RX not empty", clk, sbi_if);
    chk(UART_ISR , x"01", "Only one byte received during the break (RX FIFO empty)", clk, sbi_if);
    uart_send(x"3C", C_BIT_PERIOD, rx);
    chk(UART_DATA, x"3C", "UART RX 0x3C after the break", clk, sbi_if);
    wr (UART_ISR , x"04", "Clear RX not empty", clk, sbi_if);
    chk(UART_ISR , x"01", "No RX error after the break", clk, sbi_if);
    -- Parity error : event and interrupt. The byte is stored (read back), or
    -- dropped with RX_PARITY_ERROR = "drop" (RX not empty never set). With
    -- "halt", the clear of isr[6] resumes RX
    wr(UART_CTRL_RX, CTRL_EN_EVEN, "Enable UART RX with even parity", clk, sbi_if);
    wr(UART_IMR    , x"E0", "Unmask RX error interrupts", clk, sbi_if);
    uart_send(x"A5", C_BIT_PERIOD, rx, PARITY_EVEN, true);
    wait until rising_edge(clk);
    chk_bit(par_err, '1', "RX parity error flag for 0xA5");
    chk_bit(it     , '1', "RX parity error interrupt");
    if policy /= "drop"
    then
      chk(UART_ISR , x"45", "RX parity error in isr, byte stored (RX not empty)", clk, sbi_if);
      chk(UART_DATA, x"A5", "UART RX 0xA5 with a parity error (stored)", clk, sbi_if);
    else
      chk(UART_ISR , x"41", "RX parity error in isr, RX not empty never set (byte dropped)", clk, sbi_if);
    end if;
    wr (UART_ISR, x"44", "Clear RX parity error and RX not empty", clk, sbi_if);
    chk(UART_ISR, x"01", "RX parity error cleared", clk, sbi_if);
    chk_bit(it, '0', "it_o cleared");
    test_rx(x"5A", PARITY_EVEN, false, policy, clk, sbi_if, rx, par_err);
    chk(UART_ISR, x"05", "No RX error with a good parity", clk, sbi_if);
    chk_bit(it, '0', "No interrupt with a good parity");
    wr (UART_IMR, x"00", "Mask RX error interrupts", clk, sbi_if);
    wr (UART_ISR, x"FF", "Clear the old events", clk, sbi_if);
    chk(UART_ISR, x"01", "isr : TX FIFO empty only", clk, sbi_if);
  end procedure;

end package body tb_UART_rx_errors_pkg;
