-------------------------------------------------------------------------------
-- Title      : tb_uart_core_rx_sampling_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_uart_core_rx_sampling_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Scenario rx_sampling of tb_uart_core
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

package tb_uart_core_rx_sampling_pkg is

  -- Sampling point of the receiver in the middle of each bit, for each
  -- number of clock cycles per bit N of CYCLES_PER_BIT : every bit of the
  -- frame (start, 8 data bits 0xFF, odd parity, stop) is cut in turn (at 0
  -- during its first cut clock cycles, then at 1, uart_send_cut) :
  -- * cut (N-1)/2 : sampled after the cut, the bit is read at 1 (a cut start
  --   bit is a glitch : no byte) ;
  -- * cut (N+2)/2 : sampled in the cut, the bit is read at 0 (data bit at 0
  --   and parity error, parity error, framing error).
  -- The bits start on a falling edge of the clock : each bit is sampled
  -- between N/2 - 1/2 and N/2 + 1 clock cycles after its start.
  procedure run
    (signal   clk      : in    std_logic
    ;signal   tb_req   : inout tb_req_t
    ;signal   tb_rsp   : in    tb_rsp_t
    );

end package tb_uart_core_rx_sampling_pkg;

package body tb_uart_core_rx_sampling_pkg is

  -- Name of bit b of the frame
  function bit_name
    (constant b        : in    natural
    ) return string is
  begin
    case b is
      when 0      => return "start bit";
      when 9      => return "parity bit";
      when 10     => return "stop bit";
      when others => return "data bit " & integer'image(b-1);
    end case;
  end function;

  procedure run
    (signal   clk      : in    std_logic
    ;signal   tb_req   : inout tb_req_t
    ;signal   tb_rsp   : in    tb_rsp_t
    ) is
    variable v_n       : natural;   -- Clock cycles per bit
    variable v_cut     : natural;   -- Clock cycles of the cut bit at 0
    variable v_data    : byte_t;    -- Expected byte
    variable v_par_err : std_logic; -- Expected parity error
    variable v_framing : natural;   -- Expected framing errors
  begin
    v_framing := 0;
    for c in CYCLES_PER_BIT'range loop
      v_n := CYCLES_PER_BIT(c);
      log(ID_SEQUENCER, integer'image(v_n) & " clock cycles per bit", C_TB_SCOPE);
      set_cycles(v_n, clk, tb_req);
      set_rx    ('1', PARITY_ODD, clk, tb_req);

      for b in 0 to 10 loop
        for long in false to true loop
          -- Cut shorter than the sampling point : bit read at 1, then
          -- longer : bit read at 0
          if long
          then
            v_cut := (v_n+2)/2;
          else
            v_cut := (v_n-1)/2;
          end if;
          v_data    := x"FF";
          v_par_err := '0';
          if long and b >= 1 and b <= 8
          then
            v_data(b-1) := '0';
            v_par_err   := '1';
          elsif long and b = 9
          then
            v_par_err   := '1';
          elsif long and b = 10
          then
            v_framing   := v_framing + 1;
          end if;

          uart_send_cut(b, v_cut, clk, tb_req);

          if b = 0 and not long
          then
            chk_bit(tb_rsp.m_tvalid, '0', integer'image(v_n) & " cycles per bit, start bit at 0 during " & integer'image(v_cut) & " cycles : false start, no byte");
          else
            axis_expect(v_data, v_par_err, integer'image(v_n) & " cycles per bit, " & bit_name(b) & " at 0 during " & integer'image(v_cut) & " cycles", tb_req, tb_rsp, clk);
          end if;
          if b = 10
          then
            chk_nb(tb_rsp.nb_framing, v_framing, integer'image(v_n) & " cycles per bit, stop bit at 0 during " & integer'image(v_cut) & " cycles : framing errors");
          end if;
        end loop;
      end loop;
    end loop;
  end procedure;

end package body tb_uart_core_rx_sampling_pkg;
