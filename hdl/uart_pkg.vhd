-------------------------------------------------------------------------------
-- Title      : uart_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : uart_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: UART types and components
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-05  1.1      mrosiere Add parity_error in uart_rx_debug_t and
--                               parity_error_o in uart_rx_axis
-- 2026-11-16  1.2      mrosiere Add err_overrun_o in uart_rx_axis
-- 2026-11-16  1.3      mrosiere Add err_parity_o, err_framing_o and
--                               err_break_o in uart_rx_axis
-- 2026-11-16  1.4      mrosiere Add RX_PARITY_ERROR in sbi_UART and
--                               m_axis_parity_error_o in uart_rx_axis,
--                               parity_error_o renamed
--                               last_parity_error_o
-- 2026-11-23  1.5      mrosiere Add uart_core
-------------------------------------------------------------------------------

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;
library asylum;
use     asylum.sbi_pkg.all;

package uart_pkg is


  -----------------------------------------------------------------------------
  -- uart_tx_debug_t
  -----------------------------------------------------------------------------
  type uart_tx_debug_t is record
    state   : std_logic;
  end record uart_tx_debug_t;

  -----------------------------------------------------------------------------
  -- uart_rx_debug_t
  -----------------------------------------------------------------------------
  type uart_rx_debug_t is record
    state          : std_logic_vector(2-1 downto 0);
    bit_cnt        : std_logic_vector(4-1 downto 0);
    baud_tick_half : std_logic;
    parity_error   : std_logic; -- Parity error on the last received frame
  end record uart_rx_debug_t;

  -----------------------------------------------------------------------------
  -- uart_debug_t
  -----------------------------------------------------------------------------
  type uart_debug_t is record

    uart_tx : uart_tx_debug_t;
    uart_rx : uart_rx_debug_t;
    
  end record uart_debug_t;

  
-- [COMPONENT_INSERT][BEGIN]
component sbi_UART is
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

end component sbi_UART;

component uart_baud_rate_gen is
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
end component uart_baud_rate_gen;

component uart_core is
  generic (
    TX_ENABLE               : boolean := true  -- Transmitter instantiated
   ;RX_ENABLE               : boolean := true  -- Receiver    instantiated
   ;WIDTH                   : natural := 8     -- Data width
   ;BAUD_TICK_CNT_WIDTH     : natural := 16    -- Width of cfg_baud_tick_cnt_max_i
  );
  port (
    -- Clock and Reset
    clk_i                   : in  std_logic
   ;arst_b_i                : in  std_logic
    -- Configuration
   ;cfg_baud_tick_cnt_max_i : in  std_logic_vector(BAUD_TICK_CNT_WIDTH-1 downto 0) -- Clock cycles per bit - 1 (TX and RX)
   ;cfg_tx_enable_i         : in  std_logic  -- 0 : TX held in reset
   ;cfg_tx_parity_enable_i  : in  std_logic  -- 1 : TX sends a parity bit
   ;cfg_tx_parity_odd_i     : in  std_logic  -- 0 : even, 1 : odd parity
   ;cfg_rx_enable_i         : in  std_logic  -- 0 : RX held in reset
   ;cfg_rx_parity_enable_i  : in  std_logic  -- 1 : RX expects a parity bit
   ;cfg_rx_parity_odd_i     : in  std_logic  -- 0 : even, 1 : odd parity
    -- TX : AXI-Stream input
   ;s_axis_tdata_i          : in  std_logic_vector(WIDTH-1 downto 0)
   ;s_axis_tvalid_i         : in  std_logic
   ;s_axis_tready_o         : out std_logic
    -- TX : To IO
   ;uart_tx_o               : out std_logic
   ;uart_cts_b_i            : in  std_logic  -- Clear To Send (active low), asynchronous
    -- RX : From IO
   ;uart_rx_i               : in  std_logic  -- Asynchronous
    -- RX : AXI-Stream output
   ;m_axis_tdata_o          : out std_logic_vector(WIDTH-1 downto 0)
   ;m_axis_parity_error_o   : out std_logic  -- Parity error of m_axis_tdata_o
   ;m_axis_tvalid_o         : out std_logic
   ;m_axis_tready_i         : in  std_logic
    -- RX : errors, one clock cycle pulses at the end of a frame
   ;err_overrun_o           : out std_logic  -- Byte still pending : new byte dropped
   ;err_parity_o            : out std_logic  -- Parity bit mismatch
   ;err_framing_o           : out std_logic  -- Stop bit sampled at 0
   ;err_break_o             : out std_logic  -- All bits of the frame at 0
    -- Debug
   ;debug_o                 : out uart_debug_t
  );
end component uart_core;

component uart_rx_axis is
  generic (
    WIDTH              : natural := 8
    );
  port (
    clk_i           : in  std_logic;
    arst_b_i        : in  std_logic;

    uart_rx_i       : in  std_logic;

    -- Every received byte is delivered, with its parity error on
    -- m_axis_parity_error_o (except a byte dropped by an overrun)
    m_axis_tdata_o  : out std_logic_vector(WIDTH-1 downto 0);
    m_axis_parity_error_o : out std_logic; -- Parity error of m_axis_tdata_o
    m_axis_tvalid_o : out std_logic;
    m_axis_tready_i : in  std_logic;

    baud_tick_i     : in  std_logic;
    baud_tick_half_i: in  std_logic;
    baud_tick_en_o  : out std_logic;

    parity_enable_i : in  std_logic;
    parity_odd_i    : in  std_logic;

    -- Parity status of the last received frame (updated at the end of each
    -- frame, debug) : 0 : parity ok or parity disabled, 1 : parity error
    last_parity_error_o : out std_logic;

    -- Overrun : one clock cycle pulse when a frame is received while the
    -- previous byte is still pending on m_axis (the new byte is dropped)
    err_overrun_o   : out std_logic;

    -- Errors of the received frame : one clock cycle pulse at the end of the
    -- frame (the byte is delivered on m_axis, unless dropped by an overrun)
    err_parity_o    : out std_logic; -- Parity bit mismatch
    err_framing_o   : out std_logic; -- Stop bit sampled at 0
    err_break_o     : out std_logic; -- Break : all bits of the frame at 0

    debug_o         : out uart_rx_debug_t
  );
end component uart_rx_axis;

component uart_tx_axis is
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
    uart_cts_b_i    : in  std_logic;

    baud_tick_i     : in  std_logic;
    parity_enable_i : in  std_logic;
    parity_odd_i    : in  std_logic;

    debug_o         : out uart_tx_debug_t

    );
end component uart_tx_axis;

-- [COMPONENT_INSERT][END]

end uart_pkg;
