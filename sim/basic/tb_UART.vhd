-------------------------------------------------------------------------------
-- Title      : tb_UART
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_UART.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: UVVM/SBI self-checking testbench of sbi_UART (FIFO depths
--              16, 115200 baud at 50 MHz).
--              TESTS_LIST      : scenarios run in sequence, separated by
--                                ',' (tb_UART_tests_pkg), each one after a
--                                reset pulse ; "" : build and elaboration
--                                only
--              RX_PARITY_ERROR : generic of the DUT, policy on a byte
--                                received with a parity error ("keep",
--                                "drop" or "halt")
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-05  1.1      mrosiere Add parity tests (RX BFM, TX monitor,
--                               internal loopback) and parity error check
-- 2026-11-16  1.2      mrosiere isr source 0 = TX FIFO empty, isr polling
--                               (clear then read back to back)
-- 2026-11-16  1.3      mrosiere RX overrun interrupt and RTS# threshold
-- 2026-11-16  1.4      mrosiere RX framing error, break and parity error
--                               interrupts
-- 2026-11-16  1.5      mrosiere Generic RX_PARITY_ERROR : a byte with a
--                               parity error is checked stored ("keep"),
--                               dropped ("drop"), or stored with RX halted
--                               until isr[6] is cleared ("halt")
-- 2026-11-16  1.6      mrosiere Echo mode (ctrl_tx.tx_use_loopback)
-- 2026-11-17  1.7      mrosiere Test 16 : parity error policy (RTS#, overrun
--                               of a frame with a parity error, byte with a
--                               parity error waiting for a full RX FIFO)
-- 2026-11-20  2.0      mrosiere TESTS_LIST, one package per scenario
--                               (tb_UART_<name>_pkg), helpers in
--                               tb_UART_bfm_pkg, reset pulse before each
--                               scenario, scenarios reset_values and baud
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library bitvis_vip_sbi;
use     bitvis_vip_sbi.sbi_bfm_pkg.all;

library asylum;
use     asylum.sbi_pkg.all;
use     asylum.string_pkg.all;
use     asylum.uart_pkg.all;
use     asylum.UART_csr_pkg.all;

library work;
use     work.tb_UART_bfm_pkg.all;
use     work.tb_UART_tests_pkg.all;

entity tb_UART is
  generic (
    TESTS_LIST       : string  := ""      -- Scenarios, e.g. "rx,tx"
   ;RX_PARITY_ERROR  : string  := "keep"  -- "keep", "drop" or "halt"
  );
end entity tb_UART;

architecture sim of tb_UART is

  constant C_SCOPE         : string  := "TB_UART";

  signal   clk_i           : std_logic := '0';
  signal   clk_ena         : boolean   := true;
  signal   arst_b_i        : std_logic := '0';

  signal   sbi_ini         : sbi_ini_t(addr (UART_ADDR_WIDTH-1 downto 0),
                                       wdata(UART_DATA_WIDTH-1 downto 0));
  signal   sbi_tgt         : sbi_tgt_t(rdata(UART_DATA_WIDTH-1 downto 0));
  signal   sbi_if          : t_sbi_if (addr (UART_ADDR_WIDTH-1 downto 0),
                                       wdata(UART_DATA_WIDTH-1 downto 0),
                                       rdata(UART_DATA_WIDTH-1 downto 0));

  signal   uart_tx         : std_logic;
  signal   uart_rx         : std_logic := '1';
  signal   uart_cts_b      : std_logic := '0';
  signal   uart_rts_b      : std_logic;
  signal   it              : std_logic;
  signal   debug           : uart_debug_t;

begin

  clock_generator(clk_i, clk_ena, C_CLK_PERIOD, "TB Clock");

  -----------------------------------------------------------------------------
  -- DUT
  -----------------------------------------------------------------------------
  dut : sbi_UART
    generic map
    (NAME            => "UART"
    ,BAUD_RATE       => C_BAUD_RATE
    ,CLOCK_FREQ      => C_CLOCK_FREQ
    ,DEPTH_TX        => C_DEPTH_TX
    ,DEPTH_RX        => C_DEPTH_RX
    ,RX_PARITY_ERROR => RX_PARITY_ERROR
    )
    port map
    (clk_i           => clk_i
    ,arst_b_i        => arst_b_i
    ,sbi_ini_i       => sbi_ini
    ,sbi_tgt_o       => sbi_tgt
    ,uart_tx_o       => uart_tx
    ,uart_rx_i       => uart_rx
    ,uart_cts_b_i    => uart_cts_b
    ,uart_rts_b_o    => uart_rts_b
    ,it_o            => it
    ,debug_o         => debug
    );

  sbi_ini.cs    <= sbi_if.cs;
  sbi_ini.addr  <= std_logic_vector(sbi_if.addr);
  sbi_ini.re    <= sbi_if.rena;
  sbi_ini.we    <= sbi_if.wena;
  sbi_ini.wdata <= sbi_if.wdata;
  sbi_if.ready  <= sbi_tgt.ready;
  sbi_if.rdata  <= sbi_tgt.rdata;

  -----------------------------------------------------------------------------
  -- Sequencer
  -----------------------------------------------------------------------------
  p_sequencer : process
  begin
    log(ID_LOG_HDR, "RX_PARITY_ERROR = " & RX_PARITY_ERROR & ", TESTS_LIST : " & TESTS_LIST, C_SCOPE);

    -- Every name is checked before the first scenario
    for i in 1 to list_length(TESTS_LIST) loop
      if not list_contains(C_TESTS, list_item(TESTS_LIST, i))
      then
        alert(TB_ERROR, "Unknown test """ & list_item(TESTS_LIST, i) & """ (tests : " & C_TESTS & ")", C_SCOPE);
      end if;
    end loop;

    for i in 1 to list_length(TESTS_LIST) loop
      -- Reset pulse, bus inactive, lines idle and CTS# active : each
      -- scenario starts from reset
      sbi_if     <= init_sbi_if_signals(UART_ADDR_WIDTH, UART_DATA_WIDTH);
      uart_rx    <= '1';
      uart_cts_b <= '0';
      do_reset(clk_i, arst_b_i);

      log(ID_LOG_HDR, "TEST " & integer'image(i) & "/" & integer'image(list_length(TESTS_LIST)) & " : " & list_item(TESTS_LIST, i), C_SCOPE);
      run_test(list_item(TESTS_LIST, i), RX_PARITY_ERROR, clk_i, sbi_if, uart_rx, uart_tx, uart_cts_b, uart_rts_b, it, debug.uart_rx.parity_error);
    end loop;

    report_alert_counters(FINAL);
    std.env.stop;
    wait;
  end process p_sequencer;

end architecture sim;
