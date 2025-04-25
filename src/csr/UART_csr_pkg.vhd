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
  -- Width       : 5
  -- Sw Access   : rw
  -- Hw Access   : ro
  -- Hw Type     : reg
  --==================================
  type UART_ctrl_sw2hw_t is record
    re : std_logic;
    we : std_logic;
  --==================================
  -- Field       : enable_tx
  -- Description : 0 : TX is disable, 1 : TX is enable
  -- Width       : 1
  --==================================
    enable_tx : std_logic_vector(1-1 downto 0);
  --==================================
  -- Field       : enable_rx
  -- Description : 0 : RX is disable, 1 : RX is enable
  -- Width       : 1
  --==================================
    enable_rx : std_logic_vector(1-1 downto 0);
  --==================================
  -- Field       : parity_enable
  -- Description : 0 : Parity is disable, 1 : Parity is enable
  -- Width       : 1
  --==================================
    parity_enable : std_logic_vector(1-1 downto 0);
  --==================================
  -- Field       : parity_odd
  -- Description : 0 : Parity is even, 1 : Parity is odd
  -- Width       : 1
  --==================================
    parity_odd : std_logic_vector(1-1 downto 0);
  --==================================
  -- Field       : loopback
  -- Description : 0 : UART RX is connected to input, 1 : UART RX is connected to UART TX
  -- Width       : 1
  --==================================
    loopback : std_logic_vector(1-1 downto 0);
  end record UART_ctrl_sw2hw_t;

  ------------------------------------
  -- Structure UART_t
  ------------------------------------
  type UART_sw2hw_t is record
    data : UART_data_sw2hw_t;
    ctrl : UART_ctrl_sw2hw_t;
  end record UART_sw2hw_t;

  type UART_hw2sw_t is record
    data : UART_data_hw2sw_t;
  end record UART_hw2sw_t;

  constant UART_ADDR_WIDTH : natural := 1;
  constant UART_DATA_WIDTH : natural := 8;

end package UART_csr_pkg;
