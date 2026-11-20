-------------------------------------------------------------------------------
-- Title      : tb_UART_baud_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_UART_baud_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario baud of tb_UART, from reset :
--              Software baud rate : baud_tick_cnt_max written (57600 baud,
--              MSB and LSB not 0) while TX and RX are disabled : a frame
--              sent and a frame received at the new bit period
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created
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

package tb_UART_baud_pkg is

  -- Software baud rate : baud_tick_cnt_max written (57600 baud, MSB and LSB
  -- not 0) while TX and RX are disabled : a frame sent and a frame received at
  -- the new bit period
  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   rx       : out   std_logic  -- uart_rx_i
    ;signal   tx       : in    std_logic  -- uart_tx_o
    );

end package tb_UART_baud_pkg;

package body tb_UART_baud_pkg is

  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   rx       : out   std_logic  -- uart_rx_i
    ;signal   tx       : in    std_logic  -- uart_tx_o
    ) is
    -- 57600 baud : (CLOCK_FREQ/57600)-1 = 867 = 0x0363
    constant C_DIV     : natural := C_CLOCK_FREQ / 57_600;
    constant C_PERIOD  : time    := C_DIV * C_CLK_PERIOD;
    constant C_CNT_MAX : std_logic_vector(16-1 downto 0) := std_logic_vector(to_unsigned(C_DIV-1, 16));
  begin
    wr(UART_BAUD_TICK_CNT_MAX_LSB, C_CNT_MAX( 7 downto 0), "Write baud_tick_cnt_max_lsb (57600 baud)", clk, sbi_if);
    wr(UART_BAUD_TICK_CNT_MAX_MSB, C_CNT_MAX(15 downto 8), "Write baud_tick_cnt_max_msb (57600 baud)", clk, sbi_if);
    wr(UART_CTRL_TX, CTRL_EN, "Enable UART TX", clk, sbi_if);
    wr(UART_CTRL_RX, CTRL_EN, "Enable UART RX", clk, sbi_if);
    wr(UART_DATA, x"96", "Write UART TX 0x96", clk, sbi_if);
    uart_expect(x"96", PARITY_NONE, "UART TX 0x96 at 57600 baud", tx, C_PERIOD);
    uart_send(x"69", C_PERIOD, rx);
    chk(UART_DATA, x"69", "UART RX 0x69 at 57600 baud", clk, sbi_if);
  end procedure;

end package body tb_UART_baud_pkg;
