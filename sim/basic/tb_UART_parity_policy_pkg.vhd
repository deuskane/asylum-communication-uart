-------------------------------------------------------------------------------
-- Title      : tb_UART_parity_policy_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_UART_parity_policy_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario parity_policy of tb_UART, from reset :
--              Policy on a byte with a parity error (RX_PARITY_ERROR) with
--              RTS# enabled : keep (stored), drop (dropped) or halt
--              (stored, RX halted and RTS# inactive until isr[6] is
--              cleared), overrun of a frame with a parity error while a
--              good byte waits for room in the full RX FIFO, byte with a
--              parity error received while the RX FIFO is full (waits for
--              room or dropped, halt : event when it enters the RX FIFO)
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (from tb_uart, test 16)
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

package tb_UART_parity_policy_pkg is

  -- Policy on a byte with a parity error (RX_PARITY_ERROR) with RTS# enabled :
  -- keep (stored), drop (dropped) or halt (stored, RX halted and RTS# inactive
  -- until isr[6] is cleared), overrun of a frame with a parity error while a
  -- good byte waits for room in the full RX FIFO, byte with a parity error
  -- received while the RX FIFO is full (waits for room or dropped, halt :
  -- event when it enters the RX FIFO)
  procedure run
    (constant policy   : in    string     -- RX_PARITY_ERROR
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   rx       : out   std_logic  -- uart_rx_i
    ;signal   rts_b    : in    std_logic  -- uart_rts_b_o
    );

end package tb_UART_parity_policy_pkg;

package body tb_UART_parity_policy_pkg is

  procedure run
    (constant policy   : in    string     -- RX_PARITY_ERROR
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   rx       : out   std_logic  -- uart_rx_i
    ;signal   rts_b    : in    std_logic  -- uart_rts_b_o
    ) is
    -- Good byte A, byte B with a parity error, good bytes C and D
    constant POLICY_BYTES : byte_array_t := (x"A1", x"B2", x"C3", x"D4");
  begin
    -- Good byte A, byte B with a parity error, then C and D back to back.
    --   "keep" : A, B, C and D stored, RTS# stays active
    --   "drop" : B dropped, A, C and D stored
    --   "halt" : B stored, RX halted and RTS# inactive : the RX FIFO holds
    --            A and B, C waits in uart_rx_axis, D is an overrun. The
    --            clear of isr[6] resumes RX : C stored, RTS# active
    -- The RX FIFO state is polled in isr (never a blocking read of an empty
    -- RX FIFO while RX is halted)
    log(ID_SEQUENCER, "Parity error policy (RX_PARITY_ERROR = " & policy & ")", C_TB_SCOPE);
    wr (UART_CTRL_RX, CTRL_EN_EVEN or CTRL_FLOW_CTRL, "Enable UART RX with even parity and RTS", clk, sbi_if);
    wr (UART_ISR    , x"FF", "Clear isr (polling)", clk, sbi_if);
    chk(UART_ISR    , x"01", "isr : TX FIFO empty only (RX FIFO empty)", clk, sbi_if);
    chk_bit(rts_b, '0', "RTS# active with an empty RX FIFO");
    for i in POLICY_BYTES'range loop
      uart_send(POLICY_BYTES(i), C_BIT_PERIOD, rx, PARITY_EVEN, i = 1);
      if (policy = "halt") and (i >= 1)
      then
        chk_bit(rts_b, '1', "RTS# inactive while RX is halted, after 0x" & to_hstring(POLICY_BYTES(i)));
      else
        chk_bit(rts_b, '0', "RTS# active after 0x" & to_hstring(POLICY_BYTES(i)));
      end if;
    end loop;
    wait until rising_edge(clk);
    if policy = "halt"
    then
      chk(UART_ISR , x"55", "RX parity error event (0xB2) and RX overrun (0xD4) in isr, RX FIFO not empty", clk, sbi_if);
      chk(UART_DATA, POLICY_BYTES(0), "UART RX 0x" & to_hstring(POLICY_BYTES(0)), clk, sbi_if);
      chk(UART_DATA, POLICY_BYTES(1), "UART RX 0x" & to_hstring(POLICY_BYTES(1)) & " with a parity error", clk, sbi_if);
      wr (UART_ISR , x"0F", "Clear the FIFO state bits (polling)", clk, sbi_if);
      chk(UART_ISR , x"51", "RX FIFO empty after 0x" & to_hstring(POLICY_BYTES(1)) & " (0x" & to_hstring(POLICY_BYTES(2)) & " waits), RX halted", clk, sbi_if);
      chk_bit(rts_b, '1', "RTS# inactive while RX is halted with an empty RX FIFO");
      wr (UART_ISR , x"40", "Clear RX parity error : RX resumes", clk, sbi_if);
      cycles(2, clk);
      chk_bit(rts_b, '0', "RTS# active after the clear of isr[6]");
      chk(UART_DATA, POLICY_BYTES(2), "UART RX 0x" & to_hstring(POLICY_BYTES(2)) & " waiting while RX was halted", clk, sbi_if);
      wr (UART_ISR , x"0F", "Clear the FIFO state bits (polling)", clk, sbi_if);
      chk(UART_ISR , x"11", "RX FIFO empty : 0x" & to_hstring(POLICY_BYTES(3)) & " dropped (overrun), no parity error event", clk, sbi_if);
    else
      chk(UART_ISR, x"45", "RX parity error event (0xB2) in isr, RX FIFO not empty, no overrun", clk, sbi_if);
      for i in POLICY_BYTES'range loop
        if (i /= 1) or (policy = "keep")
        then
          chk(UART_DATA, POLICY_BYTES(i), "UART RX 0x" & to_hstring(POLICY_BYTES(i)), clk, sbi_if);
        end if;
      end loop;
      wr (UART_ISR, x"0F", "Clear the FIFO state bits (polling)", clk, sbi_if);
      chk(UART_ISR, x"41", "RX FIFO empty after 0x" & to_hstring(POLICY_BYTES(3)), clk, sbi_if);
    end if;
    wr (UART_ISR, x"FF", "Clear the old events", clk, sbi_if);
    chk(UART_ISR, x"01", "isr : TX FIFO empty only", clk, sbi_if);

    -- Overrun of a frame with a parity error while a good byte waits for
    -- room in the full RX FIFO (RTS# disabled) : the waiting byte is not
    -- marked with the parity error of the dropped frame (stored in the
    -- three modes). Parity error event of the dropped frame : raised with
    -- "keep" and "drop" (end of the frame), not with "halt" (it never
    -- enters the RX FIFO)
    log(ID_SEQUENCER, "Overrun of a frame with a parity error", C_TB_SCOPE);
    wr(UART_CTRL_RX, CTRL_EN_EVEN, "Enable UART RX with even parity, without RTS", clk, sbi_if);
    for i in 0 to C_DEPTH_RX-1 loop
      uart_send(byte(16#60#+i), C_BIT_PERIOD, rx, PARITY_EVEN);
    end loop;
    uart_send(x"76", C_BIT_PERIOD, rx, PARITY_EVEN);
    uart_send(x"F5", C_BIT_PERIOD, rx, PARITY_EVEN, true);
    wait until rising_edge(clk);
    if policy = "halt"
    then
      chk(UART_ISR, x"1D", "RX overrun (0xF5), no parity error event (RX FIFO full, 0x76 waits)", clk, sbi_if);
    else
      chk(UART_ISR, x"5D", "RX overrun and parity error event (0xF5) (RX FIFO full, 0x76 waits)", clk, sbi_if);
    end if;
    for i in 0 to C_DEPTH_RX-1 loop
      chk(UART_DATA, byte(16#60#+i), "UART RX 0x" & to_hstring(byte(16#60#+i)) & " from the full RX FIFO", clk, sbi_if);
    end loop;
    wr(UART_ISR, x"0F", "Clear the FIFO state bits (polling)", clk, sbi_if);
    if policy = "halt"
    then
      chk(UART_ISR, x"15", "0x76 in the RX FIFO, no parity error event", clk, sbi_if);
    else
      chk(UART_ISR, x"55", "0x76 in the RX FIFO", clk, sbi_if);
    end if;
    chk(UART_DATA, x"76", "UART RX 0x76, waiting during the overrun of 0xF5 with a parity error", clk, sbi_if);
    wr(UART_ISR, x"0F", "Clear the FIFO state bits (polling)", clk, sbi_if);
    if policy = "halt"
    then
      chk(UART_ISR, x"11", "RX FIFO empty after 0x76, RX not halted", clk, sbi_if);
    else
      chk(UART_ISR, x"51", "RX FIFO empty after 0x76", clk, sbi_if);
    end if;
    wr (UART_ISR, x"FF", "Clear the old events", clk, sbi_if);
    chk(UART_ISR, x"01", "isr : TX FIFO empty only", clk, sbi_if);

    -- A byte with a parity error received while the RX FIFO is full, then a
    -- good byte (RTS# disabled) :
    --   "keep" : the byte with the parity error waits for room, the good byte
    --            is an overrun
    --   "drop" : the byte with the parity error is dropped at once, the good
    --            byte waits for room (no overrun)
    --   "halt" : the byte with the parity error waits for room and raises the
    --            parity error event (and halts RX) only when it enters the RX
    --            FIFO : it is the last byte of the RX FIFO. The good byte is
    --            an overrun
    log(ID_SEQUENCER, "Byte with a parity error received while the RX FIFO is full", C_TB_SCOPE);
    for i in 0 to C_DEPTH_RX-1 loop
      uart_send(byte(16#80#+i), C_BIT_PERIOD, rx, PARITY_EVEN);
    end loop;
    uart_send(x"E5", C_BIT_PERIOD, rx, PARITY_EVEN, true);
    uart_send(x"77", C_BIT_PERIOD, rx, PARITY_EVEN);
    wait until rising_edge(clk);
    if policy = "keep"
    then
      chk(UART_ISR , x"5D", "Parity error event (0xE5 waits for room), overrun of 0x77 (RX FIFO full)", clk, sbi_if);
      chk(UART_DATA, x"80", "UART RX 0x80", clk, sbi_if);
    elsif policy = "drop"
    then
      chk(UART_ISR , x"4D", "Parity error event (0xE5 dropped), no overrun : 0x77 waits for room (RX FIFO full)", clk, sbi_if);
      chk(UART_DATA, x"80", "UART RX 0x80", clk, sbi_if);
    else
      chk(UART_ISR , x"1D", "No parity error event while 0xE5 waits (RX FIFO full), overrun of 0x77", clk, sbi_if);
      chk(UART_DATA, x"80", "UART RX 0x80 : room for 0xE5", clk, sbi_if);
      chk(UART_ISR , x"5D", "Parity error event when 0xE5 enters the RX FIFO (RX halted)", clk, sbi_if);
    end if;
    for i in 1 to C_DEPTH_RX-1 loop
      chk(UART_DATA, byte(16#80#+i), "UART RX 0x" & to_hstring(byte(16#80#+i)) & " from the full RX FIFO", clk, sbi_if);
    end loop;
    wr(UART_ISR, x"0F", "Clear the FIFO state bits (polling)", clk, sbi_if);
    if policy = "drop"
    then
      chk(UART_ISR , x"45", "0x77 in the RX FIFO", clk, sbi_if);
      chk(UART_DATA, x"77", "UART RX 0x77, last byte of the RX FIFO", clk, sbi_if);
      wr (UART_ISR , x"0F", "Clear the FIFO state bits (polling)", clk, sbi_if);
      chk(UART_ISR , x"41", "RX FIFO empty after 0x77", clk, sbi_if);
    else
      chk(UART_ISR , x"55", "0xE5 in the RX FIFO", clk, sbi_if);
      chk(UART_DATA, x"E5", "UART RX 0xE5 with a parity error, last byte of the RX FIFO", clk, sbi_if);
      wr (UART_ISR , x"0F", "Clear the FIFO state bits (polling)", clk, sbi_if);
      chk(UART_ISR , x"51", "RX FIFO empty after 0xE5", clk, sbi_if);
    end if;
    if policy = "halt"
    then
      wr (UART_ISR , x"40", "Clear RX parity error : RX resumes", clk, sbi_if);
      uart_send(x"3C", C_BIT_PERIOD, rx, PARITY_EVEN);
      chk(UART_DATA, x"3C", "UART RX 0x3C after the clear of isr[6] (RX resumed)", clk, sbi_if);
    end if;
  end procedure;

end package body tb_UART_parity_policy_pkg;
