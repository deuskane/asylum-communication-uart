-------------------------------------------------------------------------------
-- Title      : tb_uart_core_rx_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_uart_core_rx_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario rx of tb_uart_core
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

package tb_uart_core_rx_pkg is

  -- Reception : cfg_rx_enable_i = 0 holds RX in reset (no byte), then every
  -- pattern without, with even and with odd parity, and a corrupted parity
  -- bit (m_axis_parity_error_o, err_parity_o, debug_o.uart_rx.parity_error),
  -- then frames whose bits change away from the clock edges (uart_rx_i is
  -- asynchronous) (TX parity left disabled)
  procedure run
    (signal   clk      : in    std_logic
    ;signal   tb_req   : inout tb_req_t
    ;signal   tb_rsp   : in    tb_rsp_t
    );

end package tb_uart_core_rx_pkg;

package body tb_uart_core_rx_pkg is

  procedure run
    (signal   clk      : in    std_logic
    ;signal   tb_req   : inout tb_req_t
    ;signal   tb_rsp   : in    tb_rsp_t
    ) is
    constant C_FRAME   : time := frame_time(C_CNT_FAST);
    -- Delay of the frame start after a rising edge (clock period 20 ns)
    type     time_array_t is array (natural range <>) of time;
    constant C_PHASES  : time_array_t := (1 ns, 7 ns, 13 ns, 19 ns);
  begin
    -- RX disabled : held in reset
    uart_send (x"3C", PARITY_NONE, tb_req);
    wait for C_FRAME;
    chk_stable(tb_rsp.m_tvalid, C_FRAME, "RX disabled : no byte");
    chk_bit   (tb_rsp.m_tvalid, '0', "RX disabled : m_axis_tvalid_o");

    set_rx('1', PARITY_NONE, clk, tb_req);
    for p in PARITIES'range loop
      set_rx('1', PARITIES(p), clk, tb_req);
      for i in PATTERNS'range loop
        uart_send  (PATTERNS(i), PARITIES(p), tb_req);
        axis_expect(PATTERNS(i), '0', "RX 0x" & to_hstring(PATTERNS(i)) & " (" & to_string(PARITIES(p)) & ")", tb_req, tb_rsp, clk);
      end loop;
      chk_nb(tb_rsp.nb_parity, 0, "No parity error (" & to_string(PARITIES(p)) & ")");
    end loop;

    -- Corrupted parity bit : the byte is delivered with its parity error
    for p in PARITY_ODD to PARITY_EVEN loop
      set_rx     ('1', p, clk, tb_req);
      uart_send  (x"A5", p, tb_req, parity_error => true);
      chk_bit    (tb_rsp.debug.uart_rx.parity_error, '1', "debug_o.uart_rx.parity_error (" & to_string(p) & ")");
      axis_expect(x"A5", '1', "RX 0xA5 with a parity error (" & to_string(p) & ")", tb_req, tb_rsp, clk);
      uart_send  (x"A5", p, tb_req);
      chk_bit    (tb_rsp.debug.uart_rx.parity_error, '0', "debug_o.uart_rx.parity_error cleared (" & to_string(p) & ")");
      axis_expect(x"A5", '0', "RX 0xA5 (" & to_string(p) & ")", tb_req, tb_rsp, clk);
    end loop;

    -- Asynchronous line : every edge of the frame between two clock edges
    set_rx('1', PARITY_NONE, clk, tb_req);
    for i in C_PHASES'range loop
      wait until rising_edge(clk);
      wait for C_PHASES(i);
      uart_send  (x"96", PARITY_NONE, tb_req);
      axis_expect(x"96", '0', "RX 0x96, line edges " & to_string(C_PHASES(i)) & " after the clock edges", tb_req, tb_rsp, clk);
    end loop;

    chk_nb(tb_rsp.nb_parity , 2, "Two parity errors (err_parity_o)");
    chk_nb(tb_rsp.nb_framing, 0, "No framing error");
    chk_nb(tb_rsp.nb_overrun, 0, "No overrun");
  end procedure;

end package body tb_uart_core_rx_pkg;
