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
Interruption Status Register

### [3:0] value
0: interrupt is inactive, 1: interrupt is active

## 0x1 imr
Interruption Mask Register

### [3:0] enable
0: interrupt is disable, 1: interrupt is enable

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
Baud Tick Counter Max LSB. Must be equal to (Clock Frequency (Hz) / Baud Rate)-1

### [7:0] value
Baud Tick Counter Max LSB

## 0x7 baud_tick_cnt_max_msb
Baud Tick Counter Max MSB. Must be equal to (Clock Frequency (Hz) / Baud Rate)-1

### [7:0] value
Baud Tick Counter Max MSB

