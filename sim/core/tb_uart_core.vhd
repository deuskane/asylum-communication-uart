-------------------------------------------------------------------------------
-- Title      : tb_uart_core
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_uart_core.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: UVVM self-checking testbench of uart_core (50 MHz clock).
--              The scenarios drive the inputs (tb_req) and read the outputs
--              (tb_rsp) ; frames on the pads with the UVVM UART BFM,
--              uart_rx_i looped back to uart_tx_o on request. Each pulse of
--              err_*_o is counted and each byte taken on m_axis is kept
--              (tb_rsp.nb_*, tb_rsp.rx_bytes, cleared by the reset).
--              TESTS_LIST           : scenarios run in sequence, separated
--                                     by ',' (tb_uart_core_tests_pkg), each
--                                     one after a reset pulse ; "" : build
--                                     and elaboration only
--              TX_ENABLE, RX_ENABLE : generics of the DUT
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-23  1.0      mrosiere Created
-- 2026-11-25  1.1      mrosiere Bytes taken on m_axis kept (nb_rx, rx_bytes)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
use     asylum.string_pkg.all;
use     asylum.uart_pkg.all;

library work;
use     work.tb_uart_core_bfm_pkg.all;
use     work.tb_uart_core_tests_pkg.all;

entity tb_uart_core is
  generic (
    TESTS_LIST       : string  := ""      -- Scenarios, e.g. "tx,rx"
   ;TX_ENABLE        : boolean := true    -- Generic of the DUT
   ;RX_ENABLE        : boolean := true    -- Generic of the DUT
  );
end entity tb_uart_core;

architecture sim of tb_uart_core is

  constant C_SCOPE         : string  := "TB_UART_CORE";

  signal   clk_i           : std_logic := '0';
  signal   clk_ena         : boolean   := true;
  signal   arst_b_i        : std_logic := '0';

  signal   cnt_max         : std_logic_vector(16-1 downto 0);
  signal   uart_rx         : std_logic;

  signal   tb_req          : tb_req_t  := C_TB_REQ_IDLE;
  signal   tb_rsp          : tb_rsp_t;

begin

  clock_generator(clk_i, clk_ena, C_CLK_PERIOD, "TB Clock");

  -----------------------------------------------------------------------------
  -- DUT
  -----------------------------------------------------------------------------
  dut : uart_core
    generic map
    (TX_ENABLE               => TX_ENABLE
    ,RX_ENABLE               => RX_ENABLE
    ,WIDTH                   => 8
    ,BAUD_TICK_CNT_WIDTH     => 16
    )
    port map
    (clk_i                   => clk_i
    ,arst_b_i                => arst_b_i
    ,cfg_baud_tick_cnt_max_i => cnt_max
    ,cfg_tx_enable_i         => tb_req.tx_enable
    ,cfg_tx_parity_enable_i  => tb_req.tx_parity_enable
    ,cfg_tx_parity_odd_i     => tb_req.tx_parity_odd
    ,cfg_rx_enable_i         => tb_req.rx_enable
    ,cfg_rx_parity_enable_i  => tb_req.rx_parity_enable
    ,cfg_rx_parity_odd_i     => tb_req.rx_parity_odd
    ,s_axis_tdata_i          => tb_req.s_tdata
    ,s_axis_tvalid_i         => tb_req.s_tvalid
    ,s_axis_tready_o         => tb_rsp.s_tready
    ,uart_tx_o               => tb_rsp.tx
    ,uart_cts_b_i            => tb_req.cts_b
    ,uart_rx_i               => uart_rx
    ,m_axis_tdata_o          => tb_rsp.m_tdata
    ,m_axis_parity_error_o   => tb_rsp.m_parity_error
    ,m_axis_tvalid_o         => tb_rsp.m_tvalid
    ,m_axis_tready_i         => tb_req.m_tready
    ,err_overrun_o           => tb_rsp.err_overrun
    ,err_parity_o            => tb_rsp.err_parity
    ,err_framing_o           => tb_rsp.err_framing
    ,err_break_o             => tb_rsp.err_break
    ,debug_o                 => tb_rsp.debug
    );

  cnt_max <= std_logic_vector(to_unsigned(tb_req.cnt_max, 16));
  uart_rx <= tb_rsp.tx when tb_req.loopback else
             tb_req.rx;

  -----------------------------------------------------------------------------
  -- Error pulses and bytes taken on m_axis since the reset
  -----------------------------------------------------------------------------
  p_errors : process (clk_i, arst_b_i) is
  begin
    if arst_b_i = '0'
    then
      tb_rsp.nb_overrun <= 0;
      tb_rsp.nb_parity  <= 0;
      tb_rsp.nb_framing <= 0;
      tb_rsp.nb_break   <= 0;
      tb_rsp.nb_rx      <= 0;
      tb_rsp.rx_bytes   <= (others => (others => '0'));
    elsif rising_edge(clk_i)
    then
      if tb_rsp.err_overrun = '1' then tb_rsp.nb_overrun <= tb_rsp.nb_overrun + 1; end if;
      if tb_rsp.err_parity  = '1' then tb_rsp.nb_parity  <= tb_rsp.nb_parity  + 1; end if;
      if tb_rsp.err_framing = '1' then tb_rsp.nb_framing <= tb_rsp.nb_framing + 1; end if;
      if tb_rsp.err_break   = '1' then tb_rsp.nb_break   <= tb_rsp.nb_break   + 1; end if;
      if tb_rsp.m_tvalid = '1' and tb_req.m_tready = '1'
      then
        tb_rsp.rx_bytes(tb_rsp.nb_rx mod tb_rsp.rx_bytes'length) <= tb_rsp.m_tdata;
        tb_rsp.nb_rx      <= tb_rsp.nb_rx + 1;
      end if;
    end if;
  end process p_errors;

  -----------------------------------------------------------------------------
  -- Sequencer
  -----------------------------------------------------------------------------
  p_sequencer : process
  begin
    log(ID_LOG_HDR, "TX_ENABLE = " & boolean'image(TX_ENABLE) & ", RX_ENABLE = " & boolean'image(RX_ENABLE) & ", TESTS_LIST : " & TESTS_LIST, C_SCOPE);

    -- Every name is checked before the first scenario
    for i in 1 to list_length(TESTS_LIST) loop
      if not list_contains(C_TESTS, list_item(TESTS_LIST, i))
      then
        alert(TB_ERROR, "Unknown test """ & list_item(TESTS_LIST, i) & """ (tests : " & C_TESTS & ")", C_SCOPE);
      end if;
    end loop;

    for i in 1 to list_length(TESTS_LIST) loop
      -- Reset pulse, inputs idle : each scenario starts from reset
      tb_req <= C_TB_REQ_IDLE;
      do_reset(clk_i, arst_b_i);

      log(ID_LOG_HDR, "TEST " & integer'image(i) & "/" & integer'image(list_length(TESTS_LIST)) & " : " & list_item(TESTS_LIST, i), C_SCOPE);
      run_test(list_item(TESTS_LIST, i), TX_ENABLE, RX_ENABLE, clk_i, tb_req, tb_rsp);
    end loop;

    report_alert_counters(FINAL);
    std.env.stop;
    wait;
  end process p_sequencer;

end architecture sim;
