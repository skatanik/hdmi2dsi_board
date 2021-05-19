#include "lib_sys_timer.h"

uint32_t SYS_TIMER_read_state(void)
{
    return SYS_TIMER->usart_reg_curr_val;
}

void SYS_TIMER_set_reload(uint32_t val)
{
    SYS_TIMER->usart_reg_rld = val;
}

int  SYS_TIMER_read_count_flag(void)
{
    return (SYS_TIMER->usart_reg_cr & (1<<1));
}

void SYS_TIMER_set_enable(int state)
{
    if(state)
        SYS_TIMER->usart_reg_cr |= 1;
    else
        SYS_TIMER->usart_reg_cr &= ~1;
}

