-------------------------------------------------------------------------------
-- Title      : tb_UART_tx_flow_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_UART_tx_flow_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario tx_flow of tb_UART, from reset :
--              A byte written while TX is disabled waits in the TX FIFO,
--              CTS# ignored while cts_enable = 0, bytes written while CTS#
--              is inactive (cts_enable = 1) are sent after its activation
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (from tb_uart, test 10)
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

package tb_UART_tx_flow_pkg is

  -- A byte written while TX is disabled waits in the TX FIFO, CTS# ignored
  -- while cts_enable = 0, bytes written while CTS# is inactive (cts_enable =
  -- 1) are sent after its activation
  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   tx       : in    std_logic  -- uart_tx_o
    ;signal   cts_b    : out   std_logic  -- uart_cts_b_i
    );

end package tb_UART_tx_flow_pkg;

package body tb_UART_tx_flow_pkg is

  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   tx       : in    std_logic  -- uart_tx_o
    ;signal   cts_b    : out   std_logic  -- uart_cts_b_i
    ) is
  begin
    wr(UART_DATA, x"4B", "Write UART TX 0x4B while TX is disabled", clk, sbi_if);
    chk_idle(tx, 2 * 12 * C_BIT_PERIOD, "No frame while TX is disabled");
    wr(UART_CTRL_TX, CTRL_EN, "Enable UART TX", clk, sbi_if);
    uart_expect(x"4B", PARITY_NONE, "Byte written while TX was disabled", tx);
    -- cts_enable = 0 : the CTS# pin is ignored (waits for CTS# through the
    -- synchronizer)
    cts_b <= '1';
    cycles(3, clk);
    wr(UART_DATA, x"E1", "Write UART TX 0xE1, CTS# inactive and cts_enable = 0", clk, sbi_if);
    uart_expect(x"E1", PARITY_NONE, "CTS# ignored while cts_enable = 0", tx);
    -- cts_enable = 1 : no frame while CTS# is inactive
    wr(UART_CTRL_TX, CTRL_EN or CTRL_FLOW_CTRL, "Enable UART TX with CTS", clk, sbi_if);
    wr(UART_DATA, x"D2", "Write UART TX 0xD2 while CTS# is inactive", clk, sbi_if);
    wr(UART_DATA, x"2D", "Write UART TX 0x2D while CTS# is inactive", clk, sbi_if);
    chk_idle(tx, 3 * 12 * C_BIT_PERIOD, "No frame while CTS# is inactive");
    cts_b <= '0';
    uart_expect(x"D2", PARITY_NONE, "UART TX 0xD2 after CTS# activation", tx);
    uart_expect(x"2D", PARITY_NONE, "UART TX 0x2D after CTS# activation", tx);
  end procedure;

end package body tb_UART_tx_flow_pkg;
