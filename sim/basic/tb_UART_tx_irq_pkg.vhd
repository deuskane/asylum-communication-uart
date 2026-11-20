-------------------------------------------------------------------------------
-- Title      : tb_UART_tx_irq_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_UART_tx_irq_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario tx_irq of tb_UART, from reset :
--              Isr polling of the TX FIFO state (empty, neither, full, read
--              right after the clear), TX FIFO empty interrupt raised when
--              the last byte leaves the TX FIFO, level source set again
--              after a clear, dropped by the mask
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (from tb_uart, test 13)
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

package tb_UART_tx_irq_pkg is

  -- Isr polling of the TX FIFO state (empty, neither, full, read right after
  -- the clear), TX FIFO empty interrupt raised when the last byte leaves the
  -- TX FIFO, level source set again after a clear, dropped by the mask
  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   tx       : in    std_logic  -- uart_tx_o
    ;signal   it       : in    std_logic  -- it_o
    );

end package tb_UART_tx_irq_pkg;

package body tb_UART_tx_irq_pkg is

  procedure run
    (signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   tx       : in    std_logic  -- uart_tx_o
    ;signal   it       : in    std_logic  -- it_o
    ) is
  begin
    -- isr / imr sources : [0] TX FIFO empty, [1] TX FIFO full, [2] RX FIFO not
    -- empty, [3] RX FIFO full. Polling : write 1 to clear the bits, then read
    -- isr. A bit cleared while its source is still active is set again one
    -- cycle after the clear : the read wait state of isr lets the read issued
    -- right after the clear (back to back SBI accesses) see it
    wr (UART_ISR, x"FF", "Clear isr (polling)", clk, sbi_if);
    chk(UART_ISR, x"01", "isr read right after the clear : TX FIFO empty", clk, sbi_if);
    -- Fill the TX FIFO while TX is disabled : not empty, then full
    wr (UART_DATA, x"80", "Write UART TX 0x80 while TX is disabled", clk, sbi_if);
    wr (UART_ISR , x"FF", "Clear isr (polling)", clk, sbi_if);
    chk(UART_ISR , x"00", "isr read right after the clear : TX FIFO neither empty nor full", clk, sbi_if);
    for i in 1 to C_DEPTH_TX-1 loop
      wr(UART_DATA, byte(16#80#+i), "Write UART TX while TX is disabled", clk, sbi_if);
    end loop;
    wr (UART_ISR, x"FF", "Clear isr (polling)", clk, sbi_if);
    chk(UART_ISR, x"02", "isr read right after the clear : TX FIFO full", clk, sbi_if);
    -- TX FIFO empty interrupt : raised when the last byte leaves the TX FIFO
    -- (loaded in the transmitter at the stop bit of the previous frame), so
    -- that software can write the next bytes before the line goes idle
    wr(UART_IMR, x"01", "Unmask TX FIFO empty interrupt", clk, sbi_if);
    wait until rising_edge(clk);
    chk_bit(it, '0', "No TX FIFO empty interrupt with a full TX FIFO");
    wr(UART_CTRL_TX, CTRL_EN, "Enable UART TX", clk, sbi_if);
    for i in 0 to C_DEPTH_TX-3 loop
      uart_expect(byte(16#80#+i), PARITY_NONE, "UART TX 0x" & to_hstring(byte(16#80#+i)) & " from the TX FIFO", tx);
    end loop;
    chk_bit(it, '0', "No TX FIFO empty interrupt while a byte is in the TX FIFO");
    uart_expect(x"8E", PARITY_NONE, "UART TX 0x8E, the last byte leaves the TX FIFO", tx);
    chk_bit(it, '1', "TX FIFO empty interrupt");
    uart_expect(x"8F", PARITY_NONE, "UART TX 0x8F, last byte of the TX FIFO", tx);
    chk(UART_ISR, x"03", "TX FIFO empty in isr (TX FIFO full event kept)", clk, sbi_if);
    -- Level source : clearing isr[0] while the TX FIFO is empty does not
    -- drop the interrupt, masking it does (no more byte to send)
    wr (UART_ISR, x"01", "Clear TX FIFO empty interrupt", clk, sbi_if);
    chk(UART_ISR, x"03", "TX FIFO empty set again right after the clear", clk, sbi_if);
    chk_bit(it, '1', "TX FIFO empty interrupt kept while the TX FIFO is empty");
    wr(UART_IMR, x"00", "Mask TX FIFO empty interrupt", clk, sbi_if);
    wait until rising_edge(clk);
    chk_bit(it, '0', "No interrupt when TX FIFO empty is masked");
    wr (UART_ISR, x"FF", "Clear the old events", clk, sbi_if);
    chk(UART_ISR, x"01", "isr read right after the clear : TX FIFO empty", clk, sbi_if);
  end procedure;

end package body tb_UART_tx_irq_pkg;
