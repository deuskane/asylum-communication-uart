-------------------------------------------------------------------------------
-- Title      : pbi_UART
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : pbi_UART.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2025-01-21
-- Last update: 2025-01-29
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2017
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2025-01-21  0.1      rosiere	Created
-------------------------------------------------------------------------------

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.numeric_std.ALL;

use     work.pbi_pkg.all;

entity pbi_UART is
  generic (
    BAUD_RATE           : integer := 115200;
    CLOCK_FREQ          : integer := 50000000;
    BAUD_TICK_CNT_WIDTH : integer := 16;
    ID                  : std_logic_vector (PBI_ADDR_WIDTH-1 downto 0) := (others => '0')
    );
  port   (
    clk_i            : in  std_logic;
    arst_b_i         : in  std_logic; -- asynchronous reset

    -- Bus
    pbi_ini_i        : in  pbi_ini_t;
    pbi_tgt_o        : out pbi_tgt_t;
    
    -- To/From IO
    uart_tx_o        : out std_logic;
    uart_rx_i        : in  std_logic
    );

end entity pbi_UART;

architecture rtl of pbi_UART is
  constant SIZE_ADDR_IP : natural := 2;
  
  signal ip_cs               : std_logic;
  signal ip_re               : std_logic;
  signal ip_we               : std_logic;
  signal ip_addr             : std_logic_vector (SIZE_ADDR_IP-1   downto 0);
  signal ip_wdata            : std_logic_vector (PBI_DATA_WIDTH-1 downto 0);
  signal ip_rdata            : std_logic_vector (PBI_DATA_WIDTH-1 downto 0);
  signal ip_busy             : std_logic;

  signal uart_baud_tick      : std_logic;

  signal s_axis_tvalid       : std_logic;
  signal s_axis_tready       : std_logic;
  signal s_axis_tdata        : std_logic_vector(8-1 downto 0);

begin  -- architecture rtl
    
  ins_pbi_wrapper_target : entity work.pbi_wrapper_target(rtl)
  generic map(
    SIZE_DATA      => PBI_DATA_WIDTH,
    SIZE_ADDR_IP   => SIZE_ADDR_IP  ,
    ID             => ID
     )
  port map(
    clk_i          => clk_i         ,
    cke_i          => '1'           ,
    arstn_i        => arst_b_i      ,
    ip_cs_o        => ip_cs         ,
    ip_re_o        => ip_re         ,
    ip_we_o        => ip_we         ,
    ip_addr_o      => ip_addr       ,
    ip_wdata_o     => ip_wdata      ,
    ip_rdata_i     => ip_rdata      ,
    ip_busy_i      => ip_busy       ,
    pbi_ini_i      => pbi_ini_i     ,
    pbi_tgt_o      => pbi_tgt_o     
    );

  ins_uart_baud_rate_gen : entity work.uart_baud_rate_gen(rtl)
    generic map(
      BAUD_RATE      => BAUD_RATE,
      CLOCK_FREQ     => CLOCK_FREQ
      )
    port map(
      clk_i            => clk_i   ,
      arst_b_i         => arst_b_i,
      baud_tick_en_i   => '1',
      baud_tick_o      => uart_baud_tick,
      baud_tick_half_o => open
      );

  s_axis_tvalid <= ip_cs and ip_we;
  s_axis_tdata  <= ip_wdata;
  ip_busy       <= not s_axis_tready;
  
  ins_uart_tx_axis : entity work.uart_tx_axis(rtl)
    generic map
    ( WIDTH           => 8
      )
    port map
    ( clk_i           => clk_i
     ,arst_b_i        => arst_b_i
     ,s_axis_tdata_i  => s_axis_tdata
     ,s_axis_tvalid_i => s_axis_tvalid
     ,s_axis_tready_o => s_axis_tready
     ,uart_tx_o       => uart_tx_o
     ,baud_tick_i     => uart_baud_tick
     ,parity_enable_i => '0'
     ,parity_odd_i    => '0'
      );

--  ins_uart_rx_axis : entity work.uart_rx_axis(rtl)
--    generic map
--    ( WIDTH           => 8
--      )
--    port map
--    ( clk_i           => clk
--     ,arst_b_i        => arst_b_supervisor
--     ,m_axis_tdata_o  => open
--     ,m_axis_tvalid_o => open
--     ,m_axis_tready_i => '1'
--     ,uart_rx_i       => uart_tx
--     ,baud_tick_i     => uart_baud_tick
--     ,parity_enable_i => '0'
--     ,parity_odd_i    => '0'
--      );

  
end architecture rtl;
