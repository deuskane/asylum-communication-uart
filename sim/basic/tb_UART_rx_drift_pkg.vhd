-------------------------------------------------------------------------------
-- Title      : tb_UART_rx_drift_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_UART_rx_drift_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario rx_drift of tb_UART, from reset :
--              Reception with a bit period 3 % longer, then 3 % shorter
--              than the bit period of the DUT
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (from tb_uart, tests 2 and 3)
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

package tb_UART_rx_drift_pkg is

  -- Reception with a bit period 3 % longer, then 3 % shorter than the bit
  -- period of the DUT
  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   rx       : out   std_logic  -- uart_rx_i
    );

end package tb_UART_rx_drift_pkg;

package body tb_UART_rx_drift_pkg is

  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   rx       : out   std_logic  -- uart_rx_i
    ) is
  begin
    wr(UART_CTRL_RX, CTRL_EN, "Enable UART RX", clk, sbi_if);
    uart_send(x"55", C_BIT_PERIOD * 1.03, rx);
    wait for 15 * C_BIT_PERIOD;
    chk(UART_DATA, x"55", "UART RX with a bit period +3 %", clk, sbi_if);
    uart_send(x"3C", C_BIT_PERIOD * 0.97, rx);
    wait for 15 * C_BIT_PERIOD;
    chk(UART_DATA, x"3C", "UART RX with a bit period -3 %", clk, sbi_if);
  end procedure;

end package body tb_UART_rx_drift_pkg;
