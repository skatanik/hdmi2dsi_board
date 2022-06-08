#ifndef BSP_HEADER
#define BSP_HEADER

#include <stdint.h>

#define WRITE_REG(x,y)          *((volatile uint32_t*)x) = (uint32_t)y
#define READ_REG(x,y)           y = (uint32_t)*((volatile uint32_t*)x)

typedef struct
{
    volatile uint32_t destination_addr_reg;
    volatile uint32_t pixels_number_reg;
    volatile uint32_t control_reg;
    volatile uint32_t reg_hs_cnt     ;
    volatile uint32_t reg_vs_cnt     ;
    volatile uint32_t reg_frames_cnt ;
    volatile uint32_t reg_pix_cnt    ;
    volatile uint32_t reg_sr    ;
}td_hdmi_recv_struct;

typedef struct
{
    volatile uint32_t source_addr_reg;
    volatile uint32_t words_number_reg;
    volatile uint32_t control_reg;
}td_axi2stream_struct;

typedef struct
{
    volatile uint32_t dsi_reg_cr;
    volatile uint32_t dsi_reg_isr;
    volatile uint32_t dsi_reg_ier;
    volatile uint32_t dsi_reg_tr1;
    volatile uint32_t dsi_reg_tr2;
    volatile uint32_t dsi_reg_cmd;
}td_dsi_struct;

typedef struct
{
    volatile uint32_t usart_reg_cr;
    volatile uint32_t usart_reg_isr;
    volatile uint32_t usart_reg_ier;
    volatile uint32_t usart_reg_rxd;
    volatile uint32_t usart_reg_txd;
    volatile uint32_t usart_reg_prsc;
}td_usart_struct;

typedef struct
{
    volatile uint32_t usart_reg_cr;
    volatile uint32_t usart_reg_rld;
    volatile uint32_t usart_reg_curr_val;
}td_sys_timer_struct;

typedef struct
{
    volatile uint32_t gpio_cr;
}td_gpio_struct;

typedef struct
{
    volatile uint32_t pg_source;
    volatile uint32_t pg_cr;
}td_patget_struct;

#define HDMI_RECV  ((td_hdmi_recv_struct *) 0x01010000)
#define DSI  ((td_dsi_struct *) 0x01010300)
#define PIX_READER  ((td_axi2stream_struct *) 0x01010200)
#define UART  ((td_usart_struct *) 0x01010400)
#define I2C_HDMI  ((td_hdmi_recv_struct *) 0x01010500)
#define SYS_TIMER  ((td_sys_timer_struct *) 0x1010700)
#define GPIO  ((td_gpio_struct *) 0x01010600)
#define PATTERN_GENERATOR  ((td_patget_struct *) 0x01010100)


#define READ_FLAG_STATUS(reg, flag) (reg & (flag))

#endif
