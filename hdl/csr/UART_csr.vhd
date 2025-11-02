-- Generated VHDL Module for UART


library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;

library asylum;
use     asylum.UART_csr_pkg.ALL;
library asylum;
use     asylum.csr_pkg.ALL;
library asylum;
use     asylum.pbi_pkg.all;

--==================================
-- Module      : UART
-- Description : CSR for UART
-- Width       : 8
--==================================
entity UART_registers is
  generic (
    USER_DEFINE_BAUD_TICK : boolean -- Parameters to use the enable the User define Baud Tick
   ;BAUD_TICK_CNT_MAX : std_logic_vector(15 downto 0) -- Default value for Baud Tick Timer
   ;DEPTH_TX : natural -- Depth of FIFO TX (SW2HW)
   ;DEPTH_RX : natural -- Depth of FIFO RX (HW2SW)
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

  function INIT_isr
    return std_logic_vector is
    variable tmp : std_logic_vector(4-1 downto 0);
  begin  -- function INIT_isr
    tmp(3 downto 0) := "0000"; -- value
    return tmp;
  end function INIT_isr;

  signal   isr_wcs       : std_logic;
  signal   isr_we        : std_logic;
  signal   isr_wdata     : std_logic_vector(8-1 downto 0);
  signal   isr_wdata_sw  : std_logic_vector(4-1 downto 0);
  signal   isr_wdata_hw  : std_logic_vector(4-1 downto 0);
  signal   isr_wbusy     : std_logic;

  signal   isr_rcs       : std_logic;
  signal   isr_re        : std_logic;
  signal   isr_rdata     : std_logic_vector(8-1 downto 0);
  signal   isr_rdata_sw  : std_logic_vector(4-1 downto 0);
  signal   isr_rdata_hw  : std_logic_vector(4-1 downto 0);
  signal   isr_rbusy     : std_logic;

  function INIT_imr
    return std_logic_vector is
    variable tmp : std_logic_vector(4-1 downto 0);
  begin  -- function INIT_imr
    tmp(3 downto 0) := "0000"; -- enable
    return tmp;
  end function INIT_imr;

  signal   imr_wcs       : std_logic;
  signal   imr_we        : std_logic;
  signal   imr_wdata     : std_logic_vector(8-1 downto 0);
  signal   imr_wdata_sw  : std_logic_vector(4-1 downto 0);
  signal   imr_wdata_hw  : std_logic_vector(4-1 downto 0);
  signal   imr_wbusy     : std_logic;

  signal   imr_rcs       : std_logic;
  signal   imr_re        : std_logic;
  signal   imr_rdata     : std_logic_vector(8-1 downto 0);
  signal   imr_rdata_sw  : std_logic_vector(4-1 downto 0);
  signal   imr_rdata_hw  : std_logic_vector(4-1 downto 0);
  signal   imr_rbusy     : std_logic;

  function INIT_data
    return std_logic_vector is
    variable tmp : std_logic_vector(8-1 downto 0);
  begin  -- function INIT_data
    tmp(7 downto 0) := "00000000"; -- value
    return tmp;
  end function INIT_data;

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

  function INIT_ctrl_tx
    return std_logic_vector is
    variable tmp : std_logic_vector(5-1 downto 0);
  begin  -- function INIT_ctrl_tx
    tmp(0 downto 0) := "0"; -- tx_enable
    tmp(1 downto 1) := "0"; -- tx_parity_enable
    tmp(2 downto 2) := "0"; -- tx_parity_odd
    tmp(3 downto 3) := "0"; -- tx_use_loopback
    tmp(4 downto 4) := "0"; -- cts_enable
    return tmp;
  end function INIT_ctrl_tx;

  signal   ctrl_tx_wcs       : std_logic;
  signal   ctrl_tx_we        : std_logic;
  signal   ctrl_tx_wdata     : std_logic_vector(8-1 downto 0);
  signal   ctrl_tx_wdata_sw  : std_logic_vector(5-1 downto 0);
  signal   ctrl_tx_wdata_hw  : std_logic_vector(5-1 downto 0);
  signal   ctrl_tx_wbusy     : std_logic;

  signal   ctrl_tx_rcs       : std_logic;
  signal   ctrl_tx_re        : std_logic;
  signal   ctrl_tx_rdata     : std_logic_vector(8-1 downto 0);
  signal   ctrl_tx_rdata_sw  : std_logic_vector(5-1 downto 0);
  signal   ctrl_tx_rdata_hw  : std_logic_vector(5-1 downto 0);
  signal   ctrl_tx_rbusy     : std_logic;

  function INIT_ctrl_rx
    return std_logic_vector is
    variable tmp : std_logic_vector(5-1 downto 0);
  begin  -- function INIT_ctrl_rx
    tmp(0 downto 0) := "0"; -- rx_enable
    tmp(1 downto 1) := "0"; -- rx_parity_enable
    tmp(2 downto 2) := "0"; -- rx_parity_odd
    tmp(3 downto 3) := "0"; -- rx_use_loopback
    tmp(4 downto 4) := "0"; -- rts_enable
    return tmp;
  end function INIT_ctrl_rx;

  signal   ctrl_rx_wcs       : std_logic;
  signal   ctrl_rx_we        : std_logic;
  signal   ctrl_rx_wdata     : std_logic_vector(8-1 downto 0);
  signal   ctrl_rx_wdata_sw  : std_logic_vector(5-1 downto 0);
  signal   ctrl_rx_wdata_hw  : std_logic_vector(5-1 downto 0);
  signal   ctrl_rx_wbusy     : std_logic;

  signal   ctrl_rx_rcs       : std_logic;
  signal   ctrl_rx_re        : std_logic;
  signal   ctrl_rx_rdata     : std_logic_vector(8-1 downto 0);
  signal   ctrl_rx_rdata_sw  : std_logic_vector(5-1 downto 0);
  signal   ctrl_rx_rdata_hw  : std_logic_vector(5-1 downto 0);
  signal   ctrl_rx_rbusy     : std_logic;

  function INIT_baud_tick_cnt_max_lsb
    return std_logic_vector is
    variable tmp : std_logic_vector(8-1 downto 0);
  begin  -- function INIT_baud_tick_cnt_max_lsb
    tmp(7 downto 0) := BAUD_TICK_CNT_MAX(7 downto 0); -- value
    return tmp;
  end function INIT_baud_tick_cnt_max_lsb;

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

  function INIT_baud_tick_cnt_max_msb
    return std_logic_vector is
    variable tmp : std_logic_vector(8-1 downto 0);
  begin  -- function INIT_baud_tick_cnt_max_msb
    tmp(7 downto 0) := BAUD_TICK_CNT_MAX(15 downto 8); -- value
    return tmp;
  end function INIT_baud_tick_cnt_max_msb;

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

  gen_isr: if (True)
  generate
  --==================================
  -- Register    : isr
  -- Description : Interruption Status Register
  -- Address     : 0x0
  -- Width       : 4
  -- Sw Access   : rw1c
  -- Hw Access   : rw
  -- Hw Type     : reg
  --==================================
  --==================================
  -- Field       : value
  -- Description : 0: interrupt is inactive, 1: interrupt is active
  -- Width       : 4
  --==================================


    isr_rcs     <= '1' when     (sig_raddr(UART_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(0,UART_ADDR_WIDTH))) else '0';
    isr_re      <= sig_rcs and sig_re and isr_rcs;
    isr_rdata   <= (
      0 => isr_rdata_sw(0), -- value(0)
      1 => isr_rdata_sw(1), -- value(1)
      2 => isr_rdata_sw(2), -- value(2)
      3 => isr_rdata_sw(3), -- value(3)
      others => '0');

    isr_wcs     <= '1' when       (sig_waddr(UART_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(0,UART_ADDR_WIDTH)))   else '0';
    isr_we      <= sig_wcs and sig_we and isr_wcs;
    isr_wdata   <= sig_wdata;
    isr_wdata_sw(3 downto 0) <= isr_wdata(3 downto 0); -- value
    isr_wdata_hw(3 downto 0) <= hw2sw_i.isr.value; -- value
    sw2hw_o.isr.value <= isr_rdata_hw(3 downto 0); -- value

    ins_isr : csr_reg
      generic map
        (WIDTH         => 4
        ,INIT          => INIT_isr
        ,MODEL         => "rw1c"
        )
      port map
        (clk_i         => clk_i
        ,arst_b_i      => arst_b_i
        ,sw_wd_i       => isr_wdata_sw
        ,sw_rd_o       => isr_rdata_sw
        ,sw_we_i       => isr_we
        ,sw_re_i       => isr_re
        ,sw_rbusy_o    => isr_rbusy
        ,sw_wbusy_o    => isr_wbusy
        ,hw_wd_i       => isr_wdata_hw
        ,hw_rd_o       => isr_rdata_hw
        ,hw_we_i       => hw2sw_i.isr.we
        ,hw_sw_re_o    => sw2hw_o.isr.re
        ,hw_sw_we_o    => sw2hw_o.isr.we
        );

  end generate gen_isr;

  gen_isr_b: if not (True)
  generate
    isr_rcs     <= '0';
    isr_rbusy   <= '0';
    isr_rdata   <= (others => '0');
    isr_wcs      <= '0';
    isr_wbusy    <= '0';
    sw2hw_o.isr.value <= "0000";
    sw2hw_o.isr.re <= '0';
    sw2hw_o.isr.we <= '0';
  end generate gen_isr_b;

  gen_imr: if (True)
  generate
  --==================================
  -- Register    : imr
  -- Description : Interruption Mask Register
  -- Address     : 0x1
  -- Width       : 4
  -- Sw Access   : rw
  -- Hw Access   : ro
  -- Hw Type     : reg
  --==================================
  --==================================
  -- Field       : enable
  -- Description : 0: interrupt is disable, 1: interrupt is enable
  -- Width       : 4
  --==================================


    imr_rcs     <= '1' when     (sig_raddr(UART_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(1,UART_ADDR_WIDTH))) else '0';
    imr_re      <= sig_rcs and sig_re and imr_rcs;
    imr_rdata   <= (
      0 => imr_rdata_sw(0), -- enable(0)
      1 => imr_rdata_sw(1), -- enable(1)
      2 => imr_rdata_sw(2), -- enable(2)
      3 => imr_rdata_sw(3), -- enable(3)
      others => '0');

    imr_wcs     <= '1' when       (sig_waddr(UART_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(1,UART_ADDR_WIDTH)))   else '0';
    imr_we      <= sig_wcs and sig_we and imr_wcs;
    imr_wdata   <= sig_wdata;
    imr_wdata_sw(3 downto 0) <= imr_wdata(3 downto 0); -- enable
    sw2hw_o.imr.enable <= imr_rdata_hw(3 downto 0); -- enable

    ins_imr : csr_reg
      generic map
        (WIDTH         => 4
        ,INIT          => INIT_imr
        ,MODEL         => "rw"
        )
      port map
        (clk_i         => clk_i
        ,arst_b_i      => arst_b_i
        ,sw_wd_i       => imr_wdata_sw
        ,sw_rd_o       => imr_rdata_sw
        ,sw_we_i       => imr_we
        ,sw_re_i       => imr_re
        ,sw_rbusy_o    => imr_rbusy
        ,sw_wbusy_o    => imr_wbusy
        ,hw_wd_i       => (others => '0')
        ,hw_rd_o       => imr_rdata_hw
        ,hw_we_i       => '0'
        ,hw_sw_re_o    => sw2hw_o.imr.re
        ,hw_sw_we_o    => sw2hw_o.imr.we
        );

  end generate gen_imr;

  gen_imr_b: if not (True)
  generate
    imr_rcs     <= '0';
    imr_rbusy   <= '0';
    imr_rdata   <= (others => '0');
    imr_wcs      <= '0';
    imr_wbusy    <= '0';
    sw2hw_o.imr.enable <= "0000";
    sw2hw_o.imr.re <= '0';
    sw2hw_o.imr.we <= '0';
  end generate gen_imr_b;

  gen_data: if (True)
  generate
  --==================================
  -- Register    : data
  -- Description : Write : data to tansmit, Read : data to receive
  -- Address     : 0x2
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


    data_rcs     <= '1' when     (sig_raddr(UART_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(2,UART_ADDR_WIDTH))) else '0';
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

    data_wcs     <= '1' when       (sig_waddr(UART_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(2,UART_ADDR_WIDTH)))   else '0';
    data_we      <= sig_wcs and sig_we and data_wcs;
    data_wdata   <= sig_wdata;
    data_wdata_sw(7 downto 0) <= data_wdata(7 downto 0); -- value
    data_wdata_hw(7 downto 0) <= hw2sw_i.data.value; -- value
    sw2hw_o.data.value <= data_rdata_hw(7 downto 0); -- value

    ins_data : csr_fifo
      generic map
        (WIDTH         => 8
        ,BLOCKING_READ => True
        ,BLOCKING_WRITE => True
        ,DEPTH_SW2HW => DEPTH_TX
        ,DEPTH_HW2SW => DEPTH_RX
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
        ,hw_tx_valid_i        => hw2sw_i.data.valid
        ,hw_tx_ready_o        => sw2hw_o.data.ready
        ,hw_tx_data_i         => data_wdata_hw
        ,hw_tx_empty_o        => sw2hw_o.data.hw2sw_empty
        ,hw_tx_full_o         => sw2hw_o.data.hw2sw_full
        ,hw_rx_valid_o        => sw2hw_o.data.valid
        ,hw_rx_ready_i        => hw2sw_i.data.ready
        ,hw_rx_data_o         => data_rdata_hw
        ,hw_rx_empty_o        => sw2hw_o.data.sw2hw_empty
        ,hw_rx_full_o         => sw2hw_o.data.sw2hw_full
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

  gen_ctrl_tx: if (True)
  generate
  --==================================
  -- Register    : ctrl_tx
  -- Description : Control Register
  -- Address     : 0x4
  -- Width       : 5
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
  -- Field       : cts_enable
  -- Description : 0 : Clear To Send Disable, 1 : Clear To Send Enable
  -- Width       : 1
  --==================================


    ctrl_tx_rcs     <= '1' when     (sig_raddr(UART_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(4,UART_ADDR_WIDTH))) else '0';
    ctrl_tx_re      <= sig_rcs and sig_re and ctrl_tx_rcs;
    ctrl_tx_rdata   <= (
      0 => ctrl_tx_rdata_sw(0), -- tx_enable(0)
      1 => ctrl_tx_rdata_sw(1), -- tx_parity_enable(0)
      2 => ctrl_tx_rdata_sw(2), -- tx_parity_odd(0)
      3 => ctrl_tx_rdata_sw(3), -- tx_use_loopback(0)
      4 => ctrl_tx_rdata_sw(4), -- cts_enable(0)
      others => '0');

    ctrl_tx_wcs     <= '1' when       (sig_waddr(UART_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(4,UART_ADDR_WIDTH)))   else '0';
    ctrl_tx_we      <= sig_wcs and sig_we and ctrl_tx_wcs;
    ctrl_tx_wdata   <= sig_wdata;
    ctrl_tx_wdata_sw(0 downto 0) <= ctrl_tx_wdata(0 downto 0); -- tx_enable
    ctrl_tx_wdata_sw(1 downto 1) <= ctrl_tx_wdata(1 downto 1); -- tx_parity_enable
    ctrl_tx_wdata_sw(2 downto 2) <= ctrl_tx_wdata(2 downto 2); -- tx_parity_odd
    ctrl_tx_wdata_sw(3 downto 3) <= ctrl_tx_wdata(3 downto 3); -- tx_use_loopback
    ctrl_tx_wdata_sw(4 downto 4) <= ctrl_tx_wdata(4 downto 4); -- cts_enable
    sw2hw_o.ctrl_tx.tx_enable <= ctrl_tx_rdata_hw(0 downto 0); -- tx_enable
    sw2hw_o.ctrl_tx.tx_parity_enable <= ctrl_tx_rdata_hw(1 downto 1); -- tx_parity_enable
    sw2hw_o.ctrl_tx.tx_parity_odd <= ctrl_tx_rdata_hw(2 downto 2); -- tx_parity_odd
    sw2hw_o.ctrl_tx.tx_use_loopback <= ctrl_tx_rdata_hw(3 downto 3); -- tx_use_loopback
    sw2hw_o.ctrl_tx.cts_enable <= ctrl_tx_rdata_hw(4 downto 4); -- cts_enable

    ins_ctrl_tx : csr_reg
      generic map
        (WIDTH         => 5
        ,INIT          => INIT_ctrl_tx
        ,MODEL         => "rw"
        )
      port map
        (clk_i         => clk_i
        ,arst_b_i      => arst_b_i
        ,sw_wd_i       => ctrl_tx_wdata_sw
        ,sw_rd_o       => ctrl_tx_rdata_sw
        ,sw_we_i       => ctrl_tx_we
        ,sw_re_i       => ctrl_tx_re
        ,sw_rbusy_o    => ctrl_tx_rbusy
        ,sw_wbusy_o    => ctrl_tx_wbusy
        ,hw_wd_i       => (others => '0')
        ,hw_rd_o       => ctrl_tx_rdata_hw
        ,hw_we_i       => '0'
        ,hw_sw_re_o    => sw2hw_o.ctrl_tx.re
        ,hw_sw_we_o    => sw2hw_o.ctrl_tx.we
        );

  end generate gen_ctrl_tx;

  gen_ctrl_tx_b: if not (True)
  generate
    ctrl_tx_rcs     <= '0';
    ctrl_tx_rbusy   <= '0';
    ctrl_tx_rdata   <= (others => '0');
    ctrl_tx_wcs      <= '0';
    ctrl_tx_wbusy    <= '0';
    sw2hw_o.ctrl_tx.tx_enable <= "0";
    sw2hw_o.ctrl_tx.tx_parity_enable <= "0";
    sw2hw_o.ctrl_tx.tx_parity_odd <= "0";
    sw2hw_o.ctrl_tx.tx_use_loopback <= "0";
    sw2hw_o.ctrl_tx.cts_enable <= "0";
    sw2hw_o.ctrl_tx.re <= '0';
    sw2hw_o.ctrl_tx.we <= '0';
  end generate gen_ctrl_tx_b;

  gen_ctrl_rx: if (True)
  generate
  --==================================
  -- Register    : ctrl_rx
  -- Description : Control Register
  -- Address     : 0x5
  -- Width       : 5
  -- Sw Access   : rw
  -- Hw Access   : ro
  -- Hw Type     : reg
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

  --==================================
  -- Field       : rts_enable
  -- Description : 0 : Request To Send Disable, 1 : Request To Send Enable
  -- Width       : 1
  --==================================


    ctrl_rx_rcs     <= '1' when     (sig_raddr(UART_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(5,UART_ADDR_WIDTH))) else '0';
    ctrl_rx_re      <= sig_rcs and sig_re and ctrl_rx_rcs;
    ctrl_rx_rdata   <= (
      0 => ctrl_rx_rdata_sw(0), -- rx_enable(0)
      1 => ctrl_rx_rdata_sw(1), -- rx_parity_enable(0)
      2 => ctrl_rx_rdata_sw(2), -- rx_parity_odd(0)
      3 => ctrl_rx_rdata_sw(3), -- rx_use_loopback(0)
      4 => ctrl_rx_rdata_sw(4), -- rts_enable(0)
      others => '0');

    ctrl_rx_wcs     <= '1' when       (sig_waddr(UART_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(5,UART_ADDR_WIDTH)))   else '0';
    ctrl_rx_we      <= sig_wcs and sig_we and ctrl_rx_wcs;
    ctrl_rx_wdata   <= sig_wdata;
    ctrl_rx_wdata_sw(0 downto 0) <= ctrl_rx_wdata(0 downto 0); -- rx_enable
    ctrl_rx_wdata_sw(1 downto 1) <= ctrl_rx_wdata(1 downto 1); -- rx_parity_enable
    ctrl_rx_wdata_sw(2 downto 2) <= ctrl_rx_wdata(2 downto 2); -- rx_parity_odd
    ctrl_rx_wdata_sw(3 downto 3) <= ctrl_rx_wdata(3 downto 3); -- rx_use_loopback
    ctrl_rx_wdata_sw(4 downto 4) <= ctrl_rx_wdata(4 downto 4); -- rts_enable
    sw2hw_o.ctrl_rx.rx_enable <= ctrl_rx_rdata_hw(0 downto 0); -- rx_enable
    sw2hw_o.ctrl_rx.rx_parity_enable <= ctrl_rx_rdata_hw(1 downto 1); -- rx_parity_enable
    sw2hw_o.ctrl_rx.rx_parity_odd <= ctrl_rx_rdata_hw(2 downto 2); -- rx_parity_odd
    sw2hw_o.ctrl_rx.rx_use_loopback <= ctrl_rx_rdata_hw(3 downto 3); -- rx_use_loopback
    sw2hw_o.ctrl_rx.rts_enable <= ctrl_rx_rdata_hw(4 downto 4); -- rts_enable

    ins_ctrl_rx : csr_reg
      generic map
        (WIDTH         => 5
        ,INIT          => INIT_ctrl_rx
        ,MODEL         => "rw"
        )
      port map
        (clk_i         => clk_i
        ,arst_b_i      => arst_b_i
        ,sw_wd_i       => ctrl_rx_wdata_sw
        ,sw_rd_o       => ctrl_rx_rdata_sw
        ,sw_we_i       => ctrl_rx_we
        ,sw_re_i       => ctrl_rx_re
        ,sw_rbusy_o    => ctrl_rx_rbusy
        ,sw_wbusy_o    => ctrl_rx_wbusy
        ,hw_wd_i       => (others => '0')
        ,hw_rd_o       => ctrl_rx_rdata_hw
        ,hw_we_i       => '0'
        ,hw_sw_re_o    => sw2hw_o.ctrl_rx.re
        ,hw_sw_we_o    => sw2hw_o.ctrl_rx.we
        );

  end generate gen_ctrl_rx;

  gen_ctrl_rx_b: if not (True)
  generate
    ctrl_rx_rcs     <= '0';
    ctrl_rx_rbusy   <= '0';
    ctrl_rx_rdata   <= (others => '0');
    ctrl_rx_wcs      <= '0';
    ctrl_rx_wbusy    <= '0';
    sw2hw_o.ctrl_rx.rx_enable <= "0";
    sw2hw_o.ctrl_rx.rx_parity_enable <= "0";
    sw2hw_o.ctrl_rx.rx_parity_odd <= "0";
    sw2hw_o.ctrl_rx.rx_use_loopback <= "0";
    sw2hw_o.ctrl_rx.rts_enable <= "0";
    sw2hw_o.ctrl_rx.re <= '0';
    sw2hw_o.ctrl_rx.we <= '0';
  end generate gen_ctrl_rx_b;

  gen_baud_tick_cnt_max_lsb: if (USER_DEFINE_BAUD_TICK)
  generate
  --==================================
  -- Register    : baud_tick_cnt_max_lsb
  -- Description : Baud Tick Counter Max LSB. Must be equal to (Clock Frequency (Hz) / Baud Rate)-1
  -- Address     : 0x6
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


    baud_tick_cnt_max_lsb_rcs     <= '1' when     (sig_raddr(UART_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(6,UART_ADDR_WIDTH))) else '0';
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

    baud_tick_cnt_max_lsb_wcs     <= '1' when       (sig_waddr(UART_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(6,UART_ADDR_WIDTH)))   else '0';
    baud_tick_cnt_max_lsb_we      <= sig_wcs and sig_we and baud_tick_cnt_max_lsb_wcs;
    baud_tick_cnt_max_lsb_wdata   <= sig_wdata;
    baud_tick_cnt_max_lsb_wdata_sw(7 downto 0) <= baud_tick_cnt_max_lsb_wdata(7 downto 0); -- value
    sw2hw_o.baud_tick_cnt_max_lsb.value <= baud_tick_cnt_max_lsb_rdata_hw(7 downto 0); -- value

    ins_baud_tick_cnt_max_lsb : csr_reg
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
  -- Address     : 0x7
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


    baud_tick_cnt_max_msb_rcs     <= '1' when     (sig_raddr(UART_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(7,UART_ADDR_WIDTH))) else '0';
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

    baud_tick_cnt_max_msb_wcs     <= '1' when       (sig_waddr(UART_ADDR_WIDTH-1 downto 0) = std_logic_vector(to_unsigned(7,UART_ADDR_WIDTH)))   else '0';
    baud_tick_cnt_max_msb_we      <= sig_wcs and sig_we and baud_tick_cnt_max_msb_wcs;
    baud_tick_cnt_max_msb_wdata   <= sig_wdata;
    baud_tick_cnt_max_msb_wdata_sw(7 downto 0) <= baud_tick_cnt_max_msb_wdata(7 downto 0); -- value
    sw2hw_o.baud_tick_cnt_max_msb.value <= baud_tick_cnt_max_msb_rdata_hw(7 downto 0); -- value

    ins_baud_tick_cnt_max_msb : csr_reg
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
    isr_wbusy when isr_wcs = '1' else
    imr_wbusy when imr_wcs = '1' else
    data_wbusy when data_wcs = '1' else
    ctrl_tx_wbusy when ctrl_tx_wcs = '1' else
    ctrl_rx_wbusy when ctrl_rx_wcs = '1' else
    baud_tick_cnt_max_lsb_wbusy when baud_tick_cnt_max_lsb_wcs = '1' else
    baud_tick_cnt_max_msb_wbusy when baud_tick_cnt_max_msb_wcs = '1' else
    '0'; -- Bad Address, no busy
  sig_rbusy <= 
    isr_rbusy when isr_rcs = '1' else
    imr_rbusy when imr_rcs = '1' else
    data_rbusy when data_rcs = '1' else
    ctrl_tx_rbusy when ctrl_tx_rcs = '1' else
    ctrl_rx_rbusy when ctrl_rx_rcs = '1' else
    baud_tick_cnt_max_lsb_rbusy when baud_tick_cnt_max_lsb_rcs = '1' else
    baud_tick_cnt_max_msb_rbusy when baud_tick_cnt_max_msb_rcs = '1' else
    '0'; -- Bad Address, no busy
  sig_rdata <= 
    isr_rdata when isr_rcs = '1' else
    imr_rdata when imr_rcs = '1' else
    data_rdata when data_rcs = '1' else
    ctrl_tx_rdata when ctrl_tx_rcs = '1' else
    ctrl_rx_rdata when ctrl_rx_rcs = '1' else
    baud_tick_cnt_max_lsb_rdata when baud_tick_cnt_max_lsb_rcs = '1' else
    baud_tick_cnt_max_msb_rdata when baud_tick_cnt_max_msb_rcs = '1' else
    (others => '0'); -- Bad Address, return 0
end architecture rtl;
