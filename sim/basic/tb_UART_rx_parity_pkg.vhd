-------------------------------------------------------------------------------
-- Title      : tb_UART_rx_parity_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_UART_rx_parity_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario rx_parity of tb_UART, from reset :
--              Reception with even then odd parity : every pattern, good
--              and corrupted parity bit (parity error flag, byte kept,
--              dropped or RX halted by RX_PARITY_ERROR), then back to no
--              parity (flag cleared)
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (from tb_uart, test 5)
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

package tb_UART_rx_parity_pkg is

  -- Reception with even then odd parity : every pattern, good and corrupted
  -- parity bit (parity error flag, byte kept, dropped or RX halted by
  -- RX_PARITY_ERROR), then back to no parity (flag cleared)
  procedure run
    (constant policy   : in    string     -- RX_PARITY_ERROR
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   rx       : out   std_logic  -- uart_rx_i
    ;signal   par_err  : in    std_logic  -- debug_o.uart_rx.parity_error
    );

end package tb_UART_rx_parity_pkg;

package body tb_UART_rx_parity_pkg is

  procedure run
    (constant policy   : in    string     -- RX_PARITY_ERROR
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   rx       : out   std_logic  -- uart_rx_i
    ;signal   par_err  : in    std_logic  -- debug_o.uart_rx.parity_error
    ) is
    variable v_parity  : parity_t;
    variable v_ctrl    : byte_t;
  begin
    for p in 0 to 1 loop
      if p = 0
      then
        v_parity := PARITY_EVEN;
        v_ctrl   := CTRL_EN_EVEN;
      else
        v_parity := PARITY_ODD;
        v_ctrl   := CTRL_EN_ODD;
      end if;
      log(ID_SEQUENCER, "RX with " & to_string(v_parity) & " parity", C_TB_SCOPE);
      wr (UART_CTRL_RX, v_ctrl, "Enable UART RX with " & to_string(v_parity) & " parity", clk, sbi_if);
      chk(UART_CTRL_RX, v_ctrl, "Read back ctrl_rx", clk, sbi_if);
      for i in PATTERNS'range loop
        test_rx(PATTERNS(i), v_parity, false, policy, clk, sbi_if, rx, par_err);
      end loop;
      test_rx(x"A5", v_parity, true , policy, clk, sbi_if, rx, par_err);
      test_rx(x"5A", v_parity, false, policy, clk, sbi_if, rx, par_err);
      test_rx(x"01", v_parity, true , policy, clk, sbi_if, rx, par_err);
    end loop;
    -- Back to no parity : the parity error flag is cleared
    wr(UART_CTRL_RX, CTRL_EN, "Enable UART RX without parity", clk, sbi_if);
    test_rx(x"81", PARITY_NONE, false, policy, clk, sbi_if, rx, par_err);
    test_rx(x"7E", PARITY_NONE, false, policy, clk, sbi_if, rx, par_err);
  end procedure;

end package body tb_UART_rx_parity_pkg;
