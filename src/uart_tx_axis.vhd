-------------------------------------------------------------------------------
-- Title      : uart_tx_axis
-- Project    : 
-------------------------------------------------------------------------------
-- File       : uart_tx_axis.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2025-01-21
-- Last update: 2025-01-21
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2025
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2025-01-21  1.0      mrosiere Created
-------------------------------------------------------------------------------

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;

library work;
use     work.math_pkg.ALL;

entity uart_tx_axis is
  generic (
    WIDTH           : natural := 8
    );
  port (
    clk_i           : in  std_logic;
    arst_b_i        : in  std_logic;
    s_axis_tdata_i  : in  std_logic_vector(WIDTH-1 downto 0);
    s_axis_tvalid_i : in  std_logic;
    s_axis_tready_o : out std_logic;
    uart_tx_o       : out std_logic;
    baud_tick_i     : in  std_logic;
    parity_enable_i : in  std_logic;
    parity_odd_i    : in  std_logic
  );
end uart_tx_axis;

architecture rtl of uart_tx_axis is
  constant WIDTH_CNT                      : natural := clog2(WIDTH+3);
  constant UART_BIT_CNT_WITHOUT_PARITY    : unsigned(WIDTH_CNT-1 downto 0) := to_unsigned(WIDTH+1,WIDTH_CNT);
  constant UART_BIT_CNT_WITH_PARITY       : unsigned(WIDTH_CNT-1 downto 0) := UART_BIT_CNT_WITHOUT_PARITY+1;
  
-- Déclaration des registres internes
  signal   uart_tx_data_r                 : std_logic_vector(WIDTH+2  -1 downto 0);
  signal   uart_tx_bit_cnt_r              : unsigned        (WIDTH_CNT-1 downto 0);
  signal   uart_tx_active_r               : std_logic;
  signal   uart_tx_r                      : std_logic;
  signal   parity_bit                     : std_logic;

begin

  -- Assignation des sorties
  s_axis_tready_o <= not uart_tx_active_r;
  uart_tx_o       <=     uart_tx_r;

  -- Calcul du bit de parité
  process(s_axis_tdata_i, parity_enable_i, parity_odd_i)
  begin
    if parity_enable_i = '1' then
      parity_bit <= '0';
      for i in 0 to WIDTH-1 loop
        parity_bit <= parity_bit xor s_axis_tdata_i(i);
      end loop;
      if parity_odd_i = '1' then
        parity_bit <= not parity_bit;
      end if;
    else
      parity_bit <= '1'; -- Pas de parité, bit de stop
    end if;
  end process;

  -- Logique de transmission UART
  process(clk_i, arst_b_i)
  begin
    if arst_b_i = '0'
    then
      uart_tx_data_r    <= (others => '0');
      uart_tx_bit_cnt_r <= (others => '0');
      uart_tx_active_r  <= '0';
      uart_tx_r         <= '1'; -- STOP Bit
    elsif rising_edge(clk_i)
    then

      -- Have transmission ?
      if (uart_tx_active_r = '0')
      then
        -- New Data to transmit ?
        if (s_axis_tvalid_i = '1')
        then
          -- Add start, data and parity bit
          uart_tx_data_r      <= parity_bit & s_axis_tdata_i & '0'; 

          -- Update compteur depending parity to be transmit
          if (parity_enable_i = '1')
          then
            uart_tx_bit_cnt_r <= UART_BIT_CNT_WITH_PARITY;
          else
            uart_tx_bit_cnt_r <= UART_BIT_CNT_WITHOUT_PARITY;
          end if;     

          -- State is in transmisison
          uart_tx_active_r  <= '1';
        end if;
      else
        -- Transmission in progress, have tick ?
        if baud_tick_i = '1'
        then
          uart_tx_r           <= uart_tx_data_r(0);
          uart_tx_data_r      <= '1' & uart_tx_data_r(9 downto 1); -- Décalage à droite
          uart_tx_bit_cnt_r   <= uart_tx_bit_cnt_r - 1;

          -- Last bit, go inactive
          if uart_tx_bit_cnt_r = 0
          then
            uart_tx_active_r <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;
  
end rtl;
