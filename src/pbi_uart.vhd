-------------------------------------------------------------------------------
-- Title      : pbi_UART
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : pbi_UART.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2025-01-21
-- Last update: 2025-02-05
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
    UART_TX_ENABLE      : boolean := true;
    UART_RX_ENABLE      : boolean := true;
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
  
  signal ip_cs                  : std_logic;
  signal ip_re                  : std_logic;
  signal ip_we                  : std_logic;
  signal ip_addr                : std_logic_vector (SIZE_ADDR_IP-1   downto 0);
  signal ip_wdata               : std_logic_vector (PBI_DATA_WIDTH-1 downto 0);
  signal ip_rdata               : std_logic_vector (PBI_DATA_WIDTH-1 downto 0);
  signal ip_busy                : std_logic;
                            
  signal uart_tx                : std_logic;
  signal uart_rx                : std_logic;

  signal uart_tx_baud_tick_en   : std_logic;
  signal uart_tx_baud_tick      : std_logic;

  signal uart_rx_baud_tick_en   : std_logic;
  signal uart_rx_baud_tick      : std_logic;
  signal uart_rx_baud_tick_half : std_logic;

  signal s_axis_tvalid          : std_logic;
  signal s_axis_tready          : std_logic;
  signal s_axis_tdata           : std_logic_vector(8-1 downto 0);
                         
  signal m_axis_tvalid          : std_logic;
  signal m_axis_tready          : std_logic;
  signal m_axis_tdata           : std_logic_vector(8-1 downto 0);

  signal parity_enable          : std_logic;
  signal parity_odd             : std_logic;
  signal uart_loopback          : std_logic;
  
begin  -- architecture rtl

  parity_enable        <= '0';
  parity_odd           <= '0';
  uart_loopback        <= '1';

  uart_tx_o            <= uart_tx;
  
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

  ip_rdata             <= m_axis_tdata;
  ip_busy              <= not s_axis_tready;

  gen_uart_tx: if UART_TX_ENABLE = true
  generate

    ins_uart_tx_baud_rate_gen : entity work.uart_baud_rate_gen(rtl)
      generic map(
        BAUD_RATE      => BAUD_RATE,
        CLOCK_FREQ     => CLOCK_FREQ
        )
      port map(
        clk_i            => clk_i   ,
        arst_b_i         => arst_b_i,
        baud_tick_en_i   => uart_tx_baud_tick_en,
        baud_tick_o      => uart_tx_baud_tick,
        baud_tick_half_o => open
        );

    uart_tx_baud_tick_en <= '1';
    s_axis_tvalid        <= ip_cs and ip_we;
    s_axis_tdata         <= ip_wdata;
    
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
       ,uart_tx_o       => uart_tx
       ,baud_tick_i     => uart_tx_baud_tick
       ,parity_enable_i => parity_enable
       ,parity_odd_i    => parity_odd   
       );
    
  end generate gen_uart_tx;

  gen_uart_tx_b: if UART_TX_ENABLE = false
  generate

    s_axis_tready        <= '1';
    uart_tx              <= '1';
    
  end generate gen_uart_tx_b;


  gen_uart_rx: if UART_RX_ENABLE = true
  generate

    ins_uart_rx_baud_rate_gen : entity work.uart_baud_rate_gen(rtl)
      generic map(
        BAUD_RATE      => BAUD_RATE,
        CLOCK_FREQ     => CLOCK_FREQ
        )
      port map(
        clk_i            => clk_i   ,
        arst_b_i         => arst_b_i,
        baud_tick_en_i   => uart_rx_baud_tick_en,
        baud_tick_o      => uart_rx_baud_tick,
        baud_tick_half_o => uart_rx_baud_tick_half
        );

    m_axis_tready <= ip_cs and ip_re;
    uart_rx       <= uart_tx when uart_loopback = '1' else
                     uart_rx_i;

    ins_uart_rx_axis : entity work.uart_rx_axis(rtl)
      generic map
      ( WIDTH           => 8
        )
      port map
      ( clk_i           => clk_i
       ,arst_b_i        => arst_b_i
       ,m_axis_tdata_o  => m_axis_tdata
       ,m_axis_tvalid_o => m_axis_tvalid
       ,m_axis_tready_i => m_axis_tready
       ,uart_rx_i       => uart_rx
       ,baud_tick_en_o  => uart_rx_baud_tick_en
       ,baud_tick_i     => uart_rx_baud_tick
       ,baud_tick_half_i=> uart_rx_baud_tick_half
       ,parity_enable_i => parity_enable
       ,parity_odd_i    => parity_odd   
        );

  end generate gen_uart_rx;

  gen_uart_rx_b: if UART_RX_ENABLE = false
  generate

    m_axis_tdata    <= (others => '0');
    m_axis_tvalid   <= '0';
    
  end generate gen_uart_rx_b;
  
end architecture rtl;
