# UART
CSR for UART

| Address | Registers |
|---------|-----------|
|0x0|data|
|0x1|ctrl|

## 0x0 data
Write : data to tansmit, Read : data to receive

### [7:0] value
Data TX or Data RX

## 0x1 ctrl
Control Register

### [0:0] tx_enable
0 : TX is disable, 1 : TX is enable

### [1:1] tx_parity_enable
0 : Parity is disable, 1 : Parity is enable

### [2:2] tx_parity_odd
0 : Parity is even, 1 : Parity is odd

### [4:4] rx_enable
0 : RX is disable, 1 : RX is enable

### [5:5] rx_parity_enable
0 : Parity is disable, 1 : Parity is enable

### [6:6] rx_parity_odd
0 : Parity is even, 1 : Parity is odd

### [7:7] rx_use_loopback
0 : UART RX is connected to UART RX Input, 1 : UART RX is connected to UART TX

