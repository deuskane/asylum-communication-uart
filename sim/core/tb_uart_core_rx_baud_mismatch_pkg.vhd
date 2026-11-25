-------------------------------------------------------------------------------
-- Title      : tb_uart_core_rx_baud_mismatch_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_uart_core_rx_baud_mismatch_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario rx_baud_mismatch of tb_uart_core
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-25  1.0      mrosiere Created
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library bitvis_vip_uart;
use     bitvis_vip_uart.uart_bfm_pkg.all;

library work;
use     work.tb_uart_core_bfm_pkg.all;

package tb_uart_core_rx_baud_mismatch_pkg is

  -- Baud rate mismatch : for each number of clock cycles per bit of
  -- CYCLES_PER_BIT, the patterns sent back to back with even parity by the
  -- BFM with a bit period 2 % shorter, then 2 % longer than the bit period
  -- of the DUT : every byte received, no parity, framing or overrun error
  procedure run
    (signal   clk      : in    std_logic
    ;signal   tb_req   : inout tb_req_t
    ;signal   tb_rsp   : in    tb_rsp_t
    );

end package tb_uart_core_rx_baud_mismatch_pkg;

package body tb_uart_core_rx_baud_mismatch_pkg is

  procedure run
    (signal   clk      : in    std_logic
    ;signal   tb_req   : inout tb_req_t
    ;signal   tb_rsp   : in    tb_rsp_t
    ) is
    type     real_array_t is array (natural range <>) of real;
    -- Bit period of the BFM / bit period of the DUT
    constant C_RATIOS  : real_array_t := (0.98, 1.02);
    variable v_n       : natural;   -- Clock cycles per bit
    variable v_nb_rx   : natural;   -- Bytes taken before the burst
  begin
    for c in CYCLES_PER_BIT'range loop
      v_n := CYCLES_PER_BIT(c);
      set_cycles(v_n, clk, tb_req);
      set_rx    ('1', PARITY_EVEN, clk, tb_req);
      -- Every byte taken as soon as it is received
      tb_req.m_tready <= '1';

      for r in C_RATIOS'range loop
        log(ID_SEQUENCER, integer'image(v_n) & " clock cycles per bit, BFM bit period x " & to_string(C_RATIOS(r), 2), C_TB_SCOPE);
        v_nb_rx := tb_rsp.nb_rx;
        for i in PATTERNS'range loop
          uart_send(PATTERNS(i), PARITY_EVEN, tb_req, bit_ratio => C_RATIOS(r));
        end loop;
        wait for 2 * v_n * C_CLK_PERIOD;

        chk_nb(tb_rsp.nb_rx, v_nb_rx + PATTERNS'length, integer'image(v_n) & " cycles per bit, BFM bit period x " & to_string(C_RATIOS(r), 2) & " : bytes received");
        for i in PATTERNS'range loop
          check_value(tb_rsp.rx_bytes((v_nb_rx+i) mod tb_rsp.rx_bytes'length), PATTERNS(i), error, integer'image(v_n) & " cycles per bit, BFM bit period x " & to_string(C_RATIOS(r), 2) & " : byte " & integer'image(i), C_TB_SCOPE);
        end loop;
        chk_nb(tb_rsp.nb_parity , 0, integer'image(v_n) & " cycles per bit, BFM bit period x " & to_string(C_RATIOS(r), 2) & " : no parity error");
        chk_nb(tb_rsp.nb_framing, 0, integer'image(v_n) & " cycles per bit, BFM bit period x " & to_string(C_RATIOS(r), 2) & " : no framing error");
        chk_nb(tb_rsp.nb_overrun, 0, integer'image(v_n) & " cycles per bit, BFM bit period x " & to_string(C_RATIOS(r), 2) & " : no overrun");
      end loop;

      tb_req.m_tready <= '0';
    end loop;
  end procedure;

end package body tb_uart_core_rx_baud_mismatch_pkg;
