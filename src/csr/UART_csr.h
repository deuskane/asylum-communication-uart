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
// Description : Data with data_oe with mask apply
// Range       : [7:0]
#define UART_DATA_VALUE      0
#define UART_DATA_VALUE_MASK 255

//==================================
// Register    : ctrl
// Description : Write : data to tansmit, Read : data to receive
// Address     : 0x1
//==================================
#define UART_CTRL 0x1

// Field       : ctrl.value
// Description : Data with data_oe with mask apply
// Range       : [7:0]
#define UART_CTRL_VALUE      0
#define UART_CTRL_VALUE_MASK 255

//----------------------------------
// Structure {module}_t
//----------------------------------
typedef struct {
  uint8_t data; // 0x0
  uint8_t ctrl; // 0x1
} UART_t;

#endif // UART_REGISTERS_H
