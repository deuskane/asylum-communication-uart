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

### [0:0] enable_tx
0 : TX is disable, 1 : TX is enable

### [1:1] enable_rx
0 : RX is disable, 1 : RX is enable

### [2:2] parity_enable
0 : Parity is disable, 1 : Parity is enable

### [3:3] parity_odd
0 : Parity is even, 1 : Parity is odd

### [7:7] loopback
0 : UART RX is connected to input, 1 : UART RX is connected to UART TX

