-------------------------------------------------------------------------------
-- Title      : tb_uart_core_tx_disabled_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_uart_core_tx_disabled_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario tx_disabled of tb_uart_core
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-23  1.0      mrosiere Created
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library work;
use     work.tb_uart_core_bfm_pkg.all;

package tb_uart_core_tx_disabled_pkg is

  -- TX_ENABLE = false : uart_tx_o = 1 (idle line), s_axis_tready_o = 1
  -- (bytes dropped), debug_o.uart_tx = 0, whatever the configuration
  procedure run
    (signal   clk      : in    std_logic
    ;signal   tb_req   : inout tb_req_t
    ;signal   tb_rsp   : in    tb_rsp_t
    );

end package tb_uart_core_tx_disabled_pkg;

package body tb_uart_core_tx_disabled_pkg is

  procedure run
    (signal   clk      : in    std_logic
    ;signal   tb_req   : inout tb_req_t
    ;signal   tb_rsp   : in    tb_rsp_t
    ) is
    constant C_FRAME   : time := frame_time(C_CNT_FAST);
  begin
    set_tx    ('1', PARITY_ODD, clk, tb_req);
    tb_req.cts_b <= '1';
    for i in PATTERNS'range loop
      axis_send (PATTERNS(i), tb_req, tb_rsp, clk);
    end loop;
    tb_req.cts_b <= '0';
    axis_put  (x"AA", clk, tb_req);
    wait for 2*C_FRAME;
    chk_bit   (tb_rsp.tx                 , '1', "TX disabled : uart_tx_o idle");
    chk_bit   (tb_rsp.s_tready           , '1', "TX disabled : s_axis_tready_o");
    chk_bit   (tb_rsp.debug.uart_tx.state, '0', "TX disabled : debug_o.uart_tx.state");
    chk_stable(tb_rsp.tx                 , now, "TX disabled : uart_tx_o never moved");
    chk_stable(tb_rsp.s_tready           , now, "TX disabled : s_axis_tready_o never moved");
    chk_stable(tb_rsp.debug.uart_tx.state, now, "TX disabled : debug_o.uart_tx.state never moved");
    tb_req.s_tvalid <= '0';
  end procedure;

end package body tb_uart_core_tx_disabled_pkg;
