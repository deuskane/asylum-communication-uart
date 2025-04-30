#ifndef UART_REGISTERS_H
#define UART_REGISTERS_H

#include <stdint.h>

// Module      : UART
// Description : CSR for UART
// Width       : 8

//==================================
// Register    : data
// Description : Write : data to tansmit, Read : data to receive
// Address     : 0x0
//==================================
#define UART_DATA 0x0

// Field       : data.value
// Description : Data TX or Data RX
// Range       : [7:0]
#define UART_DATA_VALUE      0
#define UART_DATA_VALUE_MASK 255

//==================================
// Register    : ctrl
// Description : Control Register
// Address     : 0x1
//==================================
#define UART_CTRL 0x1

// Field       : ctrl.tx_enable
// Description : 0 : TX is disable, 1 : TX is enable
// Range       : [0]
#define UART_CTRL_TX_ENABLE      0
#define UART_CTRL_TX_ENABLE_MASK 1

// Field       : ctrl.tx_parity_enable
// Description : 0 : Parity is disable, 1 : Parity is enable
// Range       : [1]
#define UART_CTRL_TX_PARITY_ENABLE      1
#define UART_CTRL_TX_PARITY_ENABLE_MASK 1

// Field       : ctrl.tx_parity_odd
// Description : 0 : Parity is even, 1 : Parity is odd
// Range       : [2]
#define UART_CTRL_TX_PARITY_ODD      2
#define UART_CTRL_TX_PARITY_ODD_MASK 1

// Field       : ctrl.rx_enable
// Description : 0 : RX is disable, 1 : RX is enable
// Range       : [4]
#define UART_CTRL_RX_ENABLE      4
#define UART_CTRL_RX_ENABLE_MASK 1

// Field       : ctrl.rx_parity_enable
// Description : 0 : Parity is disable, 1 : Parity is enable
// Range       : [5]
#define UART_CTRL_RX_PARITY_ENABLE      5
#define UART_CTRL_RX_PARITY_ENABLE_MASK 1

// Field       : ctrl.rx_parity_odd
// Description : 0 : Parity is even, 1 : Parity is odd
// Range       : [6]
#define UART_CTRL_RX_PARITY_ODD      6
#define UART_CTRL_RX_PARITY_ODD_MASK 1

// Field       : ctrl.rx_use_loopback
// Description : 0 : UART RX is connected to UART RX Input, 1 : UART RX is connected to UART TX
// Range       : [7]
#define UART_CTRL_RX_USE_LOOPBACK      7
#define UART_CTRL_RX_USE_LOOPBACK_MASK 1

//----------------------------------
// Structure {module}_t
//----------------------------------
typedef struct {
  uint8_t data; // 0x0
  uint8_t ctrl; // 0x1
} UART_t;

#endif // UART_REGISTERS_H
