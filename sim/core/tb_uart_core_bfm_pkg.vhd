-------------------------------------------------------------------------------
-- Title      : tb_uart_core_bfm_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_uart_core_bfm_pkg.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Helpers of the tb_uart_core scenarios : inputs of the DUT
--              (tb_req), outputs of the DUT and error pulse counters
--              (tb_rsp), configuration, AXI-Stream transfers, UART frames
--              sent on uart_rx_i and checked on uart_tx_o (UVVM UART BFM),
--              checks, reset pulse.
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-23  1.0      mrosiere Created
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library bitvis_vip_uart;
use     bitvis_vip_uart.uart_bfm_pkg.all;

library asylum;
use     asylum.uart_pkg.all;

package tb_uart_core_bfm_pkg is

  constant C_TB_SCOPE      : string  := "TB_UART_CORE_BFM";

  constant C_CLK_PERIOD    : time    := 20 ns; -- 50 MHz

  -- Baud rates : cfg_baud_tick_cnt_max_i = clock cycles per bit - 1
  constant C_CNT_FAST      : natural := 15;    -- 16  cycles per bit (3.125 Mbaud)
  constant C_CNT_SLOW      : natural := 433;   -- 434 cycles per bit (115200 baud)

  -- Longest wait of a transfer : 4 frames (with parity) at the slow baud rate
  constant C_TIMEOUT       : time    := 4 * 11 * (C_CNT_SLOW+1) * C_CLK_PERIOD;

  subtype  byte_t is std_logic_vector(8-1 downto 0);
  type     byte_array_t is array (natural range <>) of byte_t;

  -- Patterns : data bit 0 at 1 and at 0, both parities
  constant PATTERNS        : byte_array_t := (x"A5", x"5A", x"01", x"80", x"FF", x"00");

  type     parity_array_t is array (natural range <>) of t_parity;
  constant PARITIES        : parity_array_t := (PARITY_NONE, PARITY_EVEN, PARITY_ODD);

  -- Inputs of the DUT, driven by the scenario
  type tb_req_t is record
    cnt_max          : natural;     -- cfg_baud_tick_cnt_max_i
    tx_enable        : std_logic;   -- cfg_tx_enable_i
    tx_parity_enable : std_logic;   -- cfg_tx_parity_enable_i
    tx_parity_odd    : std_logic;   -- cfg_tx_parity_odd_i
    rx_enable        : std_logic;   -- cfg_rx_enable_i
    rx_parity_enable : std_logic;   -- cfg_rx_parity_enable_i
    rx_parity_odd    : std_logic;   -- cfg_rx_parity_odd_i
    s_tdata          : byte_t;      -- s_axis_tdata_i
    s_tvalid         : std_logic;   -- s_axis_tvalid_i
    cts_b            : std_logic;   -- uart_cts_b_i
    rx               : std_logic;   -- uart_rx_i (UART BFM), without loopback
    loopback         : boolean;     -- true : uart_rx_i = uart_tx_o
    m_tready         : std_logic;   -- m_axis_tready_i
  end record tb_req_t;

  -- Inputs idle : both directions disabled, no parity, fast baud rate, CTS#
  -- active, line idle, no loopback
  constant C_TB_REQ_IDLE   : tb_req_t := (cnt_max          => C_CNT_FAST,
                                          tx_enable        => '0',
                                          tx_parity_enable => '0',
                                          tx_parity_odd    => '0',
                                          rx_enable        => '0',
                                          rx_parity_enable => '0',
                                          rx_parity_odd    => '0',
                                          s_tdata          => x"00",
                                          s_tvalid         => '0',
                                          cts_b            => '0',
                                          rx               => '1',
                                          loopback         => false,
                                          m_tready         => '0');

  -- Outputs of the DUT and number of pulses of each error output since the
  -- reset
  type tb_rsp_t is record
    s_tready         : std_logic;   -- s_axis_tready_o
    tx               : std_logic;   -- uart_tx_o
    m_tdata          : byte_t;      -- m_axis_tdata_o
    m_parity_error   : std_logic;   -- m_axis_parity_error_o
    m_tvalid         : std_logic;   -- m_axis_tvalid_o
    err_overrun      : std_logic;   -- err_overrun_o
    err_parity       : std_logic;   -- err_parity_o
    err_framing      : std_logic;   -- err_framing_o
    err_break        : std_logic;   -- err_break_o
    nb_overrun       : natural;     -- Pulses of err_overrun_o
    nb_parity        : natural;     -- Pulses of err_parity_o
    nb_framing       : natural;     -- Pulses of err_framing_o
    nb_break         : natural;     -- Pulses of err_break_o
    debug            : uart_debug_t;-- debug_o
  end record tb_rsp_t;

  -- uart_expect is never terminated
  signal   uart_terminate  : std_logic := '0';

  -- Duration of a frame (start, 8 data bits, parity, stop)
  function frame_time
    (constant cnt_max  : in    natural
    ) return time;

  -- Configuration of the UVVM UART BFM
  function uart_config
    (constant cnt_max  : in    natural
    ;constant parity   : in    t_parity
    ) return t_uart_bfm_config;

  -- The inputs of the DUT are driven on the falling edge of the clock

  -- cfg_tx_* (enable, parity)
  procedure set_tx
    (constant enable   : in    std_logic
    ;constant parity   : in    t_parity
    ;signal   clk      : in    std_logic
    ;signal   tb_req   : inout tb_req_t
    );

  -- cfg_rx_* (enable, parity)
  procedure set_rx
    (constant enable   : in    std_logic
    ;constant parity   : in    t_parity
    ;signal   clk      : in    std_logic
    ;signal   tb_req   : inout tb_req_t
    );

  -- Byte on s_axis (s_axis_tvalid_i = 1), without waiting for the transfer
  procedure axis_put
    (constant data     : in    byte_t
    ;signal   clk      : in    std_logic
    ;signal   tb_req   : inout tb_req_t
    );

  -- Wait for the transfer of the byte on s_axis, then s_axis_tvalid_i = 0
  procedure axis_wait
    (constant msg      : in    string
    ;signal   tb_req   : inout tb_req_t
    ;signal   tb_rsp   : in    tb_rsp_t
    ;signal   clk      : in    std_logic
    );

  -- axis_put, then axis_wait
  procedure axis_send
    (constant data     : in    byte_t
    ;signal   tb_req   : inout tb_req_t
    ;signal   tb_rsp   : in    tb_rsp_t
    ;signal   clk      : in    std_logic
    );

  -- Wait for a byte on m_axis, check it and its parity error, take it
  -- (m_axis_tready_i = 1 during one cycle)
  procedure axis_expect
    (constant data     : in    byte_t
    ;constant par_err  : in    std_logic
    ;constant msg      : in    string
    ;signal   tb_req   : inout tb_req_t
    ;signal   tb_rsp   : in    tb_rsp_t
    ;signal   clk      : in    std_logic
    );

  -- Send one frame on uart_rx_i (UVVM UART BFM, baud rate tb_req.cnt_max)
  -- parity_error : inverted parity bit
  -- stop_error   : stop bit at 0
  procedure uart_send
    (constant data         : in    byte_t
    ;constant parity       : in    t_parity
    ;signal   tb_req       : inout tb_req_t
    ;constant parity_error : in    boolean := false
    ;constant stop_error   : in    boolean := false
    );

  -- Receive one frame on uart_tx_o and check it (UVVM UART BFM, baud rate
  -- tb_req.cnt_max) : data, parity and stop bits
  procedure uart_check
    (constant data     : in    byte_t
    ;constant parity   : in    t_parity
    ;constant msg      : in    string
    ;signal   tb_req   : in    tb_req_t
    ;signal   tb_rsp   : in    tb_rsp_t
    );

  -- Check of a std_logic (pin, flag)
  procedure chk_bit
    (constant val      : in    std_logic
    ;constant exp      : in    std_logic
    ;constant msg      : in    string
    );

  -- Check of a number of error pulses
  procedure chk_nb
    (constant val      : in    natural
    ;constant exp      : in    natural
    ;constant msg      : in    string
    );

  -- Check that the signal did not move during the last duration
  procedure chk_stable
    (signal   line     : in    std_logic
    ;constant duration : in    time
    ;constant msg      : in    string
    );

  -- Reset pulse, released on a falling edge
  procedure do_reset
    (signal   clk      : in    std_logic
    ;signal   arst_b   : out   std_logic
    );

end package tb_uart_core_bfm_pkg;

package body tb_uart_core_bfm_pkg is

  function frame_time
    (constant cnt_max  : in    natural
    ) return time is
  begin
    return 11 * (cnt_max+1) * C_CLK_PERIOD;
  end function;

  function uart_config
    (constant cnt_max  : in    natural
    ;constant parity   : in    t_parity
    ) return t_uart_bfm_config is
    variable v_config  : t_uart_bfm_config := C_UART_BFM_CONFIG_DEFAULT;
  begin
    v_config.bit_time := (cnt_max+1) * C_CLK_PERIOD;
    v_config.parity   := parity;
    v_config.timeout  := C_TIMEOUT;
    return v_config;
  end function;

  procedure set_tx
    (constant enable   : in    std_logic
    ;constant parity   : in    t_parity
    ;signal   clk      : in    std_logic
    ;signal   tb_req   : inout tb_req_t
    ) is
  begin
    wait until falling_edge(clk);
    log(ID_SEQUENCER, "TX enable " & to_string(enable) & ", " & to_string(parity), C_TB_SCOPE);
    tb_req.tx_enable        <= enable;
    tb_req.tx_parity_enable <= '0' when parity = PARITY_NONE else '1';
    tb_req.tx_parity_odd    <= '1' when parity = PARITY_ODD  else '0';
  end procedure;

  procedure set_rx
    (constant enable   : in    std_logic
    ;constant parity   : in    t_parity
    ;signal   clk      : in    std_logic
    ;signal   tb_req   : inout tb_req_t
    ) is
  begin
    wait until falling_edge(clk);
    log(ID_SEQUENCER, "RX enable " & to_string(enable) & ", " & to_string(parity), C_TB_SCOPE);
    tb_req.rx_enable        <= enable;
    tb_req.rx_parity_enable <= '0' when parity = PARITY_NONE else '1';
    tb_req.rx_parity_odd    <= '1' when parity = PARITY_ODD  else '0';
  end procedure;

  procedure axis_put
    (constant data     : in    byte_t
    ;signal   clk      : in    std_logic
    ;signal   tb_req   : inout tb_req_t
    ) is
  begin
    wait until falling_edge(clk);
    tb_req.s_tdata  <= data;
    tb_req.s_tvalid <= '1';
  end procedure;

  procedure axis_wait
    (constant msg      : in    string
    ;signal   tb_req   : inout tb_req_t
    ;signal   tb_rsp   : in    tb_rsp_t
    ;signal   clk      : in    std_logic
    ) is
  begin
    wait until rising_edge(clk) and tb_rsp.s_tready = '1' for C_TIMEOUT;
    check_value(rising_edge(clk) and tb_rsp.s_tready = '1', error, msg & " : s_axis transfer", C_TB_SCOPE);
    tb_req.s_tvalid <= '0';
  end procedure;

  procedure axis_send
    (constant data     : in    byte_t
    ;signal   tb_req   : inout tb_req_t
    ;signal   tb_rsp   : in    tb_rsp_t
    ;signal   clk      : in    std_logic
    ) is
  begin
    axis_put (data, clk, tb_req);
    axis_wait("Send 0x" & to_hstring(data), tb_req, tb_rsp, clk);
  end procedure;

  procedure axis_expect
    (constant data     : in    byte_t
    ;constant par_err  : in    std_logic
    ;constant msg      : in    string
    ;signal   tb_req   : inout tb_req_t
    ;signal   tb_rsp   : in    tb_rsp_t
    ;signal   clk      : in    std_logic
    ) is
  begin
    if tb_rsp.m_tvalid /= '1'
    then
      wait until tb_rsp.m_tvalid = '1' for C_TIMEOUT;
    end if;
    check_value(tb_rsp.m_tvalid      , '1'    , error, msg & " : m_axis_tvalid_o"      , C_TB_SCOPE);
    check_value(tb_rsp.m_tdata       , data   , error, msg & " : m_axis_tdata_o"       , C_TB_SCOPE);
    check_value(tb_rsp.m_parity_error, par_err, error, msg & " : m_axis_parity_error_o", C_TB_SCOPE);
    -- Transfer on the next rising edge
    tb_req.m_tready <= '1';
    wait until rising_edge(clk);
    tb_req.m_tready <= '0';
    wait until falling_edge(clk);
    check_value(tb_rsp.m_tvalid      , '0'    , error, msg & " : byte taken (m_axis_tvalid_o)", C_TB_SCOPE);
  end procedure;

  procedure uart_send
    (constant data         : in    byte_t
    ;constant parity       : in    t_parity
    ;signal   tb_req       : inout tb_req_t
    ;constant parity_error : in    boolean := false
    ;constant stop_error   : in    boolean := false
    ) is
    variable v_config      : t_uart_bfm_config := uart_config(tb_req.cnt_max, parity);
  begin
    v_config.error_injection.parity_bit_error := parity_error;
    v_config.error_injection.stop_bit_error   := stop_error;
    uart_transmit(data_value => data
                 ,msg        => "Send 0x" & to_hstring(data) & " (" & to_string(parity) & ")"
                 ,tx         => tb_req.rx
                 ,config     => v_config
                 ,scope      => C_TB_SCOPE
                 );
  end procedure;

  procedure uart_check
    (constant data     : in    byte_t
    ;constant parity   : in    t_parity
    ;constant msg      : in    string
    ;signal   tb_req   : in    tb_req_t
    ;signal   tb_rsp   : in    tb_rsp_t
    ) is
  begin
    uart_expect(data_exp       => data
               ,msg            => msg & " (" & to_string(parity) & ")"
               ,rx             => tb_rsp.tx
               ,terminate_loop => uart_terminate
               ,config         => uart_config(tb_req.cnt_max, parity)
               ,scope          => C_TB_SCOPE
               );
  end procedure;

  procedure chk_bit
    (constant val      : in    std_logic
    ;constant exp      : in    std_logic
    ;constant msg      : in    string
    ) is
  begin
    check_value(val, exp, error, msg, C_TB_SCOPE);
  end procedure;

  procedure chk_nb
    (constant val      : in    natural
    ;constant exp      : in    natural
    ;constant msg      : in    string
    ) is
  begin
    check_value(val, exp, error, msg, C_TB_SCOPE);
  end procedure;

  procedure chk_stable
    (signal   line     : in    std_logic
    ;constant duration : in    time
    ;constant msg      : in    string
    ) is
  begin
    check_stable(line, duration, error, msg, C_TB_SCOPE);
  end procedure;

  procedure do_reset
    (signal   clk      : in    std_logic
    ;signal   arst_b   : out   std_logic
    ) is
  begin
    arst_b <= '0';
    wait for 100 ns;
    wait until falling_edge(clk);
    arst_b <= '1';
    wait until rising_edge(clk);
  end procedure;

end package body tb_uart_core_bfm_pkg;
