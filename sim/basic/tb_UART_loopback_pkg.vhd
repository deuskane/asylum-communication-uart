-------------------------------------------------------------------------------
-- Title      : tb_UART_loopback_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_UART_loopback_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario loopback of tb_UART, from reset :
--              Internal loopback (ctrl_rx.rx_use_loopback) without, with
--              even and with odd parity : every pattern sent on uart_tx_o
--              and read back, then TX even / RX odd : parity error
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (from tb_uart, tests 7 and 8)
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

package tb_UART_loopback_pkg is

  -- Internal loopback (ctrl_rx.rx_use_loopback) without, with even and with
  -- odd parity : every pattern sent on uart_tx_o and read back, then TX even /
  -- RX odd : parity error
  procedure run
    (constant policy   : in    string     -- RX_PARITY_ERROR
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   tx       : in    std_logic  -- uart_tx_o
    ;signal   par_err  : in    std_logic  -- debug_o.uart_rx.parity_error
    );

end package tb_UART_loopback_pkg;

package body tb_UART_loopback_pkg is

  procedure run
    (constant policy   : in    string     -- RX_PARITY_ERROR
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   tx       : in    std_logic  -- uart_tx_o
    ;signal   par_err  : in    std_logic  -- debug_o.uart_rx.parity_error
    ) is
    variable v_parity  : parity_t;
    variable v_ctrl    : byte_t;
  begin
    for p in 0 to 2 loop
      if p = 0
      then
        v_parity := PARITY_NONE;
        v_ctrl   := CTRL_EN;
      elsif p = 1
      then
        v_parity := PARITY_EVEN;
        v_ctrl   := CTRL_EN_EVEN;
      else
        v_parity := PARITY_ODD;
        v_ctrl   := CTRL_EN_ODD;
      end if;
      log(ID_SEQUENCER, "Loopback with parity " & to_string(v_parity), C_TB_SCOPE);
      wr(UART_CTRL_TX, v_ctrl                 , "Enable UART TX", clk, sbi_if);
      wr(UART_CTRL_RX, v_ctrl or CTRL_LOOPBACK, "Enable UART RX in loopback", clk, sbi_if);
      for i in PATTERNS'range loop
        test_loopback(PATTERNS(i), v_parity, '0', policy, clk, sbi_if, tx, par_err);
      end loop;
    end loop;
    -- Parity mismatch (TX even, RX odd) : parity error
    log(ID_SEQUENCER, "Loopback with parity mismatch (TX even, RX odd)", C_TB_SCOPE);
    wr(UART_CTRL_TX, CTRL_EN_EVEN                , "Enable UART TX even parity", clk, sbi_if);
    wr(UART_CTRL_RX, CTRL_EN_ODD  or CTRL_LOOPBACK, "Enable UART RX odd parity in loopback", clk, sbi_if);
    test_loopback(x"A5", PARITY_EVEN, '1', policy, clk, sbi_if, tx, par_err);
    test_loopback(x"01", PARITY_EVEN, '1', policy, clk, sbi_if, tx, par_err);
    wr(UART_CTRL_RX, CTRL_EN_EVEN or CTRL_LOOPBACK, "Enable UART RX even parity in loopback", clk, sbi_if);
    test_loopback(x"01", PARITY_EVEN, '0', policy, clk, sbi_if, tx, par_err);
  end procedure;

end package body tb_UART_loopback_pkg;
