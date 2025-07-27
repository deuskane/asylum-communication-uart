-- Generated VHDL Package for UART

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;

--==================================
-- Module      : UART
-- Description : CSR for UART
-- Width       : 8
--==================================

package UART_csr_pkg is

  --==================================
  -- Register    : data
  -- Description : Write : data to tansmit, Read : data to receive
  -- Address     : 0x0
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
    rx_empty : std_logic;
    rx_full  : std_logic;
    tx_empty : std_logic;
    tx_full  : std_logic;
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
  -- Register    : ctrl
  -- Description : Control Register
  -- Address     : 0x1
  -- Width       : 8
  -- Sw Access   : rw
  -- Hw Access   : ro
  -- Hw Type     : reg
  --==================================
  type UART_ctrl_sw2hw_t is record
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
  end record UART_ctrl_sw2hw_t;

  --==================================
  -- Register    : baud_tick_cnt_max_lsb
  -- Description : Baud Tick Counter Max LSB. Must be equal to (Clock Frequency (Hz) / Baud Rate)-1
  -- Address     : 0x2
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
  -- Address     : 0x3
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
    data : UART_data_sw2hw_t;
    ctrl : UART_ctrl_sw2hw_t;
    baud_tick_cnt_max_lsb : UART_baud_tick_cnt_max_lsb_sw2hw_t;
    baud_tick_cnt_max_msb : UART_baud_tick_cnt_max_msb_sw2hw_t;
  end record UART_sw2hw_t;

  type UART_hw2sw_t is record
    data : UART_data_hw2sw_t;
  end record UART_hw2sw_t;

  constant UART_ADDR_WIDTH : natural := 2;
  constant UART_DATA_WIDTH : natural := 8;

end package UART_csr_pkg;
