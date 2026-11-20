-------------------------------------------------------------------------------
-- Title      : tb_UART_tests_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_UART_tests_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenarios of tb_UART : names (valid items of TESTS_LIST) and
--              dispatch (run_test) to the package of each scenario
--              (tb_UART_<name>_pkg)
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library bitvis_vip_sbi;
use     bitvis_vip_sbi.sbi_bfm_pkg.all;

library asylum;
use     asylum.string_pkg.all;

library work;
use     work.tb_UART_bfm_pkg.all;

package tb_UART_tests_pkg is

  -- Names of the scenarios (valid items of TESTS_LIST)
  constant C_TESTS : string := "reset_values,rx,rx_drift,rx_glitch,rx_parity,tx,loopback,tx_flow,rx_overrun,rx_pending,rx_errors,tx_irq,rts,echo,parity_policy,baud";

  -- Run the scenario name
  procedure run_test
    (constant name     : in    string
    ;constant policy   : in    string     -- RX_PARITY_ERROR
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   rx       : out   std_logic  -- uart_rx_i
    ;signal   tx       : in    std_logic  -- uart_tx_o
    ;signal   cts_b    : out   std_logic  -- uart_cts_b_i
    ;signal   rts_b    : in    std_logic  -- uart_rts_b_o
    ;signal   it       : in    std_logic  -- it_o
    ;signal   par_err  : in    std_logic  -- debug_o.uart_rx.parity_error
    );

end package tb_UART_tests_pkg;

package body tb_UART_tests_pkg is

  procedure run_test
    (constant name     : in    string
    ;constant policy   : in    string     -- RX_PARITY_ERROR
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   rx       : out   std_logic  -- uart_rx_i
    ;signal   tx       : in    std_logic  -- uart_tx_o
    ;signal   cts_b    : out   std_logic  -- uart_cts_b_i
    ;signal   rts_b    : in    std_logic  -- uart_rts_b_o
    ;signal   it       : in    std_logic  -- it_o
    ;signal   par_err  : in    std_logic  -- debug_o.uart_rx.parity_error
    ) is
  begin
    if    string_eq(name, "reset_values")
    then
      work.tb_UART_reset_values_pkg.run(clk, sbi_if, tx, rts_b, it);
    elsif string_eq(name, "rx")
    then
      work.tb_UART_rx_pkg.run(policy, clk, sbi_if, rx, par_err);
    elsif string_eq(name, "rx_drift")
    then
      work.tb_UART_rx_drift_pkg.run(clk, sbi_if, rx);
    elsif string_eq(name, "rx_glitch")
    then
      work.tb_UART_rx_glitch_pkg.run(clk, sbi_if, rx, it);
    elsif string_eq(name, "rx_parity")
    then
      work.tb_UART_rx_parity_pkg.run(policy, clk, sbi_if, rx, par_err);
    elsif string_eq(name, "tx")
    then
      work.tb_UART_tx_pkg.run(clk, sbi_if, tx);
    elsif string_eq(name, "loopback")
    then
      work.tb_UART_loopback_pkg.run(policy, clk, sbi_if, tx, par_err);
    elsif string_eq(name, "tx_flow")
    then
      work.tb_UART_tx_flow_pkg.run(clk, sbi_if, tx, cts_b);
    elsif string_eq(name, "rx_overrun")
    then
      work.tb_UART_rx_overrun_pkg.run(clk, sbi_if, rx, tx, rts_b, it);
    elsif string_eq(name, "rx_pending")
    then
      work.tb_UART_rx_pending_pkg.run(clk, sbi_if);
    elsif string_eq(name, "rx_errors")
    then
      work.tb_UART_rx_errors_pkg.run(policy, clk, sbi_if, rx, it, par_err);
    elsif string_eq(name, "tx_irq")
    then
      work.tb_UART_tx_irq_pkg.run(clk, sbi_if, tx, it);
    elsif string_eq(name, "rts")
    then
      work.tb_UART_rts_pkg.run(clk, sbi_if, rx, rts_b);
    elsif string_eq(name, "echo")
    then
      work.tb_UART_echo_pkg.run(policy, clk, sbi_if, rx, tx, cts_b, rts_b, it);
    elsif string_eq(name, "parity_policy")
    then
      work.tb_UART_parity_policy_pkg.run(policy, clk, sbi_if, rx, rts_b);
    elsif string_eq(name, "baud")
    then
      work.tb_UART_baud_pkg.run(clk, sbi_if, rx, tx);
    else
      alert(TB_ERROR, "Unknown test " & name, C_TB_SCOPE);
    end if;
  end procedure;

end package body tb_UART_tests_pkg;
