-------------------------------------------------------------------------------
-- Title      : pbi_UART
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : pbi_UART.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2025-01-21
-- Last update: 2025-08-02
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2017
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version Author  Description
-- 2025-01-21  0.1     mrosiere	Created
-- 2025-03-09  0.2     mrosiere	use unconstrained pbi
-- 2025-03-15  0.3     mrosiere Add CSR
-- 2025-05-14  1.0     mrosiere Add parameter USER_DEFINE_BAUD_TICK and default value
-- 2025-07-09  1.1     mrosiere Add FIFO Depth
-------------------------------------------------------------------------------

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.numeric_std.ALL;
use     ieee.std_logic_textio.all;
use     std.textio.all;

library work;
use     work.UART_csr_pkg.ALL;
use     work.pbi_pkg.all;

entity pbi_UART is
  generic (
    BAUD_RATE             : integer := 115200;
    CLOCK_FREQ            : integer := 50000000;
    BAUD_TICK_CNT_WIDTH   : integer := 16;
    UART_TX_ENABLE        : boolean := true;
    UART_RX_ENABLE        : boolean := true;
    USER_DEFINE_BAUD_TICK : boolean := true;
    DEPTH_TX              : natural := 0;
    DEPTH_RX              : natural := 0;
    
    FILENAME_TX           : string  := "dump_uart_tx.txt";
    FILENAME_RX           : string  := "dump_uart_rx.txt"
    );
  port   (
    clk_i            : in  std_logic;
    arst_b_i         : in  std_logic; -- asynchronous reset

    -- Bus
    pbi_ini_i        : in  pbi_ini_t;
    pbi_tgt_o        : out pbi_tgt_t;
    
    -- To/From IO
    uart_tx_o        : out std_logic; -- Data 
    uart_rx_i        : in  std_logic;

    uart_cts_b_i     : in  std_logic; -- Clear   To Send (Active low)
    uart_rts_b_o     : out std_logic; -- Request To Send (Active low)

    -- Interruption
    it_o             : out std_logic

    );

end entity pbi_UART;

architecture rtl of pbi_UART is

-- synthesis translate_off
  file     file_tx                : text open write_mode is FILENAME_TX;
  file     file_rx                : text open write_mode is FILENAME_RX;
-- synthesis translate_on

  -- Compute Max baud tick counter
  constant BAUD_TICK_CNT_MAX_INT  : integer := (CLOCK_FREQ / BAUD_RATE) - 1;
  constant BAUD_TICK_CNT_MAX_SLV  : std_logic_vector(BAUD_TICK_CNT_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(BAUD_TICK_CNT_MAX_INT, BAUD_TICK_CNT_WIDTH));
  
  signal   uart_tx                : std_logic;
  signal   uart_rx                : std_logic;
           
  signal   tx_baud_tick_en        : std_logic;
  signal   tx_baud_tick           : std_logic;
           
  signal   tx_tdata               : std_logic_vector(8-1 downto 0);
  signal   tx_tvalid              : std_logic;
  signal   tx_tready              : std_logic;
           
  signal   rx_tdata               : std_logic_vector(8-1 downto 0);
  signal   rx_tvalid              : std_logic;
  signal   rx_tready              : std_logic;
           
  signal   rx_baud_tick_en        : std_logic;
  signal   rx_baud_tick           : std_logic;
  signal   rx_baud_tick_half      : std_logic;
           
  signal   tx_enable              : std_logic;
  signal   tx_parity_enable       : std_logic;
  signal   tx_parity_odd          : std_logic;
  signal   tx_use_loopback        : std_logic;
           
  signal   rx_enable              : std_logic;
  signal   rx_parity_enable       : std_logic;
  signal   rx_parity_odd          : std_logic;
  signal   rx_use_loopback        : std_logic;
           
  signal   sw2hw                  : UART_sw2hw_t;
  signal   hw2sw                  : UART_hw2sw_t;

  signal   baud_tick_cnt_max      : std_logic_vector(16-1 downto 0);

  signal   it                     : std_logic_vector(4-1 downto 0);
  signal   it_rx_full             : std_logic;
  signal   it_rx_empty_b          : std_logic;
  signal   it_tx_full             : std_logic;
  signal   it_tx_empty_b          : std_logic;
  
begin  -- architecture rtl

  uart_tx_o            <= uart_tx;

  -- CSR Instance
  ins_csr : entity work.UART_registers(rtl)
    generic map(
      USER_DEFINE_BAUD_TICK => USER_DEFINE_BAUD_TICK,
      BAUD_TICK_CNT_MAX     => BAUD_TICK_CNT_MAX_SLV,
      DEPTH_TX              => DEPTH_TX,
      DEPTH_RX              => DEPTH_RX
      )
    port map(
      clk_i                 => clk_i           ,
      arst_b_i              => arst_b_i        ,
      pbi_ini_i             => pbi_ini_i       ,
      pbi_tgt_o             => pbi_tgt_o       ,
      sw2hw_o               => sw2hw           ,
      hw2sw_i               => hw2sw   
      );

  baud_tick_cnt_max    <= (sw2hw.baud_tick_cnt_max_msb.value &
                           sw2hw.baud_tick_cnt_max_lsb.value);
  -- UART TX
  gen_uart_tx: if UART_TX_ENABLE = true
  generate
    -- UART TX CSR Input
    tx_enable            <= sw2hw.ctrl.tx_enable       (0);
    tx_parity_enable     <= sw2hw.ctrl.tx_parity_enable(0);
    tx_parity_odd        <= sw2hw.ctrl.tx_parity_odd   (0);
    tx_use_loopback      <= sw2hw.ctrl.tx_use_loopback (0);

    ins_uart_tx_baud_rate_gen : entity work.uart_baud_rate_gen(rtl)
      generic map
      (BAUD_TICK_CNT_WIDTH     => BAUD_TICK_CNT_WIDTH
       )
      port map
      (clk_i                   => clk_i
      ,arst_b_i                => tx_enable
      ,baud_tick_en_i          => tx_baud_tick_en
      ,baud_tick_o             => tx_baud_tick
      ,baud_tick_half_o        => open
      ,cfg_baud_tick_cnt_max_i => baud_tick_cnt_max
      );

    tx_baud_tick_en  <= '1';

    ins_uart_tx_axis : entity work.uart_tx_axis(rtl)
      generic map
      ( WIDTH           => 8
        )
      port map
      ( clk_i           => clk_i
       ,arst_b_i        => tx_enable
       ,s_axis_tdata_i  => tx_tdata 
       ,s_axis_tvalid_i => tx_tvalid
       ,s_axis_tready_o => tx_tready
       ,uart_tx_o       => uart_tx
       ,baud_tick_i     => tx_baud_tick
       ,parity_enable_i => tx_parity_enable
       ,parity_odd_i    => tx_parity_odd   
        );

    gen_uart_rx: if UART_RX_ENABLE = true
    generate
      -- Have RX, can implement loopback
      tx_tdata         <= sw2hw.data.value when tx_use_loopback = '0' else rx_tdata ;
      tx_tvalid        <= sw2hw.data.valid when tx_use_loopback = '0' else rx_tvalid;
      hw2sw.data.ready <= tx_tready        when tx_use_loopback = '0' else '1';-- Always accept 
    end generate gen_uart_rx;

    gen_uart_rx_b: if UART_RX_ENABLE = false
    generate
      -- No RX, no loopback
      tx_tdata         <= sw2hw.data.value;
      tx_tvalid        <= sw2hw.data.valid;
      hw2sw.data.ready <= tx_tready;
    end generate gen_uart_rx_b;
    
  end generate gen_uart_tx;

  -- No UART TX
  gen_uart_tx_b: if UART_TX_ENABLE = false
  generate
    hw2sw.data.ready     <= '1';
    uart_tx              <= '1';
    tx_use_loopback      <= '0';
  end generate gen_uart_tx_b;

  gen_uart_rx: if UART_RX_ENABLE = true
  generate
    rx_enable            <= sw2hw.ctrl.rx_enable       (0);
    rx_parity_enable     <= sw2hw.ctrl.rx_parity_enable(0);
    rx_parity_odd        <= sw2hw.ctrl.rx_parity_odd   (0);
    rx_use_loopback      <= sw2hw.ctrl.rx_use_loopback (0);

    ins_uart_rx_baud_rate_gen : entity work.uart_baud_rate_gen(rtl)
      generic map
      (BAUD_TICK_CNT_WIDTH     => BAUD_TICK_CNT_WIDTH
       )
      port map
      (clk_i                   => clk_i
      ,arst_b_i                => rx_enable
      ,baud_tick_en_i          => rx_baud_tick_en
      ,baud_tick_o             => rx_baud_tick
      ,baud_tick_half_o        => rx_baud_tick_half
      ,cfg_baud_tick_cnt_max_i => baud_tick_cnt_max
      );

    ins_uart_rx_axis : entity work.uart_rx_axis(rtl)
      generic map
      ( WIDTH           => 8
        )
      port map
      ( clk_i           => clk_i
       ,arst_b_i        => rx_enable
       ,m_axis_tdata_o  => rx_tdata 
       ,m_axis_tvalid_o => rx_tvalid
       ,m_axis_tready_i => rx_tready
       ,uart_rx_i       => uart_rx
       ,baud_tick_en_o  => rx_baud_tick_en
       ,baud_tick_i     => rx_baud_tick
       ,baud_tick_half_i=> rx_baud_tick_half
       ,parity_enable_i => rx_parity_enable
       ,parity_odd_i    => rx_parity_odd   
        );

    gen_uart_tx: if UART_TX_ENABLE = true
    generate
      uart_rx          <= uart_tx when rx_use_loopback = '1' else
                          uart_rx_i;

      hw2sw.data.value <= rx_tdata         when tx_use_loopback = '0' else (others => '0');
      hw2sw.data.valid <= rx_tvalid        when tx_use_loopback = '0' else '0';
      rx_tready        <= sw2hw.data.ready when tx_use_loopback = '0' else tx_tready;
    end generate gen_uart_tx;

    gen_uart_tx_b: if UART_TX_ENABLE = false
    generate
      -- No TX, No loopback
      uart_rx          <= uart_rx_i;

      hw2sw.data.value <= rx_tdata ;
      hw2sw.data.valid <= rx_tvalid;
      rx_tready        <= sw2hw.data.ready;
    end generate gen_uart_tx_b;

  end generate gen_uart_rx;

  gen_uart_rx_b: if UART_RX_ENABLE = false
  generate

    hw2sw.data.value   <= (others => '0');
    hw2sw.data.valid   <= '0';
    
  end generate gen_uart_rx_b;

  it_rx_full    <=     sw2hw.data.hw2sw_full ;
  it_rx_empty_b <= not sw2hw.data.hw2sw_empty;
  it_tx_full    <=     sw2hw.data.sw2hw_full ;
  it_tx_empty_b <= not sw2hw.data.sw2hw_empty;
  it            <= (it_rx_full    &  
                    it_rx_empty_b & 
                    it_tx_full    & 
                    it_tx_empty_b 
                    );
  hw2sw.isr.we  <= '1';
  
  ins_GIC_core : entity work.GIC_core(rtl)
  port map(
    itm_o     => it_o            ,
    its_i     => it,
    isr_i     => sw2hw.isr.value ,
    isr_o     => hw2sw.isr.value ,
    imr_i     => sw2hw.imr.enable
    );
  
  
-- synthesis translate_off
  process
  begin
    report "Clock Frequency       : " & integer'image(CLOCK_FREQ);
    report "Baud Rate             : " & integer'image(BAUD_RATE);
    report "Baud Tick Counter Max : " & integer'image(BAUD_TICK_CNT_MAX_INT);
    report "Baud Tick Counter Div2: " & integer'image(BAUD_TICK_CNT_MAX_INT/2);
    wait;
  end process;

  process (clk_i) is
    variable line_buffer : line;
  begin  -- process

    if rising_edge(clk_i)
    then

      if (tx_tvalid and tx_tready)
      then
        write    (line_buffer, tx_tdata);
        write    (line_buffer, string'(" - 0x"));
        write    (line_buffer, to_hstring(tx_tdata));
        write    (line_buffer, string'(" - "));
        write    (line_buffer, character'val(to_integer(unsigned(tx_tdata))));
        writeline(file_tx, line_buffer);
      end if;

      if (rx_tvalid and rx_tready)
      then
        write    (line_buffer, rx_tdata);
        write    (line_buffer, string'(" - 0x"));
        write    (line_buffer, to_hstring(rx_tdata));
        write    (line_buffer, string'(" - "));
        write    (line_buffer, character'val(to_integer(unsigned(rx_tdata))));
        writeline(file_rx, line_buffer);
      end if;
      
    end if;
  end process;
-- synthesis translate_on
  
end architecture rtl;
