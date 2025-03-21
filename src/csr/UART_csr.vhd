-- Generated VHDL Module for UART


library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;

library work;
use     work.UART_csr_pkg.ALL;

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
    cs_i       : in    std_logic;
    re_i       : in    std_logic;
    we_i       : in    std_logic;
    addr_i     : in    std_logic_vector (1-1 downto 0);
    wdata_i    : in    std_logic_vector (8-1 downto 0);
    rdata_o    : out   std_logic_vector (8-1 downto 0);
    busy_o     : out   std_logic;
    -- CSR
    sw2hw_o    : out UART_sw2hw_t;
    hw2sw_i    : in  UART_hw2sw_t
  );
end entity UART_registers;

architecture rtl of UART_registers is

  signal   data_wcs   : std_logic;
  signal   data_rcs   : std_logic;
  signal   data_we    : std_logic;
  signal   data_re    : std_logic;
  signal   data_rdata : std_logic_vector(8-1 downto 0);
  signal   data_wdata : std_logic_vector(8-1 downto 0);
  signal   data_rbusy : std_logic;
  signal   data_value_rdata : std_logic_vector(7 downto 0);

  signal   ctrl_wcs   : std_logic;
  signal   ctrl_rcs   : std_logic;
  signal   ctrl_we    : std_logic;
  signal   ctrl_re    : std_logic;
  signal   ctrl_rdata : std_logic_vector(8-1 downto 0);
  signal   ctrl_wdata : std_logic_vector(8-1 downto 0);
  signal   ctrl_rbusy : std_logic;
  signal   ctrl_value_rdata : std_logic_vector(7 downto 0);

begin  -- architecture rtl

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


  data_rcs     <= '1' when     (addr_i = std_logic_vector(to_unsigned(0,UART_ADDR_WIDTH))) else '0';
  data_re      <= cs_i and data_rcs and re_i;
  data_rdata   <= (
    7 => data_value_rdata(7),
    6 => data_value_rdata(6),
    5 => data_value_rdata(5),
    4 => data_value_rdata(4),
    3 => data_value_rdata(3),
    2 => data_value_rdata(2),
    1 => data_value_rdata(1),
    0 => data_value_rdata(0),
    others => '0') when data_rcs = '1' else (others => '0');

  data_wcs     <= '1' when     (addr_i = std_logic_vector(to_unsigned(0,UART_ADDR_WIDTH))) else '0';
  data_we      <= cs_i and data_wcs and we_i;
  data_wdata   <= wdata_i;

  ins_data : entity work.csr_fifo(rtl)
    generic map
      (WIDTH         => 8
      )
    port map
      (clk_i         => clk_i
      ,arst_b_i      => arst_b_i
      ,sw_wd_i       => data_wdata(7 downto 0)
      ,sw_rd_o       => data_value_rdata
      ,sw_we_i       => data_we
      ,sw_re_i       => data_re
      ,sw_busy_o     => data_rbusy
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


  ctrl_rcs     <= '1' when     (addr_i = std_logic_vector(to_unsigned(1,UART_ADDR_WIDTH))) else '0';
  ctrl_re      <= cs_i and ctrl_rcs and re_i;
  ctrl_rdata   <= (
    7 => ctrl_value_rdata(7),
    6 => ctrl_value_rdata(6),
    5 => ctrl_value_rdata(5),
    4 => ctrl_value_rdata(4),
    3 => ctrl_value_rdata(3),
    2 => ctrl_value_rdata(2),
    1 => ctrl_value_rdata(1),
    0 => ctrl_value_rdata(0),
    others => '0') when ctrl_rcs = '1' else (others => '0');

  ctrl_wcs     <= '1' when     (addr_i = std_logic_vector(to_unsigned(1,UART_ADDR_WIDTH))) else '0';
  ctrl_we      <= cs_i and ctrl_wcs and we_i;
  ctrl_wdata   <= wdata_i;

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
      ,sw_busy_o     => ctrl_rbusy
      ,hw_wd_i       => (others => '0')
      ,hw_rd_o       => open
      ,hw_we_i       => '0'
      ,hw_sw_re_o    => sw2hw_o.ctrl.re
      ,hw_sw_we_o    => sw2hw_o.ctrl.we
      );

  busy_o  <= 
    data_rbusy or
    ctrl_rbusy;
  rdata_o <= 
    data_rdata or
    ctrl_rdata;
end architecture rtl;
