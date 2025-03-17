-------------------------------------------------------------------------------
-- Title      : pbi_UART
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : pbi_UART.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2025-01-21
-- Last update: 2025-03-15
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
-- 2025-03-09  0.2      rosiere	use unconstrained pbi
-- 2025-03-15  0.3      rosiere Add CSR
-------------------------------------------------------------------------------

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.numeric_std.ALL;
library work;
use     work.UART_csr_pkg.ALL;
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
  signal pbi_ini                : pbi_ini_t(addr (UART_ADDR_WIDTH-1 downto 0),
                                            wdata(PBI_DATA_WIDTH-1 downto 0));
  signal pbi_tgt                : pbi_tgt_t(rdata(PBI_DATA_WIDTH-1 downto 0));
                            
  signal uart_tx                : std_logic;
  signal uart_rx                : std_logic;

  signal uart_tx_baud_tick_en   : std_logic;
  signal uart_tx_baud_tick      : std_logic;

  signal uart_rx_baud_tick_en   : std_logic;
  signal uart_rx_baud_tick      : std_logic;
  signal uart_rx_baud_tick_half : std_logic;

  signal parity_enable          : std_logic;
  signal parity_odd             : std_logic;
  signal uart_loopback          : std_logic;

  signal sw2hw                  : UART_sw2hw_t;
  signal hw2sw                  : UART_hw2sw_t;
  
begin  -- architecture rtl

  parity_enable        <= '0';
  parity_odd           <= '0';
  uart_loopback        <= '1';

  uart_tx_o            <= uart_tx;
  
  ins_pbi_wrapper_target : entity work.pbi_wrapper_target(rtl)
  generic map(
    SIZE_DATA      => PBI_DATA_WIDTH ,
    SIZE_ADDR_IP   => UART_ADDR_WIDTH,
    ID             => ID
     )
  port map(
    clk_i          => clk_i         ,
    cke_i          => '1'           ,
    arstn_i        => arst_b_i      ,
    pbi_ini_i      => pbi_ini_i     ,
    pbi_tgt_o      => pbi_tgt_o     ,
    pbi_ini_o      => pbi_ini       ,
    pbi_tgt_i      => pbi_tgt       
    );

  ins_csr : entity work.UART_registers(rtl)
  port map(
    clk_i     => clk_i           ,
    arst_b_i  => arst_b_i        ,
    cs_i      => pbi_ini.cs      ,
    re_i      => pbi_ini.re      ,
    we_i      => pbi_ini.we      ,
    addr_i    => pbi_ini.addr    ,
    wdata_i   => pbi_ini.wdata   ,
    rdata_o   => pbi_tgt.rdata   ,
    busy_o    => pbi_tgt.busy    ,
    sw2hw_o   => sw2hw           ,
    hw2sw_i   => hw2sw   
  );
  
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
    
    ins_uart_tx_axis : entity work.uart_tx_axis(rtl)
      generic map
      ( WIDTH           => 8
        )
      port map
      ( clk_i           => clk_i
       ,arst_b_i        => arst_b_i
       ,s_axis_tdata_i  => sw2hw.data.value
       ,s_axis_tvalid_i => sw2hw.data.valid
       ,s_axis_tready_o => hw2sw.data.ready
       ,uart_tx_o       => uart_tx
       ,baud_tick_i     => uart_tx_baud_tick
       ,parity_enable_i => parity_enable
       ,parity_odd_i    => parity_odd   
       );
    
  end generate gen_uart_tx;

  gen_uart_tx_b: if UART_TX_ENABLE = false
  generate
    hw2sw.data.ready     <= '1';
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

    uart_rx       <= uart_tx when uart_loopback = '1' else
                     uart_rx_i;

    ins_uart_rx_axis : entity work.uart_rx_axis(rtl)
      generic map
      ( WIDTH           => 8
        )
      port map
      ( clk_i           => clk_i
       ,arst_b_i        => arst_b_i
       ,m_axis_tdata_o  => hw2sw.data.value
       ,m_axis_tvalid_o => hw2sw.data.valid
       ,m_axis_tready_i => sw2hw.data.ready
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

    hw2sw.data.value   <= (others => '0');
    hw2sw.data.valid   <= '0';
    
  end generate gen_uart_rx_b;
  
end architecture rtl;
