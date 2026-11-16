# UART
CSR for UART

| Address | Registers |
|---------|-----------|
|0x0|isr|
|0x1|imr|
|0x2|data|
|0x4|ctrl_tx|
|0x5|ctrl_rx|
|0x6|baud_tick_cnt_max_lsb|
|0x7|baud_tick_cnt_max_msb|

## 0x0 isr
Interruption Status Register. Each source sets its bit, masked or not (imr only masks it_o), until software writes 1 to it. Polling of the FIFO state : write 1 to clear the bits 3:0, then read isr : the bit of a source still active is set again (1 read wait state : the read right after the clear sees it)

Wait states: read 1, write 0

### [7:0] value
0: interrupt is inactive, 1: interrupt is active. Sources : [0] TX FIFO empty, [1] TX FIFO full, [2] RX FIFO not empty, [3] RX FIFO full (levels), [4] RX overrun (a received byte was dropped), [5] RX framing error (stop bit at 0), [6] RX parity error (byte stored, or dropped if RX_STORE_PARITY_ERROR = false), [7] RX break (all bits of a frame at 0) (events)

## 0x1 imr
Interruption Mask Register

### [7:0] enable
0: interrupt is disable, 1: interrupt is enable. Same bit mapping as isr

## 0x2 data
Write : data to tansmit, Read : data to receive

### [7:0] value
Data TX or Data RX

## 0x4 ctrl_tx
Control Register

### [0:0] tx_enable
0 : TX is disable, 1 : TX is enable

### [1:1] tx_parity_enable
0 : Parity is disable, 1 : Parity is enable

### [2:2] tx_parity_odd
0 : Parity is even, 1 : Parity is odd

### [3:3] tx_use_loopback
0 : UART TX FIFO is connected to CSR, 1 : UART RX FIFO is connected to UART RX FIFO

### [4:4] cts_enable
0 : Clear To Send Disable, 1 : Clear To Send Enable

## 0x5 ctrl_rx
Control Register

### [0:0] rx_enable
0 : RX is disable, 1 : RX is enable

### [1:1] rx_parity_enable
0 : Parity is disable, 1 : Parity is enable

### [2:2] rx_parity_odd
0 : Parity is even, 1 : Parity is odd

### [3:3] rx_use_loopback
0 : UART RX is connected to UART RX Input, 1 : UART RX is connected to UART TX

### [4:4] rts_enable
0 : Request To Send Disable, 1 : Request To Send Enable

## 0x6 baud_tick_cnt_max_lsb
Baud Tick Counter Max LSB. Must be equal to (Clock Frequency (Hz) / Baud Rate)-1. Write it at setup time, with ctrl_tx.tx_enable = ctrl_rx.rx_enable = 0 (baud rate generators held in reset)

### [7:0] value
Baud Tick Counter Max LSB

## 0x7 baud_tick_cnt_max_msb
Baud Tick Counter Max MSB. Must be equal to (Clock Frequency (Hz) / Baud Rate)-1. Write it at setup time, with ctrl_tx.tx_enable = ctrl_rx.rx_enable = 0 (baud rate generators held in reset)

### [7:0] value
Baud Tick Counter Max MSB

