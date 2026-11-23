-------------------------------------------------------------------------------
-- Title      : sbi_UART
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : sbi_UART.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2025-01-21
-- Last update: 2026-11-16
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2017
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version Author  Description
-- 2025-01-21  0.1     mrosiere	Created
-- 2025-03-09  0.2     mrosiere	use unconstrained pbi
-- 2025-03-15  0.3     mrosiere Add CSR
-- 2025-05-14  1.0     mrosiere Add parameter USER_DEFINE_BAUD_TICK and default value
-- 2025-07-09  1.1     mrosiere Add FIFO Depth
-- 2025-08-02  1.2     mrosiere Add RTS / CTS
-- 2025-11-22  1.3     mrosiere Use sbi instead pbi
-- 2026-09-21  1.4     mrosiere cts_b use sync2dff from top to sbi_uart
-- 2026-10-05  1.5     mrosiere Connect RX parity error (debug only, no CSR)
-- 2026-11-16  1.6     mrosiere isr / imr source 0 : TX FIFO empty (was TX FIFO
--                              not empty)
-- 2026-11-16  1.7     mrosiere RX overrun : isr / imr source 4, RTS# deasserted
--                              at DEPTH_RX-2 bytes in the RX FIFO
-- 2026-11-16  1.8     mrosiere RX framing error, parity error and break :
--                              isr / imr sources 5, 6 and 7
-- 2026-11-16  1.9     mrosiere RX_PARITY_ERROR = "drop" : a byte with a
--                              parity error (m_axis_parity_error_o of
--                              uart_rx_axis) is dropped (not in the RX
--                              FIFO, not echoed)
-- 2026-11-17  1.10    mrosiere RX_PARITY_ERROR = "halt" : a byte with a
--                              parity error is stored (or echoed), then RX
--                              is halted (RTS# deasserted) until isr bit 6
--                              is cleared
-- 2026-11-23  1.11    mrosiere TX and RX in uart_core : the loopbacks
--                              (tx_use_loopback, rx_use_loopback) need
--                              both directions, the outputs of a missing
--                              direction come from uart_core. The
--                              synchronizers of uart_rx_i and uart_cts_b_i
--                              are in uart_core : the internal loopbacks
--                              go through them (2 more clock cycles)
-------------------------------------------------------------------------------

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.numeric_std.ALL;
use     ieee.std_logic_textio.all;
use     std.textio.all;

library asylum;
use     asylum.math_pkg.ALL;
use     asylum.uart_pkg.ALL;
use     asylum.GIC_pkg.ALL;
use     asylum.UART_csr_pkg.ALL;
use     asylum.sbi_pkg.all;

entity sbi_UART is
  generic (
    NAME                  : string  := "";
    BAUD_RATE             : integer := 115200;
    CLOCK_FREQ            : integer := 50000000;
    BAUD_TICK_CNT_WIDTH   : integer := 16;
    UART_TX_ENABLE        : boolean := true;
    UART_RX_ENABLE        : boolean := true;
    USER_DEFINE_BAUD_TICK : boolean := true;
    DEPTH_TX              : natural := 0;
    DEPTH_RX              : natural := 0;
    -- Byte received with a parity error (parity error event : isr / imr
    -- source 6) : "keep" : stored in the RX FIFO (or echoed), "drop" :
    -- dropped, "halt" : stored (or echoed), then RX halted until software
    -- clears isr bit 6 (the byte is the last one of the RX FIFO)
    RX_PARITY_ERROR       : string  := "keep";
    
    FILENAME_TX           : string  := "dump_uart_tx.txt";
    FILENAME_RX           : string  := "dump_uart_rx.txt"
    );
  port   (
    clk_i            : in  std_logic;
    arst_b_i         : in  std_logic; -- asynchronous reset

    -- Bus
    sbi_ini_i        : in  sbi_ini_t;
    sbi_tgt_o        : out sbi_tgt_t;
    
    -- To/From IO
    uart_tx_o        : out std_logic; -- Data 
    uart_rx_i        : in  std_logic;

    uart_cts_b_i     : in  std_logic; -- Clear   To Send (Active low)
    uart_rts_b_o     : out std_logic; -- Request To Send (Active low)

    -- Interruption
    it_o             : out std_logic;

    -- Debug
    debug_o          : out uart_debug_t
    );

end entity sbi_UART;

architecture rtl of sbi_UART is

-- synthesis translate_off
  type raw_file_t is file of character;
  file     file_tx                : text open write_mode is FILENAME_TX & ".dbg";
  file     file_rx                : text open write_mode is FILENAME_RX & ".dbg";
  file     file_tx_raw            : raw_file_t open write_mode is FILENAME_TX;
  file     file_rx_raw            : raw_file_t open write_mode is FILENAME_RX;
-- synthesis translate_on

  -- Compute Max baud tick counter
  constant BAUD_TICK_CNT_MAX_INT  : integer := (CLOCK_FREQ / BAUD_RATE) - 1;
  constant BAUD_TICK_CNT_MAX_SLV  : std_logic_vector(BAUD_TICK_CNT_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(BAUD_TICK_CNT_MAX_INT, BAUD_TICK_CNT_WIDTH));

  -- RTS# is deasserted when the RX FIFO holds RX_RTS_LEVEL bytes or more :
  -- the remote transmitter can still send RX_RTS_MARGIN bytes (+1 byte
  -- pending in uart_rx_axis) after RTS# deassertion without overrun
  constant RX_RTS_MARGIN          : natural := 2;
  constant RX_RTS_LEVEL           : natural := max(DEPTH_RX - RX_RTS_MARGIN, 1);

  -- Policy on a byte received with a parity error
  constant RX_PARITY_ERROR_DROP   : boolean := RX_PARITY_ERROR = "drop";
  constant RX_PARITY_ERROR_HALT   : boolean := RX_PARITY_ERROR = "halt";

  -- Echo mode (tx_use_loopback) and internal loopback (rx_use_loopback)
  -- need both directions
  constant LOOPBACK_ENABLE        : boolean := UART_TX_ENABLE and UART_RX_ENABLE;

  signal   uart_tx                : std_logic;
  signal   uart_rx                : std_logic;

  signal   uart_cts_b             : std_logic;
  signal   uart_rts_b             : std_logic;

 
  signal   tx_tdata               : std_logic_vector(8-1 downto 0);
  signal   tx_tvalid              : std_logic;
  signal   tx_tready              : std_logic;
           
  signal   rx_tdata               : std_logic_vector(8-1 downto 0);
  signal   rx_data_parity_error   : std_logic;
  signal   rx_tvalid              : std_logic;
  signal   rx_tready              : std_logic;
  signal   rx_drop                : std_logic;
  signal   rx_halt                : std_logic;
  signal   rx_sink_tvalid         : std_logic;
  signal   rx_sink_tready         : std_logic;
 
  signal   rx_err_overrun         : std_logic;
  signal   rx_err_framing         : std_logic;
  signal   rx_err_parity          : std_logic;
  signal   rx_err_break           : std_logic;
  signal   rx_fifo_push           : std_logic;
  signal   rx_fifo_pop            : std_logic;
  signal   rx_fifo_nb_elt_r       : natural range 0 to DEPTH_RX;
  signal   rx_fifo_almost_full    : std_logic;
           
  signal   tx_enable              : std_logic;
  signal   tx_parity_enable       : std_logic;
  signal   tx_parity_odd          : std_logic;
  signal   tx_use_loopback        : std_logic;
  signal   cts_enable             : std_logic;
  
  signal   rx_enable              : std_logic;
  signal   rx_parity_enable       : std_logic;
  signal   rx_parity_odd          : std_logic;
  signal   rx_use_loopback        : std_logic;
  signal   rts_enable             : std_logic;
           
  signal   sw2hw                  : UART_sw2hw_t;
  signal   hw2sw                  : UART_hw2sw_t;

  signal   baud_tick_cnt_max      : std_logic_vector(16-1 downto 0);

  signal   it                     : std_logic_vector(8-1 downto 0);
  signal   it_rx_full             : std_logic;
  signal   it_rx_empty_b          : std_logic;
  signal   it_rx_parity           : std_logic;
  signal   it_tx_full             : std_logic;
  signal   it_tx_empty            : std_logic;
  
begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- Parameters checks
  -----------------------------------------------------------------------------
  -- RX_PARITY_ERROR : "keep", "drop" or "halt"
  assert (RX_PARITY_ERROR = "keep") or (RX_PARITY_ERROR = "drop") or (RX_PARITY_ERROR = "halt")
    report "sbi_UART : RX_PARITY_ERROR must be ""keep"", ""drop"" or ""halt"" (""" & RX_PARITY_ERROR & """)"
    severity failure;

  -----------------------------------------------------------------------------
  -- Output of UART
  -----------------------------------------------------------------------------
  uart_tx_o            <= uart_tx;
  uart_rts_b_o         <= uart_rts_b;
  
  -----------------------------------------------------------------------------
  -- CSR Instance
  -----------------------------------------------------------------------------
  ins_csr : UART_registers
    generic map(
      MODULE_NAME           => NAME,
      USER_DEFINE_BAUD_TICK => USER_DEFINE_BAUD_TICK,
      BAUD_TICK_CNT_MAX     => BAUD_TICK_CNT_MAX_SLV,
      DEPTH_TX              => DEPTH_TX,
      DEPTH_RX              => DEPTH_RX
      )
    port map(
      clk_i                 => clk_i           ,
      arst_b_i              => arst_b_i        ,
      sbi_ini_i             => sbi_ini_i       ,
      sbi_tgt_o             => sbi_tgt_o       ,
      sw2hw_o               => sw2hw           ,
      hw2sw_i               => hw2sw   
      );

  -- Baud Tick on 16b
  baud_tick_cnt_max    <= (sw2hw.baud_tick_cnt_max_msb.value &
                           sw2hw.baud_tick_cnt_max_lsb.value);

  -----------------------------------------------------------------------------
  -- UART TX and RX
  -----------------------------------------------------------------------------
  -- UART TX CSR Input
  tx_enable            <= sw2hw.ctrl_tx.tx_enable       (0);
  tx_parity_enable     <= sw2hw.ctrl_tx.tx_parity_enable(0);
  tx_parity_odd        <= sw2hw.ctrl_tx.tx_parity_odd   (0);
  tx_use_loopback      <= sw2hw.ctrl_tx.tx_use_loopback (0) when LOOPBACK_ENABLE else
                          '0';
  cts_enable           <= sw2hw.ctrl_tx.cts_enable      (0);

  -- UART RX CSR Input
  rx_enable            <= sw2hw.ctrl_rx.rx_enable       (0);
  rx_parity_enable     <= sw2hw.ctrl_rx.rx_parity_enable(0);
  rx_parity_odd        <= sw2hw.ctrl_rx.rx_parity_odd   (0);
  rx_use_loopback      <= sw2hw.ctrl_rx.rx_use_loopback (0) when LOOPBACK_ENABLE else
                          '0';
  rts_enable           <= sw2hw.ctrl_rx.rts_enable      (0);

  -- A missing direction (UART_TX_ENABLE / UART_RX_ENABLE = false) has
  -- constant outputs : TX : line idle, writes to data accepted and dropped
  -- (tx_tready = 1) ; RX : no byte, no error
  -- uart_rx and uart_cts_b (pads or internal loopbacks) are synchronized
  -- in uart_core (sync2dffrn, 2 clock cycles)
  ins_uart_core : uart_core
    generic map
    (TX_ENABLE               => UART_TX_ENABLE
    ,RX_ENABLE               => UART_RX_ENABLE
    ,WIDTH                   => 8
    ,BAUD_TICK_CNT_WIDTH     => BAUD_TICK_CNT_WIDTH
    )
    port map
    (clk_i                   => clk_i
    ,arst_b_i                => arst_b_i
    ,cfg_baud_tick_cnt_max_i => baud_tick_cnt_max
    ,cfg_tx_enable_i         => tx_enable
    ,cfg_tx_parity_enable_i  => tx_parity_enable
    ,cfg_tx_parity_odd_i     => tx_parity_odd
    ,cfg_rx_enable_i         => rx_enable
    ,cfg_rx_parity_enable_i  => rx_parity_enable
    ,cfg_rx_parity_odd_i     => rx_parity_odd
    ,s_axis_tdata_i          => tx_tdata
    ,s_axis_tvalid_i         => tx_tvalid
    ,s_axis_tready_o         => tx_tready
    ,uart_tx_o               => uart_tx
    ,uart_cts_b_i            => uart_cts_b
    ,uart_rx_i               => uart_rx
    ,m_axis_tdata_o          => rx_tdata
    ,m_axis_parity_error_o   => rx_data_parity_error -- Parity error of rx_tdata
    ,m_axis_tvalid_o         => rx_tvalid
    ,m_axis_tready_i         => rx_tready
    ,err_overrun_o           => rx_err_overrun
    ,err_parity_o            => rx_err_parity
    ,err_framing_o           => rx_err_framing
    ,err_break_o             => rx_err_break
    ,debug_o                 => debug_o
    );

  -----------------------------------------------------------------------------
  -- UART TX : data written by software, or received bytes in echo mode
  -----------------------------------------------------------------------------
  tx_tdata             <= sw2hw.data.value when tx_use_loopback = '0' else
                          rx_tdata ;
  tx_tvalid            <= sw2hw.data.valid when tx_use_loopback = '0' else
                          rx_sink_tvalid;
  hw2sw.data.ready     <= tx_tready        when tx_use_loopback = '0' else
                          '1';-- Always accept 
  uart_cts_b           <= '0'              when cts_enable      = '0' else -- Always Active
                          uart_cts_b_i     when tx_use_loopback = '0' else
                          uart_rts_b;                                      -- Loop With RTS from RX

  -----------------------------------------------------------------------------
  -- UART RX : pad or internal loopback ; received bytes to software, or to
  -- TX in echo mode
  -----------------------------------------------------------------------------
  uart_rx              <= uart_tx          when rx_use_loopback = '1' else
                          uart_rx_i;

  hw2sw.data.value     <= rx_tdata         when tx_use_loopback = '0' else (others => '0');
  hw2sw.data.valid     <= rx_sink_tvalid   when tx_use_loopback = '0' else '0';
  rx_sink_tready       <= sw2hw.data.ready when tx_use_loopback = '0' else tx_tready;

  -- Policy on a byte received with a parity error (rx_data_parity_error = 1) :
  -- "drop" : the byte is consumed (rx_tready forced to 1) and not given
  -- to the sinks. "halt" : the byte is given to the sink, which sets isr
  -- bit 6 (it_rx_parity) at the clock edge of the transfer : RX is
  -- halted until software clears this bit, no byte is given to the sinks
  -- (the next byte waits in uart_core, the following ones are
  -- overruns), so the byte with the parity error is the last byte of the
  -- RX FIFO. rx_sink_tvalid is the valid of every sink : RX FIFO
  -- (hw2sw.data, RX FIFO level), TX in echo mode, simulation dump
  rx_drop              <= rx_data_parity_error when RX_PARITY_ERROR_DROP else
                          '0';
  rx_halt              <= sw2hw.isr.value(6) when RX_PARITY_ERROR_HALT else
                          '0';
  rx_sink_tvalid       <= rx_tvalid and not rx_drop and not rx_halt;
  rx_tready            <= (rx_sink_tready or rx_drop) and not rx_halt;

  -- Parity error event : end of the frame ("keep", "drop", a frame
  -- dropped by an overrun included), or transfer of the byte to the
  -- sink ("halt" : a frame dropped by an overrun only raises the overrun
  -- event, a byte waiting for room in the RX FIFO raises it when it
  -- enters the RX FIFO)
  it_rx_parity         <= (rx_sink_tvalid and rx_tready and rx_data_parity_error) when RX_PARITY_ERROR_HALT else
                          rx_err_parity;

  -----------------------------------------------------------------------------
  -- UART RX : RTS#
  -----------------------------------------------------------------------------
  gen_uart_rx: if UART_RX_ENABLE = true
  generate
    -- RTS# is registered : no glitch on the pad from the combinational
    -- comparison of the RX FIFO level. Also deasserted while RX is halted
    -- ("halt"), so that a flow-controlled sender stops
    process (clk_i, arst_b_i) is
    begin
      if arst_b_i = '0'
      then
        uart_rts_b         <= '0';
      elsif rising_edge(clk_i)
      then
        if rts_enable = '0'
        then
          uart_rts_b       <= '0';
        else
          uart_rts_b       <= rx_fifo_almost_full or rx_halt;
        end if;
      end if;
    end process;

    -- Number of bytes in the RX FIFO, tracked with the FIFO handshakes
    -- (csr_fifo does not export its number of elements nor its pop) :
    -- push = byte written by uart_core, pop = read of data by software.
    -- csr_fifo pops on the cycle where the read of data is not blocked
    -- (RX FIFO not empty) : the cycle where the SBI access completes, so a
    -- blocking read lasting several cycles is one pop
    gen_rx_fifo: if DEPTH_RX > 0
    generate
      rx_fifo_push <= hw2sw.data.valid and sw2hw.data.ready;
      rx_fifo_pop  <= sbi_ini_i.cs and sbi_ini_i.re and not sw2hw.data.hw2sw_empty
                      when unsigned(sbi_ini_i.addr(UART_ADDR_WIDTH-1 downto 0)) = UART_DATA else
                      '0';

      process (clk_i, arst_b_i) is
      begin
        if arst_b_i = '0'
        then
          rx_fifo_nb_elt_r <= 0;
        elsif rising_edge(clk_i)
        then
          if    (rx_fifo_push = '1') and (rx_fifo_pop = '0')
          then
            rx_fifo_nb_elt_r <= rx_fifo_nb_elt_r + 1;
          elsif (rx_fifo_push = '0') and (rx_fifo_pop = '1')
          then
            rx_fifo_nb_elt_r <= rx_fifo_nb_elt_r - 1;
          end if;
        end if;
      end process;

      rx_fifo_almost_full <= '1' when rx_fifo_nb_elt_r >= RX_RTS_LEVEL else
                             '0';
    end generate gen_rx_fifo;

    gen_rx_fifo_b: if DEPTH_RX = 0
    generate
      -- No FIFO : RTS# deasserted while a received byte is pending
      rx_fifo_almost_full <= it_rx_full;
    end generate gen_rx_fifo_b;
  end generate gen_uart_rx;

  gen_uart_rx_b: if UART_RX_ENABLE = false
  generate
    uart_rts_b         <= '0';
  end generate gen_uart_rx_b;

  -----------------------------------------------------------------------------
  -- Interruptions
  -----------------------------------------------------------------------------
  -- Sources : levels [0] TX FIFO empty, [1] TX FIFO full,
  --                  [2] RX FIFO not empty, [3] RX FIFO full,
  --           events (one cycle pulses) [4] RX overrun, [5] RX framing error,
  --                  [6] RX parity error, [7] RX break
  -- With RX_PARITY_ERROR = "halt", isr bit 6 also halts RX until it is
  -- cleared (rx_halt)
  -- GIC_core sets the isr bit of an active source every cycle, and the bit
  -- stays set until software writes 1 to it : no local sticky flag for the
  -- events. Software polls the FIFO state by clearing the bits 3:0, then
  -- reading isr (read wait state)
  it_rx_full    <=     sw2hw.data.hw2sw_full ;
  it_rx_empty_b <= not sw2hw.data.hw2sw_empty;
  it_tx_full    <=     sw2hw.data.sw2hw_full ;
  it_tx_empty   <=     sw2hw.data.sw2hw_empty;
  it            <= (rx_err_break   &
                    it_rx_parity   &
                    rx_err_framing &
                    rx_err_overrun &
                    it_rx_full     &  
                    it_rx_empty_b  & 
                    it_tx_full     & 
                    it_tx_empty    
                    );
  hw2sw.isr.we  <= '1';
  
  ins_GIC_core : GIC_core
  port map(
    itm_o     => it_o            ,
    its_i     => it,
    isr_i     => sw2hw.isr.value ,
    isr_o     => hw2sw.isr.value ,
    imr_i     => sw2hw.imr.enable
    );

  -----------------------------------------------------------------------------
  -- Debug
  -----------------------------------------------------------------------------

-- synthesis translate_off
  process
  begin
    report "Clock Frequency       : " & integer'image(CLOCK_FREQ);
    report "Baud Rate             : " & integer'image(BAUD_RATE);
    report "Baud Tick Counter Max : " & integer'image(BAUD_TICK_CNT_MAX_INT);
    report "Baud Tick Counter Div2: " & integer'image(BAUD_TICK_CNT_MAX_INT/2);
    wait;
  end process;

  process (clk_i) is
    variable line_buffer : line;
    variable line_raw    : line;
  begin  -- process

    if rising_edge(clk_i)
    then

      -- No TX : the bytes written to data are dropped, not sent
      if (tx_tvalid and tx_tready) = '1' and UART_TX_ENABLE
      then
        write    (line_buffer, tx_tdata);
        write    (line_buffer, string'(" - 0x"));
        write    (line_buffer, to_hstring(tx_tdata));
        write    (line_buffer, string'(" - "));
        write    (line_buffer, character'val(to_integer(unsigned(tx_tdata))));
        writeline(file_tx, line_buffer);

        write    (file_tx_raw, character'val(to_integer(unsigned(tx_tdata))));
        flush    (file_tx_raw);
      end if;

      if (rx_sink_tvalid and rx_tready)
      then
        write    (line_buffer, rx_tdata);
        write    (line_buffer, string'(" - 0x"));
        write    (line_buffer, to_hstring(rx_tdata));
        write    (line_buffer, string'(" - "));
        write    (line_buffer, character'val(to_integer(unsigned(rx_tdata))));
        writeline(file_rx, line_buffer);

        write    (file_rx_raw, character'val(to_integer(unsigned(rx_tdata))));
        flush    (file_rx_raw);
      end if;
      
    end if;
  end process;
-- synthesis translate_on
  
end architecture rtl;
