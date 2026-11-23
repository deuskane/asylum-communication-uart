-------------------------------------------------------------------------------
-- Title      : tb_uart_core_tests_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_uart_core_tests_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenarios of tb_uart_core : names (valid items of
--              TESTS_LIST), directions each one needs, and dispatch
--              (run_test) to the package of each scenario
--              (tb_uart_core_<name>_pkg)
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

library asylum;
use     asylum.string_pkg.all;

library work;
use     work.tb_uart_core_bfm_pkg.all;

package tb_uart_core_tests_pkg is

  -- Names of the scenarios (valid items of TESTS_LIST)
  constant C_TESTS : string := "tx,rx,loopback,cts,rx_errors,tx_disabled,rx_disabled";

  -- Run the scenario name ; a scenario that does not apply to TX_ENABLE /
  -- RX_ENABLE is a testbench error
  procedure run_test
    (constant name      : in    string
    ;constant tx_enable : in    boolean    -- TX_ENABLE
    ;constant rx_enable : in    boolean    -- RX_ENABLE
    ;signal   clk       : in    std_logic
    ;signal   tb_req    : inout tb_req_t
    ;signal   tb_rsp    : in    tb_rsp_t
    );

end package tb_uart_core_tests_pkg;

package body tb_uart_core_tests_pkg is

  -- TB_ERROR when the scenario name does not apply to the generics
  procedure check_generics
    (constant name      : in    string
    ;constant ok        : in    boolean
    ;constant needs     : in    string
    ) is
  begin
    if not ok
    then
      alert(TB_ERROR, "Scenario " & name & " needs " & needs, C_TB_SCOPE);
    end if;
  end procedure;

  procedure run_test
    (constant name      : in    string
    ;constant tx_enable : in    boolean
    ;constant rx_enable : in    boolean
    ;signal   clk       : in    std_logic
    ;signal   tb_req    : inout tb_req_t
    ;signal   tb_rsp    : in    tb_rsp_t
    ) is
  begin
    if    string_eq(name, "tx")
    then
      check_generics(name, tx_enable, "TX_ENABLE = true");
      work.tb_uart_core_tx_pkg.run(clk, tb_req, tb_rsp);
    elsif string_eq(name, "rx")
    then
      check_generics(name, rx_enable, "RX_ENABLE = true");
      work.tb_uart_core_rx_pkg.run(clk, tb_req, tb_rsp);
    elsif string_eq(name, "loopback")
    then
      check_generics(name, tx_enable and rx_enable, "TX_ENABLE = RX_ENABLE = true");
      work.tb_uart_core_loopback_pkg.run(clk, tb_req, tb_rsp);
    elsif string_eq(name, "cts")
    then
      check_generics(name, tx_enable, "TX_ENABLE = true");
      work.tb_uart_core_cts_pkg.run(clk, tb_req, tb_rsp);
    elsif string_eq(name, "rx_errors")
    then
      check_generics(name, rx_enable, "RX_ENABLE = true");
      work.tb_uart_core_rx_errors_pkg.run(clk, tb_req, tb_rsp);
    elsif string_eq(name, "tx_disabled")
    then
      check_generics(name, not tx_enable, "TX_ENABLE = false");
      work.tb_uart_core_tx_disabled_pkg.run(clk, tb_req, tb_rsp);
    elsif string_eq(name, "rx_disabled")
    then
      check_generics(name, not rx_enable, "RX_ENABLE = false");
      work.tb_uart_core_rx_disabled_pkg.run(clk, tb_req, tb_rsp);
    else
      alert(TB_ERROR, "Unknown test " & name, C_TB_SCOPE);
    end if;
  end procedure;

end package body tb_uart_core_tests_pkg;
