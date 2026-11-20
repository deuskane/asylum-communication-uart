-------------------------------------------------------------------------------
-- Title      : tb_UART_reset_values_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_UART_reset_values_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario reset_values of tb_UART, from reset :
--              Reset values of the pads (uart_tx_o idle, RTS# active, it_o)
--              and of the registers (isr : TX FIFO empty only,
--              baud_tick_cnt_max = (CLOCK_FREQ/BAUD_RATE)-1), read / write
--              of imr, ctrl_tx, ctrl_rx and baud_tick_cnt_max
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

package tb_UART_reset_values_pkg is

  -- Reset values of the pads (uart_tx_o idle, RTS# active, it_o) and of the
  -- registers (isr : TX FIFO empty only, baud_tick_cnt_max =
  -- (CLOCK_FREQ/BAUD_RATE)-1), read / write of imr, ctrl_tx, ctrl_rx and
  -- baud_tick_cnt_max
  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   tx       : in    std_logic  -- uart_tx_o
    ;signal   rts_b    : in    std_logic  -- uart_rts_b_o
    ;signal   it       : in    std_logic  -- it_o
    );

end package tb_UART_reset_values_pkg;

package body tb_UART_reset_values_pkg is

  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   tx       : in    std_logic  -- uart_tx_o
    ;signal   rts_b    : in    std_logic  -- uart_rts_b_o
    ;signal   it       : in    std_logic  -- it_o
    ) is
  begin
    -- Pads after reset : line idle, RTS# active, no interrupt
    chk_bit(tx   , '1', "uart_tx_o idle (1) after reset");
    chk_bit(rts_b, '0', "uart_rts_b_o active (0) after reset");
    chk_bit(it   , '0', "it_o inactive after reset");
    -- Registers : the empty TX FIFO is the only active source
    chk(UART_ISR                  , x"01"                          , "isr : TX FIFO empty only", clk, sbi_if);
    chk(UART_IMR                  , x"00"                          , "imr reset value", clk, sbi_if);
    chk(UART_CTRL_TX              , x"00"                          , "ctrl_tx reset value (TX disabled)", clk, sbi_if);
    chk(UART_CTRL_RX              , x"00"                          , "ctrl_rx reset value (RX disabled)", clk, sbi_if);
    chk(UART_BAUD_TICK_CNT_MAX_LSB, C_BAUD_TICK_CNT_MAX( 7 downto 0), "baud_tick_cnt_max_lsb : (CLOCK_FREQ/BAUD_RATE)-1", clk, sbi_if);
    chk(UART_BAUD_TICK_CNT_MAX_MSB, C_BAUD_TICK_CNT_MAX(15 downto 8), "baud_tick_cnt_max_msb : (CLOCK_FREQ/BAUD_RATE)-1", clk, sbi_if);
    -- Read / write (ctrl_tx and ctrl_rx : 5 bits)
    wr (UART_IMR                  , x"A5", "Write imr", clk, sbi_if);
    chk(UART_IMR                  , x"A5", "Read back imr", clk, sbi_if);
    wr (UART_CTRL_TX              , x"FF", "Write ctrl_tx", clk, sbi_if);
    chk(UART_CTRL_TX              , x"1F", "Read back ctrl_tx (bits 4:0)", clk, sbi_if);
    wr (UART_CTRL_RX              , x"FF", "Write ctrl_rx", clk, sbi_if);
    chk(UART_CTRL_RX              , x"1F", "Read back ctrl_rx (bits 4:0)", clk, sbi_if);
    wr (UART_BAUD_TICK_CNT_MAX_LSB, x"5A", "Write baud_tick_cnt_max_lsb", clk, sbi_if);
    wr (UART_BAUD_TICK_CNT_MAX_MSB, x"C3", "Write baud_tick_cnt_max_msb", clk, sbi_if);
    chk(UART_BAUD_TICK_CNT_MAX_LSB, x"5A", "Read back baud_tick_cnt_max_lsb", clk, sbi_if);
    chk(UART_BAUD_TICK_CNT_MAX_MSB, x"C3", "Read back baud_tick_cnt_max_msb", clk, sbi_if);
  end procedure;

end package body tb_UART_reset_values_pkg;
