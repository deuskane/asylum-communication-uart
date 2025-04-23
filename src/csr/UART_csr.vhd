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

  signal   data_wcs       : std_logic;
  signal   data_we        : std_logic;
  signal   data_wdata     : std_logic_vector(8-1 downto 0);
  signal   data_wbusy     : std_logic;
  signal   data_rcs       : std_logic;
  signal   data_re        : std_logic;
  signal   data_rdata     : std_logic_vector(8-1 downto 0);
  signal   data_rbusy     : std_logic;
  signal   data_value_rdata : std_logic_vector(7 downto 0);

  signal   ctrl_wcs       : std_logic;
  signal   ctrl_we        : std_logic;
  signal   ctrl_wdata     : std_logic_vector(8-1 downto 0);
  signal   ctrl_wbusy     : std_logic;
  signal   ctrl_rcs       : std_logic;
  signal   ctrl_re        : std_logic;
  signal   ctrl_rdata     : std_logic_vector(8-1 downto 0);
  signal   ctrl_rbusy     : std_logic;
  signal   ctrl_value_rdata : std_logic_vector(7 downto 0);

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
  -- Description : Data with data_oe with mask apply
  -- Width       : 8
  --==================================


  data_rcs     <= '1' when     (sig_raddr(UART_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(0,UART_ADDR_WIDTH))) else '0';
  data_re      <= sig_rcs and sig_re and data_rcs;
  data_rdata   <= (
    7 => data_value_rdata(7),
    6 => data_value_rdata(6),
    5 => data_value_rdata(5),
    4 => data_value_rdata(4),
    3 => data_value_rdata(3),
    2 => data_value_rdata(2),
    1 => data_value_rdata(1),
    0 => data_value_rdata(0),
    others => '0');

  data_wcs     <= '1' when     (sig_waddr(UART_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(0,UART_ADDR_WIDTH))) else '0';
  data_we      <= sig_wcs and sig_we and data_wcs;
  data_wdata   <= sig_wdata;

  ins_data : entity work.csr_fifo(rtl)
    generic map
      (WIDTH         => 8
      ,BLOCKING_READ => True
      ,BLOCKING_WRITE => True
      )
    port map
      (clk_i         => clk_i
      ,arst_b_i      => arst_b_i
      ,sw_wd_i       => data_wdata(7 downto 0)
      ,sw_rd_o       => data_value_rdata
      ,sw_we_i       => data_we
      ,sw_re_i       => data_re
      ,sw_rbusy_o    => data_rbusy
      ,sw_wbusy_o    => data_wbusy
      ,hw_tx_valid_i => hw2sw_i.data.valid
      ,hw_tx_ready_o => sw2hw_o.data.ready
      ,hw_tx_data_i  => hw2sw_i.data.value
      ,hw_rx_valid_o => sw2hw_o.data.valid
      ,hw_rx_ready_i => hw2sw_i.data.ready
      ,hw_rx_data_o  => sw2hw_o.data.value
      );

  --==================================
  -- Register    : ctrl
  -- Description : Write : data to tansmit, Read : data to receive
  -- Address     : 0x1
  -- Width       : 8
  -- Sw Access   : rw
  -- Hw Access   : none
  -- Hw Type     : reg
  --==================================
  --==================================
  -- Field       : value
  -- Description : Data with data_oe with mask apply
  -- Width       : 8
  --==================================


  ctrl_rcs     <= '1' when     (sig_raddr(UART_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(1,UART_ADDR_WIDTH))) else '0';
  ctrl_re      <= sig_rcs and sig_re and ctrl_rcs;
  ctrl_rdata   <= (
    7 => ctrl_value_rdata(7),
    6 => ctrl_value_rdata(6),
    5 => ctrl_value_rdata(5),
    4 => ctrl_value_rdata(4),
    3 => ctrl_value_rdata(3),
    2 => ctrl_value_rdata(2),
    1 => ctrl_value_rdata(1),
    0 => ctrl_value_rdata(0),
    others => '0');

  ctrl_wcs     <= '1' when     (sig_waddr(UART_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(1,UART_ADDR_WIDTH))) else '0';
  ctrl_we      <= sig_wcs and sig_we and ctrl_wcs;
  ctrl_wdata   <= sig_wdata;

  ins_ctrl : entity work.csr_reg(rtl)
    generic map
      (WIDTH         => 8
      ,INIT          => "00000000"
      ,MODEL         => "rw"
      )
    port map
      (clk_i         => clk_i
      ,arst_b_i      => arst_b_i
      ,sw_wd_i       => ctrl_wdata(7 downto 0)
      ,sw_rd_o       => ctrl_value_rdata
      ,sw_we_i       => ctrl_we
      ,sw_re_i       => ctrl_re
      ,sw_rbusy_o    => ctrl_rbusy
      ,sw_wbusy_o    => ctrl_wbusy
      ,hw_wd_i       => (others => '0')
      ,hw_rd_o       => open
      ,hw_we_i       => '0'
      ,hw_sw_re_o    => sw2hw_o.ctrl.re
      ,hw_sw_we_o    => sw2hw_o.ctrl.we
      );

  sig_wbusy <= 
    data_wbusy when data_wcs = '1' else
    ctrl_wbusy when ctrl_wcs = '1' else
    '0'; -- Bad Address, no busy
  sig_rbusy <= 
    data_rbusy when data_rcs = '1' else
    ctrl_rbusy when ctrl_rcs = '1' else
    '0'; -- Bad Address, no busy
  sig_rdata <= 
    data_rdata when data_rcs = '1' else
    ctrl_rdata when ctrl_rcs = '1' else
    (others => '0'); -- Bad Address, return 0
end architecture rtl;
