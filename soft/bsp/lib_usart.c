#include "lib_usart.h"

void USART_init(int presc)
{
    // presc = f_clk/(8*baudrate)
    UART->usart_reg_prsc = presc;
    UART->usart_reg_cr |= 0x3;
}

int USART_check_tx_busy(void)
{
    return (UART->usart_reg_isr & (1<<5));
}

int USART_check_rx_busy(void)
{
    return (UART->usart_reg_isr & (1<<4));
}

int USART_check_tx_ready(void)
{
    return (UART->usart_reg_isr & (1));
}

int USART_check_rx_ready(void)
{
    return (UART->usart_reg_isr & (1<<1));
}

void USART_clear_rx_ready(void)
{
    UART->usart_reg_isr |= (1<<1);
}

int USART_read_byte_blocking(uint8_t * data)
{
    uint32_t timeout = 50000;
    while(!USART_check_rx_ready()) {
        timeout--;
        if(timeout == 0)
        {
            return -1;
        }
    }
    (*data) = UART->usart_reg_rxd;
    USART_clear_rx_ready();
    return 0;
}

int USART_send_byte_blocking(uint8_t byte)
{
    UART->usart_reg_txd = byte;
    while(USART_check_tx_busy()) {}
    return 0;
}
