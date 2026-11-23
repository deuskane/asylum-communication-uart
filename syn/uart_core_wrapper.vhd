-------------------------------------------------------------------------------
-- Title      : uart_core_wrapper
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : uart_core_wrapper.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description:
-- Wrapper (lint_ghdl_synth_core*, syn_core*) : uart_core, 8 data bits,
-- 16-bit baud tick counter, TX_ENABLE / RX_ENABLE given by the target.
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-23  1.0      mrosiere Created
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
library asylum;
use     asylum.uart_pkg.all;

entity uart_core_wrapper is
  generic (
    TX_ENABLE               : boolean := true
   ;RX_ENABLE               : boolean := true
  );
  port (
    clk_i                   : in  std_logic
   ;arst_b_i                : in  std_logic

    -- Configuration
   ;cfg_baud_tick_cnt_max_i : in  std_logic_vector(16-1 downto 0)
   ;cfg_tx_enable_i         : in  std_logic
   ;cfg_tx_parity_enable_i  : in  std_logic
   ;cfg_tx_parity_odd_i     : in  std_logic
   ;cfg_rx_enable_i         : in  std_logic
   ;cfg_rx_parity_enable_i  : in  std_logic
   ;cfg_rx_parity_odd_i     : in  std_logic

    -- TX
   ;s_axis_tdata_i          : in  std_logic_vector(8-1 downto 0)
   ;s_axis_tvalid_i         : in  std_logic
   ;s_axis_tready_o         : out std_logic
   ;uart_tx_o               : out std_logic
   ;uart_cts_b_i            : in  std_logic

    -- RX
   ;uart_rx_i               : in  std_logic
   ;m_axis_tdata_o          : out std_logic_vector(8-1 downto 0)
   ;m_axis_parity_error_o   : out std_logic
   ;m_axis_tvalid_o         : out std_logic
   ;m_axis_tready_i         : in  std_logic
   ;err_overrun_o           : out std_logic
   ;err_parity_o            : out std_logic
   ;err_framing_o           : out std_logic
   ;err_break_o             : out std_logic

    -- Debug
   ;debug_o                 : out uart_debug_t
  );
end entity uart_core_wrapper;

architecture rtl of uart_core_wrapper is

begin

  ins_uart_core : entity asylum.uart_core
    generic map
    (TX_ENABLE               => TX_ENABLE
    ,RX_ENABLE               => RX_ENABLE
    ,WIDTH                   => 8
    ,BAUD_TICK_CNT_WIDTH     => 16
    )
    port map
    (clk_i                   => clk_i
    ,arst_b_i                => arst_b_i
    ,cfg_baud_tick_cnt_max_i => cfg_baud_tick_cnt_max_i
    ,cfg_tx_enable_i         => cfg_tx_enable_i
    ,cfg_tx_parity_enable_i  => cfg_tx_parity_enable_i
    ,cfg_tx_parity_odd_i     => cfg_tx_parity_odd_i
    ,cfg_rx_enable_i         => cfg_rx_enable_i
    ,cfg_rx_parity_enable_i  => cfg_rx_parity_enable_i
    ,cfg_rx_parity_odd_i     => cfg_rx_parity_odd_i
    ,s_axis_tdata_i          => s_axis_tdata_i
    ,s_axis_tvalid_i         => s_axis_tvalid_i
    ,s_axis_tready_o         => s_axis_tready_o
    ,uart_tx_o               => uart_tx_o
    ,uart_cts_b_i            => uart_cts_b_i
    ,uart_rx_i               => uart_rx_i
    ,m_axis_tdata_o          => m_axis_tdata_o
    ,m_axis_parity_error_o   => m_axis_parity_error_o
    ,m_axis_tvalid_o         => m_axis_tvalid_o
    ,m_axis_tready_i         => m_axis_tready_i
    ,err_overrun_o           => err_overrun_o
    ,err_parity_o            => err_parity_o
    ,err_framing_o           => err_framing_o
    ,err_break_o             => err_break_o
    ,debug_o                 => debug_o
    );

end architecture rtl;
