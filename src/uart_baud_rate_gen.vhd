-------------------------------------------------------------------------------
-- Title      : uart_baud_rate_gen
-- Project    : 
-------------------------------------------------------------------------------
-- File       : uart_baud_rate_gen.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2025-01-21
-- Last update: 2025-01-29
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

entity uart_baud_rate_gen is
  generic (
    BAUD_RATE           : integer := 115200;
    CLOCK_FREQ          : integer := 50000000;
    BAUD_TICK_CNT_WIDTH : integer := 16
  );
  port (
    clk_i            : in  std_logic;
    arst_b_i         : in  std_logic;
    baud_tick_en_i   : in  std_logic;
    baud_tick_o      : out std_logic;
    baud_tick_half_o : out std_logic
  );
end uart_baud_rate_gen;

architecture rtl of uart_baud_rate_gen is
  -- Calcul du compteur maximum pour générer le tick de baud
  constant BAUD_TICK_CNT_MAX : integer := (CLOCK_FREQ / BAUD_RATE) - 1;
  constant BAUD_TICK_CNT_DIV2: integer := BAUD_TICK_CNT_MAX/2;

  -- Déclaration des registres
  signal   baud_tick_cnt_r   : unsigned(BAUD_TICK_CNT_WIDTH-1 downto 0) := (others => '0');
  signal   baud_tick_r       : std_logic;
  signal   baud_tick_half_r  : std_logic;
  signal   baud_tick_en_r    : std_logic;
begin

  -- Processus principal pour générer le tick de baud
  process(clk_i, arst_b_i)
  begin
    if arst_b_i = '0'
    then
      -- Réinitialisation asynchrone
      baud_tick_cnt_r <= (others => '0');
      baud_tick_r     <= '0';
      baud_tick_half_r<= '0';
      baud_tick_en_r  <= '0';
    elsif rising_edge(clk_i)
    then

      baud_tick_en_r   <= baud_tick_en_i; 
      baud_tick_r      <= '0';
      baud_tick_half_r <= '0';

      -- Détection du front montant de baud_tick_en_i
      if baud_tick_en_i = '1' and baud_tick_en_r = '0'
      then
        -- Initialisation du compteur à BAUD_TICK_CNT_MAX lors d'un front montant de baud_tick_en_i
        baud_tick_cnt_r <= to_unsigned(BAUD_TICK_CNT_MAX, BAUD_TICK_CNT_WIDTH);
      elsif baud_tick_en_i = '1'
      then
        if baud_tick_cnt_r = BAUD_TICK_CNT_DIV2
        then
          baud_tick_half_r <= '1';
        end if;       

        if baud_tick_cnt_r = 0
        then
          -- Réinitialisation du compteur et génération du tick
          baud_tick_cnt_r <= to_unsigned(BAUD_TICK_CNT_MAX, BAUD_TICK_CNT_WIDTH);
          baud_tick_r     <= '1';
        else
          -- Décrémentation du compteur
          baud_tick_cnt_r <= baud_tick_cnt_r - 1;
        end if;
      end if;
    end if;
  end process;

  -- Assignation de la sortie
  baud_tick_o      <= baud_tick_r;
  baud_tick_half_o <= baud_tick_half_r;

-- synthesis translate_off
  process
  begin
    report "Clock Frequency       : " & integer'image(CLOCK_FREQ);
    report "Baud Rate             : " & integer'image(BAUD_RATE);
    report "Baud Tick Counter Max : " & integer'image(BAUD_TICK_CNT_MAX);
    report "Baud Tick Counter Div2: " & integer'image(BAUD_TICK_CNT_DIV2);
    wait;
  end process;
-- synthesis translate_on

end rtl;
