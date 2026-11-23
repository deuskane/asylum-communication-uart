-------------------------------------------------------------------------------
-- Title      : tb_uart_core_loopback_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_uart_core_loopback_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario loopback of tb_uart_core
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

package tb_uart_core_loopback_pkg is

  -- uart_tx_o looped back to uart_rx_i : every pattern at two baud rates,
  -- without, with even and with odd parity ; parity of TX and RX set
  -- separately (TX even / RX odd and TX odd / RX even : parity errors)
  procedure run
    (signal   clk      : in    std_logic
    ;signal   tb_req   : inout tb_req_t
    ;signal   tb_rsp   : in    tb_rsp_t
    );

end package tb_uart_core_loopback_pkg;

package body tb_uart_core_loopback_pkg is

  procedure run
    (signal   clk      : in    std_logic
    ;signal   tb_req   : inout tb_req_t
    ;signal   tb_rsp   : in    tb_rsp_t
    ) is
  begin
    tb_req.loopback <= true;
    for b in 0 to 1 loop
      if b = 0
      then
        tb_req.cnt_max <= C_CNT_FAST;
      else
        tb_req.cnt_max <= C_CNT_SLOW;
      end if;
      wait for 0 ns;
      log(ID_SEQUENCER, "Loopback, " & integer'image(tb_req.cnt_max+1) & " clock cycles per bit", C_TB_SCOPE);
      for p in PARITIES'range loop
        set_tx('1', PARITIES(p), clk, tb_req);
        set_rx('1', PARITIES(p), clk, tb_req);
        for i in PATTERNS'range loop
          axis_send  (PATTERNS(i), tb_req, tb_rsp, clk);
          axis_expect(PATTERNS(i), '0', "Loopback 0x" & to_hstring(PATTERNS(i)) & " (" & to_string(PARITIES(p)) & ", " & integer'image(tb_req.cnt_max+1) & " cycles per bit)", tb_req, tb_rsp, clk);
        end loop;
      end loop;
      -- Back to the reset of both directions before the next baud rate
      set_tx('0', PARITY_NONE, clk, tb_req);
      set_rx('0', PARITY_NONE, clk, tb_req);
      wait until rising_edge(clk);
    end loop;
    chk_nb(tb_rsp.nb_parity, 0, "No parity error");

    -- TX and RX parities differ : the byte is received with a parity error
    tb_req.cnt_max <= C_CNT_FAST;
    set_tx     ('1', PARITY_EVEN, clk, tb_req);
    set_rx     ('1', PARITY_ODD , clk, tb_req);
    axis_send  (x"A5", tb_req, tb_rsp, clk);
    axis_expect(x"A5", '1', "Loopback 0xA5, TX even, RX odd", tb_req, tb_rsp, clk);
    set_tx     ('1', PARITY_ODD , clk, tb_req);
    set_rx     ('1', PARITY_EVEN, clk, tb_req);
    axis_send  (x"3C", tb_req, tb_rsp, clk);
    axis_expect(x"3C", '1', "Loopback 0x3C, TX odd, RX even", tb_req, tb_rsp, clk);
    chk_nb(tb_rsp.nb_parity , 2, "Two parity errors (err_parity_o)");
    chk_nb(tb_rsp.nb_framing, 0, "No framing error");
  end procedure;

end package body tb_uart_core_loopback_pkg;
