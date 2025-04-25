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

// Field       : ctrl.enable_tx
// Description : 0 : TX is disable, 1 : TX is enable
// Range       : [0]
#define UART_CTRL_ENABLE_TX      0
#define UART_CTRL_ENABLE_TX_MASK 1

// Field       : ctrl.enable_rx
// Description : 0 : RX is disable, 1 : RX is enable
// Range       : [1]
#define UART_CTRL_ENABLE_RX      1
#define UART_CTRL_ENABLE_RX_MASK 1

// Field       : ctrl.parity_enable
// Description : 0 : Parity is disable, 1 : Parity is enable
// Range       : [2]
#define UART_CTRL_PARITY_ENABLE      2
#define UART_CTRL_PARITY_ENABLE_MASK 1

// Field       : ctrl.parity_odd
// Description : 0 : Parity is even, 1 : Parity is odd
// Range       : [3]
#define UART_CTRL_PARITY_ODD      3
#define UART_CTRL_PARITY_ODD_MASK 1

// Field       : ctrl.loopback
// Description : 0 : UART RX is connected to input, 1 : UART RX is connected to UART TX
// Range       : [7]
#define UART_CTRL_LOOPBACK      7
#define UART_CTRL_LOOPBACK_MASK 1

//----------------------------------
// Structure {module}_t
//----------------------------------
typedef struct {
  uint8_t data; // 0x0
  uint8_t ctrl; // 0x1
} UART_t;

#endif // UART_REGISTERS_H
