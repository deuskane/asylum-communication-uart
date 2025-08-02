#ifndef UART_REGISTERS_H
#define UART_REGISTERS_H

#include <stdint.h>

// Module      : UART
// Description : CSR for UART
// Width       : 8

//==================================
// Register    : isr
// Description : Interruption Status Register
// Address     : 0x0
//==================================
#define UART_ISR 0x0

// Field       : isr.value
// Description : 0: interrupt is inactive, 1: interrupt is active
// Range       : [3:0]
#define UART_ISR_VALUE      0
#define UART_ISR_VALUE_MASK 15

//==================================
// Register    : imr
// Description : Interruption Mask Register
// Address     : 0x1
//==================================
#define UART_IMR 0x1

// Field       : imr.enable
// Description : 0: interrupt is disable, 1: interrupt is enable
// Range       : [3:0]
#define UART_IMR_ENABLE      0
#define UART_IMR_ENABLE_MASK 15

//==================================
// Register    : data
// Description : Write : data to tansmit, Read : data to receive
// Address     : 0x2
//==================================
#define UART_DATA 0x2

// Field       : data.value
// Description : Data TX or Data RX
// Range       : [7:0]
#define UART_DATA_VALUE      0
#define UART_DATA_VALUE_MASK 255

//==================================
// Register    : ctrl_tx
// Description : Control Register
// Address     : 0x4
//==================================
#define UART_CTRL_TX 0x4

// Field       : ctrl_tx.tx_enable
// Description : 0 : TX is disable, 1 : TX is enable
// Range       : [0]
#define UART_CTRL_TX_TX_ENABLE      0
#define UART_CTRL_TX_TX_ENABLE_MASK 1

// Field       : ctrl_tx.tx_parity_enable
// Description : 0 : Parity is disable, 1 : Parity is enable
// Range       : [1]
#define UART_CTRL_TX_TX_PARITY_ENABLE      1
#define UART_CTRL_TX_TX_PARITY_ENABLE_MASK 1

// Field       : ctrl_tx.tx_parity_odd
// Description : 0 : Parity is even, 1 : Parity is odd
// Range       : [2]
#define UART_CTRL_TX_TX_PARITY_ODD      2
#define UART_CTRL_TX_TX_PARITY_ODD_MASK 1

// Field       : ctrl_tx.tx_use_loopback
// Description : 0 : UART TX FIFO is connected to CSR, 1 : UART RX FIFO is connected to UART RX FIFO
// Range       : [3]
#define UART_CTRL_TX_TX_USE_LOOPBACK      3
#define UART_CTRL_TX_TX_USE_LOOPBACK_MASK 1

// Field       : ctrl_tx.cts_enable
// Description : 0 : Clear To Send Disable, 1 : Clear To Send Enable
// Range       : [4]
#define UART_CTRL_TX_CTS_ENABLE      4
#define UART_CTRL_TX_CTS_ENABLE_MASK 1

//==================================
// Register    : ctrl_rx
// Description : Control Register
// Address     : 0x5
//==================================
#define UART_CTRL_RX 0x5

// Field       : ctrl_rx.rx_enable
// Description : 0 : RX is disable, 1 : RX is enable
// Range       : [0]
#define UART_CTRL_RX_RX_ENABLE      0
#define UART_CTRL_RX_RX_ENABLE_MASK 1

// Field       : ctrl_rx.rx_parity_enable
// Description : 0 : Parity is disable, 1 : Parity is enable
// Range       : [1]
#define UART_CTRL_RX_RX_PARITY_ENABLE      1
#define UART_CTRL_RX_RX_PARITY_ENABLE_MASK 1

// Field       : ctrl_rx.rx_parity_odd
// Description : 0 : Parity is even, 1 : Parity is odd
// Range       : [2]
#define UART_CTRL_RX_RX_PARITY_ODD      2
#define UART_CTRL_RX_RX_PARITY_ODD_MASK 1

// Field       : ctrl_rx.rx_use_loopback
// Description : 0 : UART RX is connected to UART RX Input, 1 : UART RX is connected to UART TX
// Range       : [3]
#define UART_CTRL_RX_RX_USE_LOOPBACK      3
#define UART_CTRL_RX_RX_USE_LOOPBACK_MASK 1

// Field       : ctrl_rx.rts_enable
// Description : 0 : Request To Send Disable, 1 : Request To Send Enable
// Range       : [4]
#define UART_CTRL_RX_RTS_ENABLE      4
#define UART_CTRL_RX_RTS_ENABLE_MASK 1

//==================================
// Register    : baud_tick_cnt_max_lsb
// Description : Baud Tick Counter Max LSB. Must be equal to (Clock Frequency (Hz) / Baud Rate)-1
// Address     : 0x6
//==================================
#define UART_BAUD_TICK_CNT_MAX_LSB 0x6

// Field       : baud_tick_cnt_max_lsb.value
// Description : Baud Tick Counter Max LSB
// Range       : [7:0]
#define UART_BAUD_TICK_CNT_MAX_LSB_VALUE      0
#define UART_BAUD_TICK_CNT_MAX_LSB_VALUE_MASK 255

//==================================
// Register    : baud_tick_cnt_max_msb
// Description : Baud Tick Counter Max MSB. Must be equal to (Clock Frequency (Hz) / Baud Rate)-1
// Address     : 0x7
//==================================
#define UART_BAUD_TICK_CNT_MAX_MSB 0x7

// Field       : baud_tick_cnt_max_msb.value
// Description : Baud Tick Counter Max MSB
// Range       : [7:0]
#define UART_BAUD_TICK_CNT_MAX_MSB_VALUE      0
#define UART_BAUD_TICK_CNT_MAX_MSB_VALUE_MASK 255

//----------------------------------
// Structure {module}_t
//----------------------------------
typedef struct {
  uint8_t isr; // 0x0
  uint8_t imr; // 0x1
  uint8_t data; // 0x2
  uint8_t __dummy_0x3__
  uint8_t ctrl_tx; // 0x4
  uint8_t ctrl_rx; // 0x5
  uint8_t baud_tick_cnt_max_lsb; // 0x6
  uint8_t baud_tick_cnt_max_msb; // 0x7
} UART_t;

#endif // UART_REGISTERS_H
