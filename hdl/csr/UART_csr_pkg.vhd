-- Generated VHDL Package for UART

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;

library asylum;
use     asylum.sbi_pkg.all;
--==================================
-- Module      : UART
-- Description : CSR for UART
-- Width       : 8
--==================================

package UART_csr_pkg is

  --==================================
  -- Register    : isr
  -- Description : Interruption Status Register
  -- Address     : 0x0
  -- Width       : 4
  -- Sw Access   : rw1c
  -- Hw Access   : rw
  -- Hw Type     : reg
  --==================================
  type UART_isr_sw2hw_t is record
    re : std_logic;
    we : std_logic;
  --==================================
  -- Field       : value
  -- Description : 0: interrupt is inactive, 1: interrupt is active
  -- Width       : 4
  --==================================
    value : std_logic_vector(4-1 downto 0);
  end record UART_isr_sw2hw_t;

  type UART_isr_hw2sw_t is record
    we : std_logic;
  --==================================
  -- Field       : value
  -- Description : 0: interrupt is inactive, 1: interrupt is active
  -- Width       : 4
  --==================================
    value : std_logic_vector(4-1 downto 0);
  end record UART_isr_hw2sw_t;

  --==================================
  -- Register    : imr
  -- Description : Interruption Mask Register
  -- Address     : 0x1
  -- Width       : 4
  -- Sw Access   : rw
  -- Hw Access   : ro
  -- Hw Type     : reg
  --==================================
  type UART_imr_sw2hw_t is record
    re : std_logic;
    we : std_logic;
  --==================================
  -- Field       : enable
  -- Description : 0: interrupt is disable, 1: interrupt is enable
  -- Width       : 4
  --==================================
    enable : std_logic_vector(4-1 downto 0);
  end record UART_imr_sw2hw_t;

  --==================================
  -- Register    : data
  -- Description : Write : data to tansmit, Read : data to receive
  -- Address     : 0x2
  -- Width       : 8
  -- Sw Access   : rw
  -- Hw Access   : rw
  -- Hw Type     : fifo
  --==================================
  type UART_data_sw2hw_t is record
    ready : std_logic;
    valid : std_logic;
  --==================================
  -- Field       : value
  -- Description : Data TX or Data RX
  -- Width       : 8
  --==================================
    value : std_logic_vector(8-1 downto 0);
    sw2hw_empty : std_logic;
    sw2hw_full  : std_logic;
    hw2sw_empty : std_logic;
    hw2sw_full  : std_logic;
  end record UART_data_sw2hw_t;

  type UART_data_hw2sw_t is record
    ready : std_logic;
    valid : std_logic;
  --==================================
  -- Field       : value
  -- Description : Data TX or Data RX
  -- Width       : 8
  --==================================
    value : std_logic_vector(8-1 downto 0);
  end record UART_data_hw2sw_t;

  --==================================
  -- Register    : ctrl_tx
  -- Description : Control Register
  -- Address     : 0x4
  -- Width       : 5
  -- Sw Access   : rw
  -- Hw Access   : ro
  -- Hw Type     : reg
  --==================================
  type UART_ctrl_tx_sw2hw_t is record
    re : std_logic;
    we : std_logic;
  --==================================
  -- Field       : tx_enable
  -- Description : 0 : TX is disable, 1 : TX is enable
  -- Width       : 1
  --==================================
    tx_enable : std_logic_vector(1-1 downto 0);
  --==================================
  -- Field       : tx_parity_enable
  -- Description : 0 : Parity is disable, 1 : Parity is enable
  -- Width       : 1
  --==================================
    tx_parity_enable : std_logic_vector(1-1 downto 0);
  --==================================
  -- Field       : tx_parity_odd
  -- Description : 0 : Parity is even, 1 : Parity is odd
  -- Width       : 1
  --==================================
    tx_parity_odd : std_logic_vector(1-1 downto 0);
  --==================================
  -- Field       : tx_use_loopback
  -- Description : 0 : UART TX FIFO is connected to CSR, 1 : UART RX FIFO is connected to UART RX FIFO
  -- Width       : 1
  --==================================
    tx_use_loopback : std_logic_vector(1-1 downto 0);
  --==================================
  -- Field       : cts_enable
  -- Description : 0 : Clear To Send Disable, 1 : Clear To Send Enable
  -- Width       : 1
  --==================================
    cts_enable : std_logic_vector(1-1 downto 0);
  end record UART_ctrl_tx_sw2hw_t;

  --==================================
  -- Register    : ctrl_rx
  -- Description : Control Register
  -- Address     : 0x5
  -- Width       : 5
  -- Sw Access   : rw
  -- Hw Access   : ro
  -- Hw Type     : reg
  --==================================
  type UART_ctrl_rx_sw2hw_t is record
    re : std_logic;
    we : std_logic;
  --==================================
  -- Field       : rx_enable
  -- Description : 0 : RX is disable, 1 : RX is enable
  -- Width       : 1
  --==================================
    rx_enable : std_logic_vector(1-1 downto 0);
  --==================================
  -- Field       : rx_parity_enable
  -- Description : 0 : Parity is disable, 1 : Parity is enable
  -- Width       : 1
  --==================================
    rx_parity_enable : std_logic_vector(1-1 downto 0);
  --==================================
  -- Field       : rx_parity_odd
  -- Description : 0 : Parity is even, 1 : Parity is odd
  -- Width       : 1
  --==================================
    rx_parity_odd : std_logic_vector(1-1 downto 0);
  --==================================
  -- Field       : rx_use_loopback
  -- Description : 0 : UART RX is connected to UART RX Input, 1 : UART RX is connected to UART TX
  -- Width       : 1
  --==================================
    rx_use_loopback : std_logic_vector(1-1 downto 0);
  --==================================
  -- Field       : rts_enable
  -- Description : 0 : Request To Send Disable, 1 : Request To Send Enable
  -- Width       : 1
  --==================================
    rts_enable : std_logic_vector(1-1 downto 0);
  end record UART_ctrl_rx_sw2hw_t;

  --==================================
  -- Register    : baud_tick_cnt_max_lsb
  -- Description : Baud Tick Counter Max LSB. Must be equal to (Clock Frequency (Hz) / Baud Rate)-1
  -- Address     : 0x6
  -- Width       : 8
  -- Sw Access   : rw
  -- Hw Access   : ro
  -- Hw Type     : reg
  --==================================
  type UART_baud_tick_cnt_max_lsb_sw2hw_t is record
    re : std_logic;
    we : std_logic;
  --==================================
  -- Field       : value
  -- Description : Baud Tick Counter Max LSB
  -- Width       : 8
  --==================================
    value : std_logic_vector(8-1 downto 0);
  end record UART_baud_tick_cnt_max_lsb_sw2hw_t;

  --==================================
  -- Register    : baud_tick_cnt_max_msb
  -- Description : Baud Tick Counter Max MSB. Must be equal to (Clock Frequency (Hz) / Baud Rate)-1
  -- Address     : 0x7
  -- Width       : 8
  -- Sw Access   : rw
  -- Hw Access   : ro
  -- Hw Type     : reg
  --==================================
  type UART_baud_tick_cnt_max_msb_sw2hw_t is record
    re : std_logic;
    we : std_logic;
  --==================================
  -- Field       : value
  -- Description : Baud Tick Counter Max MSB
  -- Width       : 8
  --==================================
    value : std_logic_vector(8-1 downto 0);
  end record UART_baud_tick_cnt_max_msb_sw2hw_t;

  ------------------------------------
  -- Structure UART_t
  ------------------------------------
  type UART_sw2hw_t is record
    isr : UART_isr_sw2hw_t;
    imr : UART_imr_sw2hw_t;
    data : UART_data_sw2hw_t;
    ctrl_tx : UART_ctrl_tx_sw2hw_t;
    ctrl_rx : UART_ctrl_rx_sw2hw_t;
    baud_tick_cnt_max_lsb : UART_baud_tick_cnt_max_lsb_sw2hw_t;
    baud_tick_cnt_max_msb : UART_baud_tick_cnt_max_msb_sw2hw_t;
  end record UART_sw2hw_t;

  type UART_hw2sw_t is record
    isr : UART_isr_hw2sw_t;
    data : UART_data_hw2sw_t;
  end record UART_hw2sw_t;

  constant UART_ADDR_WIDTH : natural := 3;
  constant UART_DATA_WIDTH : natural := 8;

  ------------------------------------
  -- Component
  ------------------------------------
component UART_registers is
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
    sbi_ini_i  : in  sbi_ini_t;
    sbi_tgt_o  : out sbi_tgt_t;
    -- CSR
    sw2hw_o    : out UART_sw2hw_t;
    hw2sw_i    : in  UART_hw2sw_t
  );
end component UART_registers;


end package UART_csr_pkg;
