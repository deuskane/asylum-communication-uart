-------------------------------------------------------------------------------
-- Title      : uart_rx_axis
-- Project    : 
-------------------------------------------------------------------------------
-- File       : uart_rx_axis.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2025-01-21
-- Last update: 2025-11-10
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

library asylum;
use     asylum.math_pkg.ALL;
use     asylum.uart_pkg.ALL;

entity uart_rx_axis is
  generic (
    WIDTH           : natural := 8
    );
  port (
    clk_i           : in  std_logic;
    arst_b_i        : in  std_logic;

    uart_rx_i       : in  std_logic;

    m_axis_tdata_o  : out std_logic_vector(WIDTH-1 downto 0);
    m_axis_tvalid_o : out std_logic;
    m_axis_tready_i : in  std_logic;

    baud_tick_i     : in  std_logic;
    baud_tick_half_i: in  std_logic;
    baud_tick_en_o  : out std_logic;

    parity_enable_i : in  std_logic;
    parity_odd_i    : in  std_logic;

    debug_o         : out uart_rx_debug_t
  );
end uart_rx_axis;

architecture rtl of uart_rx_axis is
  -- Define constant 
  constant BIT_START                      : natural := 0;
  constant BIT_DATA_LSB                   : natural := BIT_START+1;
  constant BIT_DATA_MSB                   : natural := BIT_DATA_LSB+WIDTH-1;
  constant BIT_PARITY                     : natural := BIT_DATA_MSB+1;
  constant BIT_MSB                        : natural := WIDTH+2-1;
  
  type     state_t is (IDLE, ACTIVE, STOP);
  signal   state_r                        : state_t;
  
  -- Déclaration des registres internes
  signal   uart_rx_data_r                 : std_logic_vector(BIT_MSB     downto 0); 
  signal   uart_rx_bit_cnt_r              : std_logic_vector(BIT_MSB     downto 0); 
  signal   parity_bit_r                   : std_logic;
  
begin
  
  -- Logique de réception UART
  process(clk_i, arst_b_i)
  begin
    if arst_b_i = '0'
    then
      uart_rx_data_r    <= (others => '0');
      uart_rx_bit_cnt_r <= (others => '0');
      m_axis_tvalid_o   <= '0';
      state_r           <= IDLE;
      baud_tick_en_o    <= '0';
    elsif rising_edge(clk_i)
    then
      baud_tick_en_o    <= '0';

      
      -- FIFO consume the character
      if m_axis_tready_i = '1'
      then
        m_axis_tvalid_o <= '0';
      end if;

      case state_r is
        when IDLE => 

          uart_rx_bit_cnt_r <= (others => '0');

          if (parity_enable_i = '0')
          then
            uart_rx_bit_cnt_r(BIT_MSB) <= '1';
          end if;   
          
          -- No transmission, wait START Bit
          if uart_rx_i = '0'
          then

            state_r          <= ACTIVE;
          end if;
        when ACTIVE =>
          baud_tick_en_o    <= '1';

        -- Reception in progress, have tick ?
          if baud_tick_half_i = '1'
          then
            uart_rx_data_r    <= uart_rx_i & uart_rx_data_r   (BIT_MSB downto 1); -- Décalage à gauche

            uart_rx_bit_cnt_r <= '1'       & uart_rx_bit_cnt_r(BIT_MSB downto 1);
            
            -- Last bit, go inactive
            if uart_rx_bit_cnt_r(0) = '1'
            then
              state_r          <= STOP;
            end if;
          end if;
        when STOP =>
          state_r         <= IDLE;
          m_axis_tdata_o  <= uart_rx_data_r(BIT_DATA_MSB downto BIT_DATA_LSB); -- Extraire les bits de données
          parity_bit_r    <= uart_rx_data_r(BIT_PARITY); -- Extraire le bit de parité
          m_axis_tvalid_o <= '1';
        when others =>
          state_r         <= IDLE;
      end case;
    end if;
  end process;

--  -- Vérification de la parité
--  process(clk_i, arst_b_i)
--  begin
--    if arst_b_i = '0' then
--      -- Réinitialisation
--    elsif rising_edge(clk_i) then
--      if m_axis_tvalid_o = '1' and parity_enable_i = '1' then
--        if parity_odd_i = '1' then
--          if (parity_bit xor reduce_xor(m_axis_tdata_o)) = '0' then
--            -- Erreur de parité impaire
--          end if;
--        else
--          if (parity_bit xor reduce_xor(m_axis_tdata_o)) = '1' then
--            -- Erreur de parité paire
--          end if;
--        end if;
--      end if;
--    end if;
--  end process;

  debug_o.state          <= std_logic_vector(to_unsigned(state_t'pos(state_r), 2));
  debug_o.baud_tick_half <= baud_tick_half_i;
  debug_o.bit_cnt        <= std_logic_vector(uart_rx_bit_cnt_r(3 downto 0));
end rtl;
