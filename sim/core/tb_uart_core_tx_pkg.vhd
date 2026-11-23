-------------------------------------------------------------------------------
-- Title      : tb_uart_core_tx_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_uart_core_tx_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario tx of tb_uart_core
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

package tb_uart_core_tx_pkg is

  -- Transmission : cfg_tx_enable_i = 0 holds TX in reset (no byte taken,
  -- line idle), then every pattern without, with even and with odd parity,
  -- every bit of the frame checked (RX parity left disabled)
  procedure run
    (signal   clk      : in    std_logic
    ;signal   tb_req   : inout tb_req_t
    ;signal   tb_rsp   : in    tb_rsp_t
    );

end package tb_uart_core_tx_pkg;

package body tb_uart_core_tx_pkg is

  procedure run
    (signal   clk      : in    std_logic
    ;signal   tb_req   : inout tb_req_t
    ;signal   tb_rsp   : in    tb_rsp_t
    ) is
    constant C_FRAME   : time := frame_time(C_CNT_FAST);
  begin
    -- TX disabled : held in reset
    chk_bit   (tb_rsp.tx, '1', "Line idle after the reset");
    axis_put  (x"55", clk, tb_req);
    wait for C_FRAME;
    chk_stable(tb_rsp.tx      , C_FRAME, "TX disabled : no frame");
    chk_stable(tb_rsp.s_tready, C_FRAME, "TX disabled : no byte taken");
    chk_bit   (tb_rsp.s_tready, '0', "TX disabled : s_axis_tready_o");

    -- TX enabled : the pending byte is sent
    set_tx    ('1', PARITY_NONE, clk, tb_req);
    axis_wait ("Send 0x55 once TX is enabled", tb_req, tb_rsp, clk);
    wait until falling_edge(clk);
    chk_bit   (tb_rsp.debug.uart_tx.state, '1', "debug_o.uart_tx.state : frame in progress");
    uart_check(x"55", PARITY_NONE, "TX 0x55", tb_req, tb_rsp);

    for p in PARITIES'range loop
      set_tx('1', PARITIES(p), clk, tb_req);
      for i in PATTERNS'range loop
        axis_send (PATTERNS(i), tb_req, tb_rsp, clk);
        uart_check(PATTERNS(i), PARITIES(p), "TX 0x" & to_hstring(PATTERNS(i)), tb_req, tb_rsp);
      end loop;
    end loop;
  end procedure;

end package body tb_uart_core_tx_pkg;
