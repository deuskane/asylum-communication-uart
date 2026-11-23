-------------------------------------------------------------------------------
-- Title      : tb_uart_core_rx_disabled_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_uart_core_rx_disabled_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario rx_disabled of tb_uart_core
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

package tb_uart_core_rx_disabled_pkg is

  -- RX_ENABLE = false : m_axis_tvalid_o = 0, m_axis_tdata_o = 0,
  -- m_axis_parity_error_o = 0, no error pulse, debug_o.uart_rx = 0, while
  -- frames (good, parity error, framing error, break) come on uart_rx_i
  procedure run
    (signal   clk      : in    std_logic
    ;signal   tb_req   : inout tb_req_t
    ;signal   tb_rsp   : in    tb_rsp_t
    );

end package tb_uart_core_rx_disabled_pkg;

package body tb_uart_core_rx_disabled_pkg is

  procedure run
    (signal   clk      : in    std_logic
    ;signal   tb_req   : inout tb_req_t
    ;signal   tb_rsp   : in    tb_rsp_t
    ) is
  begin
    set_rx    ('1', PARITY_EVEN, clk, tb_req);
    tb_req.m_tready <= '1';
    uart_send (x"A5", PARITY_EVEN, tb_req);
    uart_send (x"5A", PARITY_EVEN, tb_req, parity_error => true);
    uart_send (x"C3", PARITY_EVEN, tb_req, stop_error   => true);
    uart_send (x"00", PARITY_EVEN, tb_req, stop_error   => true);
    tb_req.m_tready <= '0';
    uart_send (x"3C", PARITY_EVEN, tb_req);
    uart_send (x"3C", PARITY_EVEN, tb_req);
    wait for frame_time(C_CNT_FAST);
    chk_bit   (tb_rsp.m_tvalid      , '0', "RX disabled : m_axis_tvalid_o");
    check_value(tb_rsp.m_tdata      , x"00", error, "RX disabled : m_axis_tdata_o", C_TB_SCOPE);
    chk_bit   (tb_rsp.m_parity_error, '0', "RX disabled : m_axis_parity_error_o");
    chk_nb    (tb_rsp.nb_overrun    , 0  , "RX disabled : no err_overrun_o pulse");
    chk_nb    (tb_rsp.nb_parity     , 0  , "RX disabled : no err_parity_o pulse");
    chk_nb    (tb_rsp.nb_framing    , 0  , "RX disabled : no err_framing_o pulse");
    chk_nb    (tb_rsp.nb_break      , 0  , "RX disabled : no err_break_o pulse");
    chk_stable(tb_rsp.m_tvalid      , now, "RX disabled : m_axis_tvalid_o never moved");
    chk_stable(tb_rsp.m_parity_error, now, "RX disabled : m_axis_parity_error_o never moved");
    check_stable(tb_rsp.m_tdata, now, error, "RX disabled : m_axis_tdata_o never moved", C_TB_SCOPE);
    check_value (tb_rsp.debug.uart_rx.state  , "00"  , error, "RX disabled : debug_o.uart_rx.state"  , C_TB_SCOPE);
    check_stable(tb_rsp.debug.uart_rx.state  , now   , error, "RX disabled : debug_o.uart_rx.state never moved", C_TB_SCOPE);
    check_value (tb_rsp.debug.uart_rx.bit_cnt, "0000", error, "RX disabled : debug_o.uart_rx.bit_cnt", C_TB_SCOPE);
    check_stable(tb_rsp.debug.uart_rx.bit_cnt, now   , error, "RX disabled : debug_o.uart_rx.bit_cnt never moved", C_TB_SCOPE);
    chk_bit   (tb_rsp.debug.uart_rx.baud_tick_half, '0', "RX disabled : debug_o.uart_rx.baud_tick_half");
    chk_stable(tb_rsp.debug.uart_rx.baud_tick_half, now, "RX disabled : debug_o.uart_rx.baud_tick_half never moved");
    chk_bit   (tb_rsp.debug.uart_rx.parity_error  , '0', "RX disabled : debug_o.uart_rx.parity_error");
    chk_stable(tb_rsp.debug.uart_rx.parity_error  , now, "RX disabled : debug_o.uart_rx.parity_error never moved");
  end procedure;

end package body tb_uart_core_rx_disabled_pkg;
