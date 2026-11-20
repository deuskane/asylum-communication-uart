-------------------------------------------------------------------------------
-- Title      : tb_UART_rx_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_UART_rx_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario rx of tb_UART, from reset :
--              Reception without parity at 115200 baud : one byte read
--              after the frame, then every pattern, parity error flag at 0
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (from tb_uart, test 1)
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

package tb_UART_rx_pkg is

  -- Reception without parity at 115200 baud : one byte read after the frame,
  -- then every pattern, parity error flag at 0
  procedure run
    (constant policy   : in    string     -- RX_PARITY_ERROR
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   rx       : out   std_logic  -- uart_rx_i
    ;signal   par_err  : in    std_logic  -- debug_o.uart_rx.parity_error
    );

end package tb_UART_rx_pkg;

package body tb_UART_rx_pkg is

  procedure run
    (constant policy   : in    string     -- RX_PARITY_ERROR
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   rx       : out   std_logic  -- uart_rx_i
    ;signal   par_err  : in    std_logic  -- debug_o.uart_rx.parity_error
    ) is
  begin
    wr(UART_CTRL_RX, CTRL_EN, "Enable UART RX", clk, sbi_if);
    uart_send(x"A5", C_BIT_PERIOD, rx);
    wait for 15 * C_BIT_PERIOD;
    chk(UART_DATA, x"A5", "UART RX nominal", clk, sbi_if);
    for i in PATTERNS'range loop
      test_rx(PATTERNS(i), PARITY_NONE, false, policy, clk, sbi_if, rx, par_err);
    end loop;
  end procedure;

end package body tb_UART_rx_pkg;
