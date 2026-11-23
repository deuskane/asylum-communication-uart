-------------------------------------------------------------------------------
-- Title      : tb_uart_core_rx_errors_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_uart_core_rx_errors_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario rx_errors of tb_uart_core
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

package tb_uart_core_rx_errors_pkg is

  -- Errors of the receiver : framing error (stop bit at 0), break (every
  -- bit at 0), overrun (a frame received while the previous byte is
  -- pending : dropped), one pulse each on err_*_o
  procedure run
    (signal   clk      : in    std_logic
    ;signal   tb_req   : inout tb_req_t
    ;signal   tb_rsp   : in    tb_rsp_t
    );

end package tb_uart_core_rx_errors_pkg;

package body tb_uart_core_rx_errors_pkg is

  procedure run
    (signal   clk      : in    std_logic
    ;signal   tb_req   : inout tb_req_t
    ;signal   tb_rsp   : in    tb_rsp_t
    ) is
  begin
    set_rx('1', PARITY_NONE, clk, tb_req);

    -- Framing error : the byte is delivered
    uart_send  (x"5A", PARITY_NONE, tb_req, stop_error => true);
    axis_expect(x"5A", '0', "RX 0x5A with a framing error", tb_req, tb_rsp, clk);
    chk_nb     (tb_rsp.nb_framing, 1, "Framing error (err_framing_o)");
    chk_nb     (tb_rsp.nb_break  , 0, "No break");

    -- Break : 0x00 and stop bit at 0
    uart_send  (x"00", PARITY_NONE, tb_req, stop_error => true);
    axis_expect(x"00", '0', "RX break", tb_req, tb_rsp, clk);
    chk_nb     (tb_rsp.nb_framing, 2, "Framing error of the break (err_framing_o)");
    chk_nb     (tb_rsp.nb_break  , 1, "Break (err_break_o)");

    -- Break with a parity bit : start, data, parity (even) and stop at 0
    set_rx     ('1', PARITY_EVEN, clk, tb_req);
    uart_send  (x"00", PARITY_EVEN, tb_req, stop_error => true);
    axis_expect(x"00", '0', "RX break with parity", tb_req, tb_rsp, clk);
    chk_nb     (tb_rsp.nb_break  , 2, "Break with parity (err_break_o)");
    chk_nb     (tb_rsp.nb_parity , 0, "No parity error");

    -- Overrun : 0x11 pending, 0x22 dropped, 0x33 received
    set_rx     ('1', PARITY_NONE, clk, tb_req);
    uart_send  (x"11", PARITY_NONE, tb_req);
    uart_send  (x"22", PARITY_NONE, tb_req);
    -- The receiver ends the frame after the BFM (synchronizer, stop bit
    -- sampled at mid-bit, registered pulse) : wait one bit period
    wait for (C_CNT_FAST+1) * C_CLK_PERIOD;
    chk_nb     (tb_rsp.nb_overrun, 1, "Overrun (err_overrun_o)");
    axis_expect(x"11", '0', "RX 0x11 kept on overrun", tb_req, tb_rsp, clk);
    uart_send  (x"33", PARITY_NONE, tb_req);
    axis_expect(x"33", '0', "RX 0x33 after the overrun", tb_req, tb_rsp, clk);
    chk_nb     (tb_rsp.nb_overrun, 1, "One overrun");
    chk_nb     (tb_rsp.nb_framing, 3, "No other framing error");
    chk_nb     (tb_rsp.nb_parity , 0, "No parity error");
  end procedure;

end package body tb_uart_core_rx_errors_pkg;
