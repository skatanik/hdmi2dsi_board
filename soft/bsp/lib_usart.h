#ifndef LIB_USART
#define LIB_USART

#include <stdint.h>
#include "bsp.h"

void USART_init(uint32_t presc);
int USART_check_tx_busy(void);
int USART_check_rx_busy(void);
int USART_check_tx_ready(void);
int USART_check_rx_ready(void);
void USART_clear_rx_ready(void);
int USART_read_byte_blocking(uint8_t * data);
int USART_send_byte_blocking(uint8_t byte);

#endif
