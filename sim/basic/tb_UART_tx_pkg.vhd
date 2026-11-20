-------------------------------------------------------------------------------
-- Title      : tb_UART_tx_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_UART_tx_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario tx of tb_UART, from reset :
--              Transmission without, with even and with odd parity : every
--              pattern, every bit of the frame checked, back to back frames
--              from the TX FIFO
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (from tb_uart, test 6)
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

package tb_UART_tx_pkg is

  -- Transmission without, with even and with odd parity : every pattern, every
  -- bit of the frame checked, back to back frames from the TX FIFO
  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   tx       : in    std_logic  -- uart_tx_o
    );

end package tb_UART_tx_pkg;

package body tb_UART_tx_pkg is

  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   tx       : in    std_logic  -- uart_tx_o
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
      log(ID_SEQUENCER, "TX with parity " & to_string(v_parity), C_TB_SCOPE);
      wr (UART_CTRL_TX, v_ctrl, "Enable UART TX with parity " & to_string(v_parity), clk, sbi_if);
      chk(UART_CTRL_TX, v_ctrl, "Read back ctrl_tx", clk, sbi_if);
      for i in PATTERNS'range loop
        test_tx(PATTERNS(i), v_parity, clk, sbi_if, tx);
      end loop;
      -- Back to back frames (TX FIFO)
      wr(UART_DATA, x"96", "Write UART TX 0x96", clk, sbi_if);
      wr(UART_DATA, x"69", "Write UART TX 0x69", clk, sbi_if);
      uart_expect(x"96", v_parity, "UART TX back to back 0x96", tx);
      uart_expect(x"69", v_parity, "UART TX back to back 0x69", tx);
      wr(UART_CTRL_TX, x"00", "Disable UART TX", clk, sbi_if);
    end loop;
  end procedure;

end package body tb_UART_tx_pkg;
