-------------------------------------------------------------------------------
-- Title      : uart_rx_axis
-- Project    : 
-------------------------------------------------------------------------------
-- File       : uart_rx_axis.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2025-01-21
-- Last update: 2026-10-05
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
-- 2026-10-05  1.1      mrosiere Fix data bit 0 lost when parity is enabled
--                               (frame register on WIDTH+3 bits),
--                               restore parity check (parity_error_o)
-------------------------------------------------------------------------------

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;

library asylum;
use     asylum.math_pkg.ALL;
use     asylum.logic_pkg.ALL;
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

    -- Parity status of the last received frame (updated with m_axis_tvalid_o)
    -- 0 : parity ok or parity disabled, 1 : parity error
    parity_error_o  : out std_logic;

    debug_o         : out uart_rx_debug_t
  );
end uart_rx_axis;

architecture rtl of uart_rx_axis is
  -- Define constant 
  -- Frame with parity    : START | DATA[0..WIDTH-1] | PARITY | STOP  (WIDTH+3 samples)
  -- Frame without parity : START | DATA[0..WIDTH-1] |          STOP  (WIDTH+2 samples)
  -- Samples are shifted in from the MSB, so at the end of a frame with parity
  -- the STOP bit is in BIT_STOP, and without parity everything is shifted by
  -- one position toward the MSB (START in bit 1, DATA in bits WIDTH+1..2)
  constant BIT_START                      : natural := 0;
  constant BIT_DATA_LSB                   : natural := BIT_START+1;
  constant BIT_DATA_MSB                   : natural := BIT_DATA_LSB+WIDTH-1;
  constant BIT_PARITY                     : natural := BIT_DATA_MSB+1;
  constant BIT_STOP                       : natural := BIT_PARITY+1;
  constant BIT_MSB                        : natural := WIDTH+2-1;
  
  type     state_t is (IDLE, START, ACTIVE, STOP);
  signal   state_r                        : state_t;
  
  -- Internal registers declaration
  signal   uart_rx_data_r                 : std_logic_vector(BIT_STOP    downto 0); 
  signal   uart_rx_bit_cnt_r              : std_logic_vector(BIT_MSB     downto 0); 
  signal   parity_enable_r                : std_logic;
  signal   parity_odd_r                   : std_logic;
  signal   parity_error_r                 : std_logic;
  
begin
  
  -- UART reception logic
  process(clk_i, arst_b_i)
    variable v_data   : std_logic_vector(WIDTH-1 downto 0);
    variable v_parity : std_logic;
  begin
    if arst_b_i = '0'
    then
      uart_rx_data_r    <= (others => '0');
      uart_rx_bit_cnt_r <= (others => '0');
      m_axis_tvalid_o   <= '0';
      state_r           <= IDLE;
      baud_tick_en_o    <= '0';
      parity_enable_r   <= '0';
      parity_odd_r      <= '0';
      parity_error_r    <= '0';
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

          -- Parity configuration is sampled at the frame start
          parity_enable_r   <= parity_enable_i;
          parity_odd_r      <= parity_odd_i;
          
          -- No transmission, wait START Bit
          if uart_rx_i = '0'
          then
            state_r          <= START;
          end if;
        when START =>
          baud_tick_en_o    <= '1';

          if baud_tick_half_i = '1'
          then
            uart_rx_data_r    <= uart_rx_i & uart_rx_data_r   (BIT_STOP downto 1);
            uart_rx_bit_cnt_r <= '1'       & uart_rx_bit_cnt_r(BIT_MSB  downto 1);

            -- Check for False Start Bit
            if uart_rx_i = '1' then
              state_r        <= IDLE;
              baud_tick_en_o <= '0';
            else
              state_r        <= ACTIVE;
            end if;
          end if;
        when ACTIVE =>
          baud_tick_en_o    <= '1';

          -- Reception in progress, have tick ?
          if baud_tick_half_i = '1'
          then
            -- Shift in data
            uart_rx_data_r    <= uart_rx_i & uart_rx_data_r   (BIT_STOP downto 1);
            uart_rx_bit_cnt_r <= '1'       & uart_rx_bit_cnt_r(BIT_MSB  downto 1);
            
            -- Last bit, go inactive
            if uart_rx_bit_cnt_r(0) = '1'
            then
              state_r          <= STOP;
            end if;
          end if;
        when STOP =>
          state_r         <= IDLE;

          -- Extract data bits (and parity bit)
          if parity_enable_r = '1'
          then
            v_data        := uart_rx_data_r(BIT_DATA_MSB   downto BIT_DATA_LSB  );
            v_parity      := uart_rx_data_r(BIT_PARITY);
            -- Even parity : xor(data,parity) = 0, Odd parity : xor(data,parity) = 1
            parity_error_r<= reduce_xor(v_data) xor v_parity xor parity_odd_r;
          else
            v_data        := uart_rx_data_r(BIT_DATA_MSB+1 downto BIT_DATA_LSB+1);
            parity_error_r<= '0';
          end if;
          
          m_axis_tdata_o  <= v_data;
          m_axis_tvalid_o <= '1';
        when others =>
          state_r         <= IDLE;
      end case;
    end if;
  end process;

  parity_error_o         <= parity_error_r;
  
  debug_o.state          <= std_logic_vector(to_unsigned(state_t'pos(state_r), 2));
  debug_o.baud_tick_half <= baud_tick_half_i;
  debug_o.bit_cnt        <= std_logic_vector(uart_rx_bit_cnt_r(3 downto 0));
  debug_o.parity_error   <= parity_error_r;
end rtl;
