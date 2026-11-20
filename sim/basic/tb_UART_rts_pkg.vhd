-------------------------------------------------------------------------------
-- Title      : tb_UART_rts_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_UART_rts_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario rts of tb_UART, from reset :
--              RTS# (registered output) inactive with a full RX FIFO,
--              forced active while rts_enable = 0, active again once the RX
--              FIFO is read
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (from tb_uart, test 14)
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

package tb_UART_rts_pkg is

  -- RTS# (registered output) inactive with a full RX FIFO, forced active while
  -- rts_enable = 0, active again once the RX FIFO is read
  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   rx       : out   std_logic  -- uart_rx_i
    ;signal   rts_b    : in    std_logic  -- uart_rts_b_o
    );

end package tb_UART_rts_pkg;

package body tb_UART_rts_pkg is

  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   rx       : out   std_logic  -- uart_rx_i
    ;signal   rts_b    : in    std_logic  -- uart_rts_b_o
    ) is
  begin
    wr(UART_CTRL_RX, CTRL_EN or CTRL_FLOW_CTRL, "Enable UART RX with RTS", clk, sbi_if);
    cycles(2, clk);
    chk_bit(rts_b, '0', "RTS# active with an empty RX FIFO");
    for i in 0 to C_DEPTH_RX-1 loop
      uart_send(byte(16#70#+i), C_BIT_PERIOD, rx);
    end loop;
    wait until rising_edge(clk);
    chk_bit(rts_b, '1', "RTS# inactive with a full RX FIFO");
    wr(UART_CTRL_RX, CTRL_EN, "Disable RTS", clk, sbi_if);
    cycles(2, clk);
    chk_bit(rts_b, '0', "RTS# forced active when rts_enable = 0");
    wr(UART_CTRL_RX, CTRL_EN or CTRL_FLOW_CTRL, "Enable RTS", clk, sbi_if);
    cycles(2, clk);
    chk_bit(rts_b, '1', "RTS# inactive again with a full RX FIFO");
    for i in 0 to C_DEPTH_RX-1 loop
      chk(UART_DATA, byte(16#70#+i), "UART RX from full FIFO", clk, sbi_if);
    end loop;
    cycles(2, clk);
    chk_bit(rts_b, '0', "RTS# active after the RX FIFO is read");
  end procedure;

end package body tb_UART_rts_pkg;
