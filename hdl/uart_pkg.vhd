library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;
library work;
use     work.pbi_pkg.all;

package uart_pkg is
-- [COMPONENT_INSERT][BEGIN]
component uart_rx_axis is
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
    parity_odd_i    : in  std_logic
  );
end component uart_tx_axis;

component pbi_UART is
  generic (
    BAUD_RATE             : integer := 115200;
    CLOCK_FREQ            : integer := 50000000;
    BAUD_TICK_CNT_WIDTH   : integer := 16;
    UART_TX_ENABLE        : boolean := true;
    UART_RX_ENABLE        : boolean := true;
    USER_DEFINE_BAUD_TICK : boolean := true;
    DEPTH_TX              : natural := 0;
    DEPTH_RX              : natural := 0;
    
    FILENAME_TX           : string  := "dump_uart_tx.txt";
    FILENAME_RX           : string  := "dump_uart_rx.txt"
    );
  port   (
    clk_i            : in  std_logic;
    arst_b_i         : in  std_logic; -- asynchronous reset

    -- Bus
    pbi_ini_i        : in  pbi_ini_t;
    pbi_tgt_o        : out pbi_tgt_t;
    
    -- To/From IO
    uart_tx_o        : out std_logic; -- Data 
    uart_rx_i        : in  std_logic;

    uart_cts_b_i     : in  std_logic; -- Clear   To Send (Active low)
    uart_rts_b_o     : out std_logic; -- Request To Send (Active low)

    -- Interruption
    it_o             : out std_logic

    );

end component pbi_UART;

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

-- [COMPONENT_INSERT][END]

end uart_pkg;
