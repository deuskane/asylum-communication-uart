library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;

library work;
use     work.math_pkg.ALL;

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
    parity_odd_i    : in  std_logic
  );
end uart_rx_axis;

architecture rtl of uart_rx_axis is
  -- Define constant 
  constant WIDTH_CNT                      : natural := clog2(WIDTH+3);
  constant UART_BIT_CNT_WITHOUT_PARITY    : unsigned(WIDTH_CNT-1 downto 0) := to_unsigned(WIDTH+1,WIDTH_CNT);
  constant UART_BIT_CNT_WITH_PARITY       : unsigned(WIDTH_CNT-1 downto 0) := UART_BIT_CNT_WITHOUT_PARITY+1;

  constant BIT_START                      : natural := 0;
  constant BIT_DATA_LSB                   : natural := BIT_START+1;
  constant BIT_DATA_MSB                   : natural := BIT_DATA_LSB+WIDTH-1;
  constant BIT_PARITY                     : natural := BIT_DATA_MSB+1;
  constant BIT_MSB                        : natural := WIDTH+2-1;
  
  type     state_t is (IDLE, ACTIVE, STOP);
  signal   state_r                        : state_t;
  
  -- Déclaration des registres internes
  signal   uart_rx_data_r                 : std_logic_vector(BIT_MSB     downto 0); 
  signal   uart_rx_bit_cnt_r              : unsigned        (WIDTH_CNT-1 downto 0);
  signal   parity_bit_r                   : std_logic;
  
begin

  baud_tick_en_o <= '1' when state_r = ACTIVE else
                    '0';
  
  -- Logique de réception UART
  process(clk_i, arst_b_i)
  begin
    if arst_b_i = '0'
    then
      uart_rx_data_r    <= (others => '0');
      uart_rx_bit_cnt_r <= (others => '0');
      m_axis_tvalid_o   <= '0';
      state_r           <= IDLE;
      
    elsif rising_edge(clk_i)
    then
      -- FIFO consume the character
      if m_axis_tready_i = '1'
      then
        m_axis_tvalid_o <= '0';
      end if;

      case state_r is
        when IDLE => 
          -- No transmission, wait START Bit
          if uart_rx_i = '0'
          then
            state_r          <= ACTIVE;
            
            -- Update counter depending parity to be transmit
            if (parity_enable_i = '1')
            then
              uart_rx_bit_cnt_r <= UART_BIT_CNT_WITH_PARITY;
            else
              uart_rx_bit_cnt_r <= UART_BIT_CNT_WITHOUT_PARITY;
            end if;     

          end if;
        when ACTIVE =>
        -- Reception in progress, have tick ?
          if baud_tick_half_i = '1'
          then
            uart_rx_data_r    <= uart_rx_i & uart_rx_data_r(BIT_MSB downto 1); -- Décalage à gauche
            uart_rx_bit_cnt_r <= uart_rx_bit_cnt_r - 1;

            -- Last bit, go inactive
            if uart_rx_bit_cnt_r = 0
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

end rtl;
