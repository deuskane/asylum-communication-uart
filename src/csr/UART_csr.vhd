-- Generated VHDL Module for UART


library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;

library work;
use     work.UART_csr_pkg.ALL;
library work;
use     work.pbi_pkg.all;

--==================================
-- Module      : UART
-- Description : CSR for UART
-- Width       : 8
--==================================
entity UART_registers is
  generic (
    USER_DEFINE_BAUD_TICK : boolean -- Parameters to use the enable the User define Baud Tick
   ;BAUD_TICK_CNT_MAX : std_logic_vector(15 downto 0) -- Default value for Baud Tick Timer
  );
  port (
    -- Clock and Reset
    clk_i      : in  std_logic;
    arst_b_i   : in  std_logic;
    -- Bus
    pbi_ini_i  : in  pbi_ini_t;
    pbi_tgt_o  : out pbi_tgt_t;
    -- CSR
    sw2hw_o    : out UART_sw2hw_t;
    hw2sw_i    : in  UART_hw2sw_t
  );
end entity UART_registers;

architecture rtl of UART_registers is

  signal   sig_wcs   : std_logic;
  signal   sig_we    : std_logic;
  signal   sig_waddr : std_logic_vector(pbi_ini_i.addr'length-1 downto 0);
  signal   sig_wdata : std_logic_vector(pbi_ini_i.wdata'length-1 downto 0);
  signal   sig_wbusy : std_logic;

  signal   sig_rcs   : std_logic;
  signal   sig_re    : std_logic;
  signal   sig_raddr : std_logic_vector(pbi_ini_i.addr'length-1 downto 0);
  signal   sig_rdata : std_logic_vector(pbi_tgt_o.rdata'length-1 downto 0);
  signal   sig_rbusy : std_logic;

  signal   sig_busy  : std_logic;

  constant INIT_data : std_logic_vector(8-1 downto 0) :=
             "00000000" -- value
           ;
  signal   data_wcs       : std_logic;
  signal   data_we        : std_logic;
  signal   data_wdata     : std_logic_vector(8-1 downto 0);
  signal   data_wdata_sw  : std_logic_vector(8-1 downto 0);
  signal   data_wdata_hw  : std_logic_vector(8-1 downto 0);
  signal   data_wbusy     : std_logic;

  signal   data_rcs       : std_logic;
  signal   data_re        : std_logic;
  signal   data_rdata     : std_logic_vector(8-1 downto 0);
  signal   data_rdata_sw  : std_logic_vector(8-1 downto 0);
  signal   data_rdata_hw  : std_logic_vector(8-1 downto 0);
  signal   data_rbusy     : std_logic;

  constant INIT_ctrl : std_logic_vector(8-1 downto 0) :=
             "0" -- tx_enable
           & "0" -- tx_parity_enable
           & "0" -- tx_parity_odd
           & "0" -- tx_use_loopback
           & "0" -- rx_enable
           & "0" -- rx_parity_enable
           & "0" -- rx_parity_odd
           & "0" -- rx_use_loopback
           ;
  signal   ctrl_wcs       : std_logic;
  signal   ctrl_we        : std_logic;
  signal   ctrl_wdata     : std_logic_vector(8-1 downto 0);
  signal   ctrl_wdata_sw  : std_logic_vector(8-1 downto 0);
  signal   ctrl_wdata_hw  : std_logic_vector(8-1 downto 0);
  signal   ctrl_wbusy     : std_logic;

  signal   ctrl_rcs       : std_logic;
  signal   ctrl_re        : std_logic;
  signal   ctrl_rdata     : std_logic_vector(8-1 downto 0);
  signal   ctrl_rdata_sw  : std_logic_vector(8-1 downto 0);
  signal   ctrl_rdata_hw  : std_logic_vector(8-1 downto 0);
  signal   ctrl_rbusy     : std_logic;

  constant INIT_baud_tick_cnt_max_lsb : std_logic_vector(8-1 downto 0) :=
             BAUD_TICK_CNT_MAX(7 downto 0) -- value
           ;
  signal   baud_tick_cnt_max_lsb_wcs       : std_logic;
  signal   baud_tick_cnt_max_lsb_we        : std_logic;
  signal   baud_tick_cnt_max_lsb_wdata     : std_logic_vector(8-1 downto 0);
  signal   baud_tick_cnt_max_lsb_wdata_sw  : std_logic_vector(8-1 downto 0);
  signal   baud_tick_cnt_max_lsb_wdata_hw  : std_logic_vector(8-1 downto 0);
  signal   baud_tick_cnt_max_lsb_wbusy     : std_logic;

  signal   baud_tick_cnt_max_lsb_rcs       : std_logic;
  signal   baud_tick_cnt_max_lsb_re        : std_logic;
  signal   baud_tick_cnt_max_lsb_rdata     : std_logic_vector(8-1 downto 0);
  signal   baud_tick_cnt_max_lsb_rdata_sw  : std_logic_vector(8-1 downto 0);
  signal   baud_tick_cnt_max_lsb_rdata_hw  : std_logic_vector(8-1 downto 0);
  signal   baud_tick_cnt_max_lsb_rbusy     : std_logic;

  constant INIT_baud_tick_cnt_max_msb : std_logic_vector(8-1 downto 0) :=
             BAUD_TICK_CNT_MAX(15 downto 8) -- value
           ;
  signal   baud_tick_cnt_max_msb_wcs       : std_logic;
  signal   baud_tick_cnt_max_msb_we        : std_logic;
  signal   baud_tick_cnt_max_msb_wdata     : std_logic_vector(8-1 downto 0);
  signal   baud_tick_cnt_max_msb_wdata_sw  : std_logic_vector(8-1 downto 0);
  signal   baud_tick_cnt_max_msb_wdata_hw  : std_logic_vector(8-1 downto 0);
  signal   baud_tick_cnt_max_msb_wbusy     : std_logic;

  signal   baud_tick_cnt_max_msb_rcs       : std_logic;
  signal   baud_tick_cnt_max_msb_re        : std_logic;
  signal   baud_tick_cnt_max_msb_rdata     : std_logic_vector(8-1 downto 0);
  signal   baud_tick_cnt_max_msb_rdata_sw  : std_logic_vector(8-1 downto 0);
  signal   baud_tick_cnt_max_msb_rdata_hw  : std_logic_vector(8-1 downto 0);
  signal   baud_tick_cnt_max_msb_rbusy     : std_logic;

begin  -- architecture rtl

  -- Interface 
  sig_wcs   <= pbi_ini_i.cs;
  sig_we    <= pbi_ini_i.we;
  sig_waddr <= pbi_ini_i.addr;
  sig_wdata <= pbi_ini_i.wdata;

  sig_rcs   <= pbi_ini_i.cs;
  sig_re    <= pbi_ini_i.re;
  sig_raddr <= pbi_ini_i.addr;
  pbi_tgt_o.rdata <= sig_rdata;
  pbi_tgt_o.busy <= sig_busy;

  sig_busy  <= sig_wbusy when sig_we = '1' else
               sig_rbusy when sig_re = '1' else
               '0';

  gen_data: if (True)
  generate
  --==================================
  -- Register    : data
  -- Description : Write : data to tansmit, Read : data to receive
  -- Address     : 0x0
  -- Width       : 8
  -- Sw Access   : rw
  -- Hw Access   : rw
  -- Hw Type     : fifo
  --==================================
  --==================================
  -- Field       : value
  -- Description : Data TX or Data RX
  -- Width       : 8
  --==================================


    data_rcs     <= '1' when     (sig_raddr(UART_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(0,UART_ADDR_WIDTH))) else '0';
    data_re      <= sig_rcs and sig_re and data_rcs;
    data_rdata   <= (
      0 => data_rdata_sw(0), -- value(0)
      1 => data_rdata_sw(1), -- value(1)
      2 => data_rdata_sw(2), -- value(2)
      3 => data_rdata_sw(3), -- value(3)
      4 => data_rdata_sw(4), -- value(4)
      5 => data_rdata_sw(5), -- value(5)
      6 => data_rdata_sw(6), -- value(6)
      7 => data_rdata_sw(7), -- value(7)
      others => '0');

    data_wcs     <= '1' when       (sig_waddr(UART_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(0,UART_ADDR_WIDTH)))   else '0';
    data_we      <= sig_wcs and sig_we and data_wcs;
    data_wdata   <= sig_wdata;
    data_wdata_sw(7 downto 0) <= data_wdata(7 downto 0); -- value
    data_wdata_hw(7 downto 0) <= hw2sw_i.data.value; -- value
    sw2hw_o.data.value <= data_rdata_hw(7 downto 0); -- value

    ins_data : entity work.csr_fifo(rtl)
      generic map
        (WIDTH         => 8
        ,BLOCKING_READ => True
        ,BLOCKING_WRITE => True
        )
      port map
        (clk_i         => clk_i
        ,arst_b_i      => arst_b_i
        ,sw_wd_i       => data_wdata_sw
        ,sw_rd_o       => data_rdata_sw
        ,sw_we_i       => data_we
        ,sw_re_i       => data_re
        ,sw_rbusy_o    => data_rbusy
        ,sw_wbusy_o    => data_wbusy
        ,hw_tx_valid_i => hw2sw_i.data.valid
        ,hw_tx_ready_o => sw2hw_o.data.ready
        ,hw_tx_data_i  => data_wdata_hw
        ,hw_rx_valid_o => sw2hw_o.data.valid
        ,hw_rx_ready_i => hw2sw_i.data.ready
        ,hw_rx_data_o  => data_rdata_hw
        );

  end generate gen_data;

  gen_data_b: if not (True)
  generate
    data_rcs     <= '0';
    data_rbusy   <= '0';
    data_rdata   <= (others => '0');
    data_wcs      <= '0';
    data_wbusy    <= '0';
    sw2hw_o.data.value <= "00000000";
    sw2hw_o.data.ready <= '0';
    sw2hw_o.data.valid <= '0';
  end generate gen_data_b;

  gen_ctrl: if (True)
  generate
  --==================================
  -- Register    : ctrl
  -- Description : Control Register
  -- Address     : 0x1
  -- Width       : 8
  -- Sw Access   : rw
  -- Hw Access   : ro
  -- Hw Type     : reg
  --==================================
  --==================================
  -- Field       : tx_enable
  -- Description : 0 : TX is disable, 1 : TX is enable
  -- Width       : 1
  --==================================

  --==================================
  -- Field       : tx_parity_enable
  -- Description : 0 : Parity is disable, 1 : Parity is enable
  -- Width       : 1
  --==================================

  --==================================
  -- Field       : tx_parity_odd
  -- Description : 0 : Parity is even, 1 : Parity is odd
  -- Width       : 1
  --==================================

  --==================================
  -- Field       : tx_use_loopback
  -- Description : 0 : UART TX FIFO is connected to CSR, 1 : UART RX FIFO is connected to UART RX FIFO
  -- Width       : 1
  --==================================

  --==================================
  -- Field       : rx_enable
  -- Description : 0 : RX is disable, 1 : RX is enable
  -- Width       : 1
  --==================================

  --==================================
  -- Field       : rx_parity_enable
  -- Description : 0 : Parity is disable, 1 : Parity is enable
  -- Width       : 1
  --==================================

  --==================================
  -- Field       : rx_parity_odd
  -- Description : 0 : Parity is even, 1 : Parity is odd
  -- Width       : 1
  --==================================

  --==================================
  -- Field       : rx_use_loopback
  -- Description : 0 : UART RX is connected to UART RX Input, 1 : UART RX is connected to UART TX
  -- Width       : 1
  --==================================


    ctrl_rcs     <= '1' when     (sig_raddr(UART_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(1,UART_ADDR_WIDTH))) else '0';
    ctrl_re      <= sig_rcs and sig_re and ctrl_rcs;
    ctrl_rdata   <= (
      0 => ctrl_rdata_sw(0), -- tx_enable(0)
      1 => ctrl_rdata_sw(1), -- tx_parity_enable(0)
      2 => ctrl_rdata_sw(2), -- tx_parity_odd(0)
      3 => ctrl_rdata_sw(3), -- tx_use_loopback(0)
      4 => ctrl_rdata_sw(4), -- rx_enable(0)
      5 => ctrl_rdata_sw(5), -- rx_parity_enable(0)
      6 => ctrl_rdata_sw(6), -- rx_parity_odd(0)
      7 => ctrl_rdata_sw(7), -- rx_use_loopback(0)
      others => '0');

    ctrl_wcs     <= '1' when       (sig_waddr(UART_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(1,UART_ADDR_WIDTH)))   else '0';
    ctrl_we      <= sig_wcs and sig_we and ctrl_wcs;
    ctrl_wdata   <= sig_wdata;
    ctrl_wdata_sw(0 downto 0) <= ctrl_wdata(0 downto 0); -- tx_enable
    ctrl_wdata_sw(1 downto 1) <= ctrl_wdata(1 downto 1); -- tx_parity_enable
    ctrl_wdata_sw(2 downto 2) <= ctrl_wdata(2 downto 2); -- tx_parity_odd
    ctrl_wdata_sw(3 downto 3) <= ctrl_wdata(3 downto 3); -- tx_use_loopback
    ctrl_wdata_sw(4 downto 4) <= ctrl_wdata(4 downto 4); -- rx_enable
    ctrl_wdata_sw(5 downto 5) <= ctrl_wdata(5 downto 5); -- rx_parity_enable
    ctrl_wdata_sw(6 downto 6) <= ctrl_wdata(6 downto 6); -- rx_parity_odd
    ctrl_wdata_sw(7 downto 7) <= ctrl_wdata(7 downto 7); -- rx_use_loopback
    sw2hw_o.ctrl.tx_enable <= ctrl_rdata_hw(0 downto 0); -- tx_enable
    sw2hw_o.ctrl.tx_parity_enable <= ctrl_rdata_hw(1 downto 1); -- tx_parity_enable
    sw2hw_o.ctrl.tx_parity_odd <= ctrl_rdata_hw(2 downto 2); -- tx_parity_odd
    sw2hw_o.ctrl.tx_use_loopback <= ctrl_rdata_hw(3 downto 3); -- tx_use_loopback
    sw2hw_o.ctrl.rx_enable <= ctrl_rdata_hw(4 downto 4); -- rx_enable
    sw2hw_o.ctrl.rx_parity_enable <= ctrl_rdata_hw(5 downto 5); -- rx_parity_enable
    sw2hw_o.ctrl.rx_parity_odd <= ctrl_rdata_hw(6 downto 6); -- rx_parity_odd
    sw2hw_o.ctrl.rx_use_loopback <= ctrl_rdata_hw(7 downto 7); -- rx_use_loopback

    ins_ctrl : entity work.csr_reg(rtl)
      generic map
        (WIDTH         => 8
        ,INIT          => INIT_ctrl
        ,MODEL         => "rw"
        )
      port map
        (clk_i         => clk_i
        ,arst_b_i      => arst_b_i
        ,sw_wd_i       => ctrl_wdata_sw
        ,sw_rd_o       => ctrl_rdata_sw
        ,sw_we_i       => ctrl_we
        ,sw_re_i       => ctrl_re
        ,sw_rbusy_o    => ctrl_rbusy
        ,sw_wbusy_o    => ctrl_wbusy
        ,hw_wd_i       => (others => '0')
        ,hw_rd_o       => ctrl_rdata_hw
        ,hw_we_i       => '0'
        ,hw_sw_re_o    => sw2hw_o.ctrl.re
        ,hw_sw_we_o    => sw2hw_o.ctrl.we
        );

  end generate gen_ctrl;

  gen_ctrl_b: if not (True)
  generate
    ctrl_rcs     <= '0';
    ctrl_rbusy   <= '0';
    ctrl_rdata   <= (others => '0');
    ctrl_wcs      <= '0';
    ctrl_wbusy    <= '0';
    sw2hw_o.ctrl.tx_enable <= "0";
    sw2hw_o.ctrl.tx_parity_enable <= "0";
    sw2hw_o.ctrl.tx_parity_odd <= "0";
    sw2hw_o.ctrl.tx_use_loopback <= "0";
    sw2hw_o.ctrl.rx_enable <= "0";
    sw2hw_o.ctrl.rx_parity_enable <= "0";
    sw2hw_o.ctrl.rx_parity_odd <= "0";
    sw2hw_o.ctrl.rx_use_loopback <= "0";
    sw2hw_o.ctrl.re <= '0';
    sw2hw_o.ctrl.we <= '0';
  end generate gen_ctrl_b;

  gen_baud_tick_cnt_max_lsb: if (USER_DEFINE_BAUD_TICK)
  generate
  --==================================
  -- Register    : baud_tick_cnt_max_lsb
  -- Description : Baud Tick Counter Max LSB. Must be equal to (Clock Frequency (Hz) / Baud Rate)-1
  -- Address     : 0x2
  -- Width       : 8
  -- Sw Access   : rw
  -- Hw Access   : ro
  -- Hw Type     : reg
  --==================================
  --==================================
  -- Field       : value
  -- Description : Baud Tick Counter Max LSB
  -- Width       : 8
  --==================================


    baud_tick_cnt_max_lsb_rcs     <= '1' when     (sig_raddr(UART_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(2,UART_ADDR_WIDTH))) else '0';
    baud_tick_cnt_max_lsb_re      <= sig_rcs and sig_re and baud_tick_cnt_max_lsb_rcs;
    baud_tick_cnt_max_lsb_rdata   <= (
      0 => baud_tick_cnt_max_lsb_rdata_sw(0), -- value(0)
      1 => baud_tick_cnt_max_lsb_rdata_sw(1), -- value(1)
      2 => baud_tick_cnt_max_lsb_rdata_sw(2), -- value(2)
      3 => baud_tick_cnt_max_lsb_rdata_sw(3), -- value(3)
      4 => baud_tick_cnt_max_lsb_rdata_sw(4), -- value(4)
      5 => baud_tick_cnt_max_lsb_rdata_sw(5), -- value(5)
      6 => baud_tick_cnt_max_lsb_rdata_sw(6), -- value(6)
      7 => baud_tick_cnt_max_lsb_rdata_sw(7), -- value(7)
      others => '0');

    baud_tick_cnt_max_lsb_wcs     <= '1' when       (sig_waddr(UART_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(2,UART_ADDR_WIDTH)))   else '0';
    baud_tick_cnt_max_lsb_we      <= sig_wcs and sig_we and baud_tick_cnt_max_lsb_wcs;
    baud_tick_cnt_max_lsb_wdata   <= sig_wdata;
    baud_tick_cnt_max_lsb_wdata_sw(7 downto 0) <= baud_tick_cnt_max_lsb_wdata(7 downto 0); -- value
    sw2hw_o.baud_tick_cnt_max_lsb.value <= baud_tick_cnt_max_lsb_rdata_hw(7 downto 0); -- value

    ins_baud_tick_cnt_max_lsb : entity work.csr_reg(rtl)
      generic map
        (WIDTH         => 8
        ,INIT          => INIT_baud_tick_cnt_max_lsb
        ,MODEL         => "rw"
        )
      port map
        (clk_i         => clk_i
        ,arst_b_i      => arst_b_i
        ,sw_wd_i       => baud_tick_cnt_max_lsb_wdata_sw
        ,sw_rd_o       => baud_tick_cnt_max_lsb_rdata_sw
        ,sw_we_i       => baud_tick_cnt_max_lsb_we
        ,sw_re_i       => baud_tick_cnt_max_lsb_re
        ,sw_rbusy_o    => baud_tick_cnt_max_lsb_rbusy
        ,sw_wbusy_o    => baud_tick_cnt_max_lsb_wbusy
        ,hw_wd_i       => (others => '0')
        ,hw_rd_o       => baud_tick_cnt_max_lsb_rdata_hw
        ,hw_we_i       => '0'
        ,hw_sw_re_o    => sw2hw_o.baud_tick_cnt_max_lsb.re
        ,hw_sw_we_o    => sw2hw_o.baud_tick_cnt_max_lsb.we
        );

  end generate gen_baud_tick_cnt_max_lsb;

  gen_baud_tick_cnt_max_lsb_b: if not (USER_DEFINE_BAUD_TICK)
  generate
    baud_tick_cnt_max_lsb_rcs     <= '0';
    baud_tick_cnt_max_lsb_rbusy   <= '0';
    baud_tick_cnt_max_lsb_rdata   <= (others => '0');
    baud_tick_cnt_max_lsb_wcs      <= '0';
    baud_tick_cnt_max_lsb_wbusy    <= '0';
    sw2hw_o.baud_tick_cnt_max_lsb.value <= BAUD_TICK_CNT_MAX(7 downto 0);
    sw2hw_o.baud_tick_cnt_max_lsb.re <= '0';
    sw2hw_o.baud_tick_cnt_max_lsb.we <= '0';
  end generate gen_baud_tick_cnt_max_lsb_b;

  gen_baud_tick_cnt_max_msb: if (USER_DEFINE_BAUD_TICK)
  generate
  --==================================
  -- Register    : baud_tick_cnt_max_msb
  -- Description : Baud Tick Counter Max MSB. Must be equal to (Clock Frequency (Hz) / Baud Rate)-1
  -- Address     : 0x3
  -- Width       : 8
  -- Sw Access   : rw
  -- Hw Access   : ro
  -- Hw Type     : reg
  --==================================
  --==================================
  -- Field       : value
  -- Description : Baud Tick Counter Max MSB
  -- Width       : 8
  --==================================


    baud_tick_cnt_max_msb_rcs     <= '1' when     (sig_raddr(UART_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(3,UART_ADDR_WIDTH))) else '0';
    baud_tick_cnt_max_msb_re      <= sig_rcs and sig_re and baud_tick_cnt_max_msb_rcs;
    baud_tick_cnt_max_msb_rdata   <= (
      0 => baud_tick_cnt_max_msb_rdata_sw(0), -- value(0)
      1 => baud_tick_cnt_max_msb_rdata_sw(1), -- value(1)
      2 => baud_tick_cnt_max_msb_rdata_sw(2), -- value(2)
      3 => baud_tick_cnt_max_msb_rdata_sw(3), -- value(3)
      4 => baud_tick_cnt_max_msb_rdata_sw(4), -- value(4)
      5 => baud_tick_cnt_max_msb_rdata_sw(5), -- value(5)
      6 => baud_tick_cnt_max_msb_rdata_sw(6), -- value(6)
      7 => baud_tick_cnt_max_msb_rdata_sw(7), -- value(7)
      others => '0');

    baud_tick_cnt_max_msb_wcs     <= '1' when       (sig_waddr(UART_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(3,UART_ADDR_WIDTH)))   else '0';
    baud_tick_cnt_max_msb_we      <= sig_wcs and sig_we and baud_tick_cnt_max_msb_wcs;
    baud_tick_cnt_max_msb_wdata   <= sig_wdata;
    baud_tick_cnt_max_msb_wdata_sw(7 downto 0) <= baud_tick_cnt_max_msb_wdata(7 downto 0); -- value
    sw2hw_o.baud_tick_cnt_max_msb.value <= baud_tick_cnt_max_msb_rdata_hw(7 downto 0); -- value

    ins_baud_tick_cnt_max_msb : entity work.csr_reg(rtl)
      generic map
        (WIDTH         => 8
        ,INIT          => INIT_baud_tick_cnt_max_msb
        ,MODEL         => "rw"
        )
      port map
        (clk_i         => clk_i
        ,arst_b_i      => arst_b_i
        ,sw_wd_i       => baud_tick_cnt_max_msb_wdata_sw
        ,sw_rd_o       => baud_tick_cnt_max_msb_rdata_sw
        ,sw_we_i       => baud_tick_cnt_max_msb_we
        ,sw_re_i       => baud_tick_cnt_max_msb_re
        ,sw_rbusy_o    => baud_tick_cnt_max_msb_rbusy
        ,sw_wbusy_o    => baud_tick_cnt_max_msb_wbusy
        ,hw_wd_i       => (others => '0')
        ,hw_rd_o       => baud_tick_cnt_max_msb_rdata_hw
        ,hw_we_i       => '0'
        ,hw_sw_re_o    => sw2hw_o.baud_tick_cnt_max_msb.re
        ,hw_sw_we_o    => sw2hw_o.baud_tick_cnt_max_msb.we
        );

  end generate gen_baud_tick_cnt_max_msb;

  gen_baud_tick_cnt_max_msb_b: if not (USER_DEFINE_BAUD_TICK)
  generate
    baud_tick_cnt_max_msb_rcs     <= '0';
    baud_tick_cnt_max_msb_rbusy   <= '0';
    baud_tick_cnt_max_msb_rdata   <= (others => '0');
    baud_tick_cnt_max_msb_wcs      <= '0';
    baud_tick_cnt_max_msb_wbusy    <= '0';
    sw2hw_o.baud_tick_cnt_max_msb.value <= BAUD_TICK_CNT_MAX(15 downto 8);
    sw2hw_o.baud_tick_cnt_max_msb.re <= '0';
    sw2hw_o.baud_tick_cnt_max_msb.we <= '0';
  end generate gen_baud_tick_cnt_max_msb_b;

  sig_wbusy <= 
    data_wbusy when data_wcs = '1' else
    ctrl_wbusy when ctrl_wcs = '1' else
    baud_tick_cnt_max_lsb_wbusy when baud_tick_cnt_max_lsb_wcs = '1' else
    baud_tick_cnt_max_msb_wbusy when baud_tick_cnt_max_msb_wcs = '1' else
    '0'; -- Bad Address, no busy
  sig_rbusy <= 
    data_rbusy when data_rcs = '1' else
    ctrl_rbusy when ctrl_rcs = '1' else
    baud_tick_cnt_max_lsb_rbusy when baud_tick_cnt_max_lsb_rcs = '1' else
    baud_tick_cnt_max_msb_rbusy when baud_tick_cnt_max_msb_rcs = '1' else
    '0'; -- Bad Address, no busy
  sig_rdata <= 
    data_rdata when data_rcs = '1' else
    ctrl_rdata when ctrl_rcs = '1' else
    baud_tick_cnt_max_lsb_rdata when baud_tick_cnt_max_lsb_rcs = '1' else
    baud_tick_cnt_max_msb_rdata when baud_tick_cnt_max_msb_rcs = '1' else
    (others => '0'); -- Bad Address, return 0
end architecture rtl;
