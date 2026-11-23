-------------------------------------------------------------------------------
-- Title      : uart_core
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : uart_core.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2026-11-23
-- Last update: 2026-11-23
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: UART without registers : transmitter (uart_tx_axis) and
--              receiver (uart_rx_axis), each with its own baud rate
--              generator (uart_baud_rate_gen).
--              TX_ENABLE / RX_ENABLE = false : no logic for that direction,
--              its outputs are constants :
--              TX : uart_tx_o = '1' (idle line), s_axis_tready_o = '1' (the
--                   bytes are dropped : a producer never blocks),
--                   debug_o.uart_tx = 0
--              RX : m_axis_tvalid_o = '0', m_axis_tdata_o = 0,
--                   m_axis_parity_error_o = '0', err_*_o = '0',
--                   debug_o.uart_rx = 0
--              uart_rx_i and uart_cts_b_i are asynchronous : each one is
--              synchronized (sync2dffrn, 2 clock cycles) when its direction
--              exists (RX : uart_rx_i, TX : uart_cts_b_i).
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-23  1.0      mrosiere Created
-------------------------------------------------------------------------------

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;

library asylum;
use     asylum.uart_pkg.ALL;
use     asylum.techmap_pkg.ALL;

entity uart_core is
  generic (
    TX_ENABLE               : boolean := true  -- Transmitter instantiated
   ;RX_ENABLE               : boolean := true  -- Receiver    instantiated
   ;WIDTH                   : natural := 8     -- Data width
   ;BAUD_TICK_CNT_WIDTH     : natural := 16    -- Width of cfg_baud_tick_cnt_max_i
  );
  port (
    -- Clock and Reset
    clk_i                   : in  std_logic
   ;arst_b_i                : in  std_logic
    -- Configuration
   ;cfg_baud_tick_cnt_max_i : in  std_logic_vector(BAUD_TICK_CNT_WIDTH-1 downto 0) -- Clock cycles per bit - 1 (TX and RX)
   ;cfg_tx_enable_i         : in  std_logic  -- 0 : TX held in reset
   ;cfg_tx_parity_enable_i  : in  std_logic  -- 1 : TX sends a parity bit
   ;cfg_tx_parity_odd_i     : in  std_logic  -- 0 : even, 1 : odd parity
   ;cfg_rx_enable_i         : in  std_logic  -- 0 : RX held in reset
   ;cfg_rx_parity_enable_i  : in  std_logic  -- 1 : RX expects a parity bit
   ;cfg_rx_parity_odd_i     : in  std_logic  -- 0 : even, 1 : odd parity
    -- TX : AXI-Stream input
   ;s_axis_tdata_i          : in  std_logic_vector(WIDTH-1 downto 0)
   ;s_axis_tvalid_i         : in  std_logic
   ;s_axis_tready_o         : out std_logic
    -- TX : To IO
   ;uart_tx_o               : out std_logic
   ;uart_cts_b_i            : in  std_logic  -- Clear To Send (active low), asynchronous
    -- RX : From IO
   ;uart_rx_i               : in  std_logic  -- Asynchronous
    -- RX : AXI-Stream output
   ;m_axis_tdata_o          : out std_logic_vector(WIDTH-1 downto 0)
   ;m_axis_parity_error_o   : out std_logic  -- Parity error of m_axis_tdata_o
   ;m_axis_tvalid_o         : out std_logic
   ;m_axis_tready_i         : in  std_logic
    -- RX : errors, one clock cycle pulses at the end of a frame
   ;err_overrun_o           : out std_logic  -- Byte still pending : new byte dropped
   ;err_parity_o            : out std_logic  -- Parity bit mismatch
   ;err_framing_o           : out std_logic  -- Stop bit sampled at 0
   ;err_break_o             : out std_logic  -- All bits of the frame at 0
    -- Debug
   ;debug_o                 : out uart_debug_t
  );
end entity uart_core;

architecture rtl of uart_core is

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- UART TX
  -----------------------------------------------------------------------------
  gen_tx: if TX_ENABLE = true
  generate
    signal   tx_arst_b         : std_logic;
    signal   tx_baud_tick      : std_logic;
    signal   uart_cts_b_sync   : std_logic;
  begin
    -- CTS# is asynchronous : synchronized before the transmitter (reset
    -- value '0' : CTS# active)
    ins_uart_cts_b_sync : sync2dffrn
      port map
      (clk_i                   => clk_i
      ,arst_b_i                => arst_b_i
      ,d_i                     => uart_cts_b_i
      ,q_o                     => uart_cts_b_sync
      );

    -- cfg_tx_enable_i = 0 holds the transmitter in reset
    tx_arst_b <= arst_b_i and cfg_tx_enable_i;

    -- Free running : the transmitter starts a bit on each tick
    ins_uart_tx_baud_rate_gen : uart_baud_rate_gen
      generic map
      (BAUD_TICK_CNT_WIDTH     => BAUD_TICK_CNT_WIDTH
      )
      port map
      (clk_i                   => clk_i
      ,arst_b_i                => tx_arst_b
      ,baud_tick_en_i          => '1'
      ,baud_tick_o             => tx_baud_tick
      ,baud_tick_half_o        => open
      ,cfg_baud_tick_cnt_max_i => cfg_baud_tick_cnt_max_i
      );

    ins_uart_tx_axis : uart_tx_axis
      generic map
      (WIDTH                   => WIDTH
      )
      port map
      (clk_i                   => clk_i
      ,arst_b_i                => tx_arst_b
      ,s_axis_tdata_i          => s_axis_tdata_i
      ,s_axis_tvalid_i         => s_axis_tvalid_i
      ,s_axis_tready_o         => s_axis_tready_o
      ,uart_tx_o               => uart_tx_o
      ,uart_cts_b_i            => uart_cts_b_sync
      ,baud_tick_i             => tx_baud_tick
      ,parity_enable_i         => cfg_tx_parity_enable_i
      ,parity_odd_i            => cfg_tx_parity_odd_i
      ,debug_o                 => debug_o.uart_tx
      );
  end generate gen_tx;

  gen_tx_b: if TX_ENABLE = false
  generate
    s_axis_tready_o            <= '1'; -- Bytes dropped
    uart_tx_o                  <= '1'; -- Idle line
    debug_o.uart_tx.state      <= '0';
  end generate gen_tx_b;

  -----------------------------------------------------------------------------
  -- UART RX
  -----------------------------------------------------------------------------
  gen_rx: if RX_ENABLE = true
  generate
    signal   rx_arst_b         : std_logic;
    signal   rx_baud_tick_en   : std_logic;
    signal   rx_baud_tick      : std_logic;
    signal   rx_baud_tick_half : std_logic;
    signal   uart_rx_b         : std_logic;
    signal   uart_rx_b_sync    : std_logic;
    signal   uart_rx_sync      : std_logic;
  begin
    -- RX is asynchronous : synchronized before the receiver FSM.
    -- sync2dffrn is reset to '0', so the inverted line is synchronized
    -- to have the idle level ('1') on uart_rx_sync during reset
    uart_rx_b    <= not uart_rx_i;

    ins_uart_rx_b_sync : sync2dffrn
      port map
      (clk_i                   => clk_i
      ,arst_b_i                => arst_b_i
      ,d_i                     => uart_rx_b
      ,q_o                     => uart_rx_b_sync
      );

    uart_rx_sync <= not uart_rx_b_sync;

    -- cfg_rx_enable_i = 0 holds the receiver in reset
    rx_arst_b <= arst_b_i and cfg_rx_enable_i;

    -- Restarted on each start bit (baud_tick_en_o of uart_rx_axis) : the
    -- half tick is the middle of each bit
    ins_uart_rx_baud_rate_gen : uart_baud_rate_gen
      generic map
      (BAUD_TICK_CNT_WIDTH     => BAUD_TICK_CNT_WIDTH
      )
      port map
      (clk_i                   => clk_i
      ,arst_b_i                => rx_arst_b
      ,baud_tick_en_i          => rx_baud_tick_en
      ,baud_tick_o             => rx_baud_tick
      ,baud_tick_half_o        => rx_baud_tick_half
      ,cfg_baud_tick_cnt_max_i => cfg_baud_tick_cnt_max_i
      );

    ins_uart_rx_axis : uart_rx_axis
      generic map
      (WIDTH                   => WIDTH
      )
      port map
      (clk_i                   => clk_i
      ,arst_b_i                => rx_arst_b
      ,uart_rx_i               => uart_rx_sync
      ,m_axis_tdata_o          => m_axis_tdata_o
      ,m_axis_parity_error_o   => m_axis_parity_error_o
      ,m_axis_tvalid_o         => m_axis_tvalid_o
      ,m_axis_tready_i         => m_axis_tready_i
      ,baud_tick_i             => rx_baud_tick
      ,baud_tick_half_i        => rx_baud_tick_half
      ,baud_tick_en_o          => rx_baud_tick_en
      ,parity_enable_i         => cfg_rx_parity_enable_i
      ,parity_odd_i            => cfg_rx_parity_odd_i
      ,last_parity_error_o     => open -- On debug_o.uart_rx.parity_error
      ,err_overrun_o           => err_overrun_o
      ,err_parity_o            => err_parity_o
      ,err_framing_o           => err_framing_o
      ,err_break_o             => err_break_o
      ,debug_o                 => debug_o.uart_rx
      );
  end generate gen_rx;

  gen_rx_b: if RX_ENABLE = false
  generate
    m_axis_tdata_o                 <= (others => '0');
    m_axis_parity_error_o          <= '0';
    m_axis_tvalid_o                <= '0';
    err_overrun_o                  <= '0';
    err_parity_o                   <= '0';
    err_framing_o                  <= '0';
    err_break_o                    <= '0';
    debug_o.uart_rx.state          <= (others => '0');
    debug_o.uart_rx.bit_cnt        <= (others => '0');
    debug_o.uart_rx.baud_tick_half <= '0';
    debug_o.uart_rx.parity_error   <= '0';
  end generate gen_rx_b;

end architecture rtl;
