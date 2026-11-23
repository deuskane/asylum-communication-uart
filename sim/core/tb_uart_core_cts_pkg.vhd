-------------------------------------------------------------------------------
-- Title      : tb_uart_core_cts_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_uart_core_cts_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario cts of tb_uart_core
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

package tb_uart_core_cts_pkg is

  -- CTS# back-pressure : no byte taken while uart_cts_b_i = 1, a frame in
  -- progress ends when CTS# goes inactive, the next one waits
  procedure run
    (signal   clk      : in    std_logic
    ;signal   tb_req   : inout tb_req_t
    ;signal   tb_rsp   : in    tb_rsp_t
    );

end package tb_uart_core_cts_pkg;

package body tb_uart_core_cts_pkg is

  procedure run
    (signal   clk      : in    std_logic
    ;signal   tb_req   : inout tb_req_t
    ;signal   tb_rsp   : in    tb_rsp_t
    ) is
    constant C_FRAME   : time := frame_time(C_CNT_FAST);
  begin
    -- uart_cts_b_i is synchronized in uart_core : the transmitter sees it
    -- 2 clock cycles later
    tb_req.cts_b <= '1';
    wait for 2*C_CLK_PERIOD;
    set_tx    ('1', PARITY_NONE, clk, tb_req);
    axis_put  (x"C3", clk, tb_req);
    wait for 2*C_FRAME;
    chk_stable(tb_rsp.tx      , 2*C_FRAME, "CTS# inactive : no frame");
    chk_stable(tb_rsp.s_tready, 2*C_FRAME, "CTS# inactive : no byte taken");
    chk_bit   (tb_rsp.s_tready, '0', "CTS# inactive : s_axis_tready_o");

    -- CTS# active : the byte is taken, then CTS# inactive during its frame
    wait until falling_edge(clk);
    tb_req.cts_b <= '0';
    axis_wait ("Send 0xC3 once CTS# is active", tb_req, tb_rsp, clk);
    tb_req.cts_b <= '1';
    axis_put  (x"3C", clk, tb_req);
    uart_check(x"C3", PARITY_NONE, "TX 0xC3 ends with CTS# inactive", tb_req, tb_rsp);
    wait for 2*C_FRAME;
    chk_stable(tb_rsp.tx      , 2*C_FRAME, "CTS# inactive : no second frame");
    chk_bit   (tb_rsp.s_tready, '0', "CTS# inactive : 0x3C not taken");

    wait until falling_edge(clk);
    tb_req.cts_b <= '0';
    axis_wait ("Send 0x3C once CTS# is active", tb_req, tb_rsp, clk);
    uart_check(x"3C", PARITY_NONE, "TX 0x3C", tb_req, tb_rsp);
  end procedure;

end package body tb_uart_core_cts_pkg;
