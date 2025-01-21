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
    m_axis_tdata_o  : out std_logic_vector(7 downto 0);
    m_axis_tvalid_o : out std_logic;
    m_axis_tready_i : in  std_logic;
    --interrupt       : out std_logic;
    baud_tick_i     : in  std_logic;
    parity_enable_i : in  std_logic;
    parity_odd_i    : in  std_logic
  );
end uart_rx_axis;

architecture rtl of uart_rx_axis is
  constant WIDTH_CNT                      : natural := clog2(WIDTH+3);
  constant UART_BIT_CNT_WITHOUT_PARITY    : unsigned(WIDTH_CNT-1 downto 0) := to_unsigned(WIDTH+1,WIDTH_CNT);
  constant UART_BIT_CNT_WITH_PARITY       : unsigned(WIDTH_CNT-1 downto 0) := UART_BIT_CNT_WITHOUT_PARITY+1;

  -- Déclaration des registres internes
  signal   uart_rx_data_r                 : std_logic_vector(WIDTH+2  -1 downto 0);
  signal   uart_rx_bit_cnt_r              : unsigned        (WIDTH_CNT-1 downto 0);
  signal   uart_rx_active_r               : std_logic;
  signal   parity_bit                     : std_logic;


  function reduce_xor(input_vector : STD_LOGIC_VECTOR) return STD_LOGIC is
    variable temp_result : STD_LOGIC := '0';
  begin
    for i in input_vector'range loop
      temp_result := temp_result xor input_vector(i);
    end loop;
    return temp_result;
  end reduce_xor;


begin

  -- Logique de réception UART
  process(clk_i, arst_b_i)
  begin
    if arst_b_i = '0'
    then
      uart_rx_data_r    <= (others => '0');
      uart_rx_bit_cnt_r <= (others => '0');
      uart_rx_active_r  <= '0';
      m_axis_tvalid_o   <= '0';
      --interrupt         <= '0';
    elsif rising_edge(clk_i)
    then
      if m_axis_tready_i = '1'
      then
        m_axis_tvalid_o <= '0';
      end if;
      -- Have transmission ?
      if uart_rx_active_r = '0'
      then
        -- No transmission, when START Bit
        if baud_tick_i = '1' and uart_rx_i = '0'
        then
          -- Détection du bit de start
          uart_rx_active_r <= '1';

          -- Update compteur depending parity to be transmit
          if (parity_enable_i = '1')
          then
            uart_rx_bit_cnt_r <= UART_BIT_CNT_WITH_PARITY;
          else
            uart_rx_bit_cnt_r <= UART_BIT_CNT_WITHOUT_PARITY;
          end if;     

        end if;
      else
        -- Transmission in progress, have tick ?
        if baud_tick_i = '1'
        then
          uart_rx_data_r    <= uart_rx_i & uart_rx_data_r(9 downto 1); -- Décalage à gauche
          uart_rx_bit_cnt_r <= uart_rx_bit_cnt_r - 1;

          -- Last bit, go inactive
          if uart_rx_bit_cnt_r = 0
          then
            m_axis_tdata_o  <= uart_rx_data_r(8 downto 1); -- Extraire les bits de données
            parity_bit      <= uart_rx_data_r(9); -- Extraire le bit de parité
            m_axis_tvalid_o <= '1';

            --interrupt <= '1'; -- Générer une interruption
            uart_rx_active_r <= '0';
          end if;
        end if;
      end if;
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
