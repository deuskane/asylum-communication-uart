-------------------------------------------------------------------------------
-- Title      : tb_uart
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : tb_uart.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description: Testbench for SBI UART with clock drift simulation
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
use     asylum.sbi_pkg.all;
use     asylum.uart_pkg.all;
use     asylum.convert_pkg.all; -- Pour to_hstring (assuming it exists)

library uvvm_util;
context uvvm_util.uvvm_util_context;
library bitvis_vip_sbi;
use     bitvis_vip_sbi.sbi_bfm_pkg.all;

entity tb_uart is
end tb_uart;

architecture sim of tb_uart is

  -- Configuration
  constant C_SCOPE         : string  := "TB_UART";
  constant CLOCK_FREQ      : integer := 50_000_000;
  constant BAUD_RATE       : integer := 115_200;
  constant CLK_PERIOD      : time    := 1 sec / CLOCK_FREQ;
  constant BIT_PERIOD      : time    := 1 sec / BAUD_RATE;

  -- Signals
  signal clk_i             : std_logic := '0';
  signal arst_b_i          : std_logic := '0';

  -- Interface SBI
  signal sbi_ini           : sbi_ini_t(addr (SBI_ADDR_WIDTH-1 downto 0), wdata(SBI_DATA_WIDTH-1 downto 0));
  signal sbi_tgt           : sbi_tgt_t(rdata(SBI_DATA_WIDTH-1 downto 0));

  -- UVVM SBI Interface
  signal sbi_if            : t_sbi_if(addr(SBI_ADDR_WIDTH-1 downto 0),
                                      wdata(SBI_DATA_WIDTH-1 downto 0),
                                      rdata(SBI_DATA_WIDTH-1 downto 0));

  -- Interface UART
  signal uart_tx           : std_logic;
  signal uart_rx           : std_logic := '1';
  signal uart_cts_b        : std_logic := '0';
  signal uart_rts_b        : std_logic;
  signal it_o              : std_logic;

begin

  -- Clock and Reset Generation
  clk_i    <= not clk_i after CLK_PERIOD / 2;
  arst_b_i <= '0', '1' after 100 ns;

  -----------------------------------------------------------------------------
  -- DUT: SBI UART
  -----------------------------------------------------------------------------
  ins_dut : entity asylum.sbi_uart
    generic map (
      BAUD_RATE            => BAUD_RATE,
      CLOCK_FREQ           => CLOCK_FREQ,
      DEPTH_TX             => 16,
      DEPTH_RX             => 16
    )
    port map (
      clk_i                => clk_i,
      arst_b_i             => arst_b_i,
      sbi_ini_i            => sbi_ini,
      sbi_tgt_o            => sbi_tgt,
      uart_tx_o            => uart_tx,
      uart_rx_i            => uart_rx,
      uart_cts_b_i         => uart_cts_b,
      uart_rts_b_o         => uart_rts_b,
      it_o                 => it_o,
      debug_o              => open
    );

  -- Mapping UVVM SBI IF to Asylum SBI Ports
  sbi_ini.cs    <= sbi_if.cs;
  sbi_ini.addr  <= std_logic_vector(sbi_if.addr(SBI_ADDR_WIDTH-1 downto 0));
  sbi_ini.re    <= sbi_if.rena;
  sbi_ini.we    <= sbi_if.wena;
  sbi_ini.wdata <= sbi_if.wdata(SBI_DATA_WIDTH-1 downto 0);
  sbi_if.ready  <= sbi_tgt.ready;
  sbi_if.rdata(SBI_DATA_WIDTH-1 downto 0) <= sbi_tgt.rdata;

  -----------------------------------------------------------------------------
  -- Stimulus
  -----------------------------------------------------------------------------
  process
    -- Simplified UART BFM procedure (Transmission to FPGA)
    procedure uart_bfm_send(data : std_logic_vector(7 downto 0); period : time) is
    begin
      log(ID_SEQUENCER, "BFM UART: Sending 0x" & to_hstring(data), C_SCOPE);
      uart_rx <= '0'; -- Start bit
      wait for period;
      for i in 0 to 7 loop
        uart_rx <= data(i);
        wait for period;
      end loop;
      uart_rx <= '1'; -- Stop bit
      wait for period;
    end procedure;

    variable rx_val     : std_logic_vector(7 downto 0);
    variable v_sbi_data : std_logic_vector(SBI_DATA_WIDTH-1 downto 0);
    variable status : std_logic_vector(SBI_DATA_WIDTH-1 downto 0);
  begin
    -- Initialisation
    sbi_if <= init_sbi_if_signals(SBI_ADDR_WIDTH, SBI_DATA_WIDTH);
    wait until arst_b_i = '1';
    wait until rising_edge(clk_i);
    log(ID_SEQUENCER, "Reset released, starting simulation", C_SCOPE);

    sbi_write(to_unsigned(5, SBI_ADDR_WIDTH), x"01", "Read UART", clk_i, sbi_if);

    -- TEST 1: Nominal Reception
    log(ID_LOG_HDR, "Test 1: Nominal Case (115200)", C_SCOPE);
    uart_bfm_send(x"A5", BIT_PERIOD);
    
    -- Wait for data to be available (polling status if available, or simple wait)
    wait for 15 * BIT_PERIOD; 
    
    sbi_check(to_unsigned(2, SBI_ADDR_WIDTH), x"A5", "Check UART RX Nominal", clk_i, sbi_if);

    -- TEST 2: Clock Drift Stress Test (Risk of connection loss)
    log(ID_LOG_HDR, "Test 2: Clock Drift +3% (Stress Test)", C_SCOPE);
    uart_bfm_send(x"55", BIT_PERIOD * 1.03);
    
    wait for 15 * BIT_PERIOD;

    sbi_check(to_unsigned(2, SBI_ADDR_WIDTH), x"55", "Check UART RX Drift +3%", clk_i, sbi_if);

    -- TEST 3: Clock Drift Stress Test (Negative drift)
    log(ID_LOG_HDR, "Test 3: Clock Drift -3% (Stress Test)", C_SCOPE);
    uart_bfm_send(x"3C", BIT_PERIOD * 0.97);
    
    wait for 15 * BIT_PERIOD;

    sbi_check(to_unsigned(2, SBI_ADDR_WIDTH), x"3C", "Check UART RX Drift -3%", clk_i, sbi_if);

    -- TEST 4: Fake Start Bit (Glitch)
    log(ID_LOG_HDR, "Test 4: Fake Start Bit (Glitch)", C_SCOPE);
    uart_rx <= '0';
    wait for BIT_PERIOD / 4; -- Glitch shorter than half bit period
    uart_rx <= '1';
    wait for 10 * BIT_PERIOD;
    sbi_check(to_unsigned(0, SBI_ADDR_WIDTH), x"00", "Check RX FIFO is still empty", clk_i, sbi_if);

    log(ID_LOG_HDR, "Simulation Finished. All tests passed.", C_SCOPE);
    report_alert_counters(FINAL);
    log(ID_LOG_HDR, "SIMULATION COMPLETED", C_SCOPE);

    -- Finish the simulation
    std.env.stop;  
    wait;
  end process;

end sim;
