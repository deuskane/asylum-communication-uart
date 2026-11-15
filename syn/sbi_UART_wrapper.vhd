-------------------------------------------------------------------------------
-- Title      : sbi_UART_wrapper
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : sbi_UART_wrapper.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description:
-- Wrapper (lint_ghdl, lint_ghdl_synth_*) : sbi_UART with flat and
-- constrained SBI ports (sbi_UART has unconstrained SBI ports and cannot be
-- a synthesis top). SBI address / data width : SBI_ADDR_WIDTH /
-- SBI_DATA_WIDTH. The synthesizable generics are forwarded with the defaults
-- of sbi_UART (configuration of asylum-soc-picosoc). NAME, FILENAME_TX and
-- FILENAME_RX are simulation only, not connected.
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-20  1.0      mrosiere Created
-- 2026-10-24  1.1      mrosiere Was sbi_UART_synth_top, library asylum
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
library asylum;
use     asylum.sbi_pkg.all;
use     asylum.uart_pkg.all;

entity sbi_UART_wrapper is
  generic (
    BAUD_RATE             : integer := 115200;
    CLOCK_FREQ            : integer := 50000000;
    BAUD_TICK_CNT_WIDTH   : integer := 16;
    UART_TX_ENABLE        : boolean := true;
    UART_RX_ENABLE        : boolean := true;
    USER_DEFINE_BAUD_TICK : boolean := true;
    DEPTH_TX              : natural := 0;
    DEPTH_RX              : natural := 0
  );
  port (
    clk_i         : in  std_logic;
    arst_b_i      : in  std_logic;

    -- Bus (SBI)
    cs_i          : in  std_logic;
    re_i          : in  std_logic;
    we_i          : in  std_logic;
    addr_i        : in  std_logic_vector(SBI_ADDR_WIDTH-1 downto 0);
    wdata_i       : in  std_logic_vector(SBI_DATA_WIDTH-1 downto 0);
    ready_o       : out std_logic;
    rdata_o       : out std_logic_vector(SBI_DATA_WIDTH-1 downto 0);

    -- To/From IO
    uart_tx_o     : out std_logic;
    uart_rx_i     : in  std_logic;
    uart_cts_b_i  : in  std_logic;
    uart_rts_b_o  : out std_logic;

    -- Interruption
    it_o          : out std_logic;

    -- Debug
    debug_o       : out uart_debug_t
  );
end entity sbi_UART_wrapper;

architecture rtl of sbi_UART_wrapper is

  signal sbi_ini       : sbi_ini_t(addr (SBI_ADDR_WIDTH-1 downto 0),
                                   wdata(SBI_DATA_WIDTH-1 downto 0));
  signal sbi_tgt       : sbi_tgt_t(rdata(SBI_DATA_WIDTH-1 downto 0));

begin

  sbi_ini.cs        <= cs_i;
  sbi_ini.re        <= re_i;
  sbi_ini.we        <= we_i;
  sbi_ini.addr      <= addr_i;
  sbi_ini.wdata     <= wdata_i;
  ready_o           <= sbi_tgt.ready;
  rdata_o           <= sbi_tgt.rdata;

  ins_sbi_UART : entity asylum.sbi_UART
    generic map (
      BAUD_RATE             => BAUD_RATE,
      CLOCK_FREQ            => CLOCK_FREQ,
      BAUD_TICK_CNT_WIDTH   => BAUD_TICK_CNT_WIDTH,
      UART_TX_ENABLE        => UART_TX_ENABLE,
      UART_RX_ENABLE        => UART_RX_ENABLE,
      USER_DEFINE_BAUD_TICK => USER_DEFINE_BAUD_TICK,
      DEPTH_TX              => DEPTH_TX,
      DEPTH_RX              => DEPTH_RX
    )
    port map (
      clk_i                 => clk_i,
      arst_b_i              => arst_b_i,
      sbi_ini_i             => sbi_ini,
      sbi_tgt_o             => sbi_tgt,
      uart_tx_o             => uart_tx_o,
      uart_rx_i             => uart_rx_i,
      uart_cts_b_i          => uart_cts_b_i,
      uart_rts_b_o          => uart_rts_b_o,
      it_o                  => it_o,
      debug_o               => debug_o
    );

end architecture rtl;
