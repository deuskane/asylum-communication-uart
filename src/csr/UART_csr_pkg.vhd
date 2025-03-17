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
  -- Description : Data with data_oe with mask apply
  -- Width       : 8
  --==================================
    value : std_logic_vector(8-1 downto 0);
  end record UART_data_sw2hw_t;

  type UART_data_hw2sw_t is record
    ready : std_logic;
    valid : std_logic;
  --==================================
  -- Field       : value
  -- Description : Data with data_oe with mask apply
  -- Width       : 8
  --==================================
    value : std_logic_vector(8-1 downto 0);
  end record UART_data_hw2sw_t;

  --==================================
  -- Register    : ctrl
  -- Description : Write : data to tansmit, Read : data to receive
  -- Address     : 0x1
  -- Width       : 8
  -- Sw Access   : rw
  -- Hw Access   : none
  -- Hw Type     : reg
  --==================================
  type UART_ctrl_sw2hw_t is record
    re : std_logic;
    we : std_logic;
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
