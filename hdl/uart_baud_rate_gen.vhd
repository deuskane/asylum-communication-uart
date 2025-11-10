-------------------------------------------------------------------------------
-- Title      : uart_baud_rate_gen
-- Project    : 
-------------------------------------------------------------------------------
-- File       : uart_baud_rate_gen.vhd
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
-- 2025-05-03  1.1      mrosiere External Baud Tick Counter Generation
-------------------------------------------------------------------------------

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;

entity uart_baud_rate_gen is
  generic
  (
    BAUD_TICK_CNT_WIDTH : integer := 16
  );
  port
  (
    clk_i                   : in  std_logic;
    arst_b_i                : in  std_logic;
    baud_tick_en_i          : in  std_logic;
    baud_tick_o             : out std_logic;
    baud_tick_half_o        : out std_logic;

    cfg_baud_tick_cnt_max_i : in  std_logic_vector(BAUD_TICK_CNT_WIDTH-1 downto 0)
  );
end uart_baud_rate_gen;

architecture rtl of uart_baud_rate_gen is
  -- Déclaration des registres
  signal   cfg_baud_tick_cnt_max      : unsigned(BAUD_TICK_CNT_WIDTH-1 downto 0);
  signal   cfg_baud_tick_cnt_max_div2 : unsigned(BAUD_TICK_CNT_WIDTH-1 downto 1);
  signal   baud_tick_cnt_r            : unsigned(BAUD_TICK_CNT_WIDTH-1 downto 0);
  signal   baud_tick_r                : std_logic;
  signal   baud_tick_half_r           : std_logic;
  signal   baud_tick_en_r             : std_logic;
begin
  cfg_baud_tick_cnt_max      <= unsigned(cfg_baud_tick_cnt_max_i);
  cfg_baud_tick_cnt_max_div2 <= cfg_baud_tick_cnt_max(BAUD_TICK_CNT_WIDTH-1 downto 1);

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

      if baud_tick_en_i = '1'
      then

        -- Détection du front montant de baud_tick_en_i
        if baud_tick_en_r = '0'
        then
          -- Initialisation du compteur à BAUD_TICK_CNT_MAX lors d'un front montant de baud_tick_en_i
          baud_tick_cnt_r <= cfg_baud_tick_cnt_max;
        else
          
          if baud_tick_cnt_r = cfg_baud_tick_cnt_max_div2
          then
            baud_tick_half_r <= '1';
          end if;       

          if baud_tick_cnt_r = 0
          then
            -- Réinitialisation du compteur et génération du tick
            baud_tick_cnt_r <= cfg_baud_tick_cnt_max;
            baud_tick_r     <= '1';
          else
            -- Décrémentation du compteur
            baud_tick_cnt_r <= baud_tick_cnt_r - 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- Assignation de la sortie
  baud_tick_o      <= baud_tick_r;
  baud_tick_half_o <= baud_tick_half_r;

end rtl;
