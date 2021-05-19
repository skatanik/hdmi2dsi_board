#ifndef LIB_SYS_TIMER
#define LIB_SYS_TIMER

#include <stdint.h>
#include "bsp.h"

uint32_t SYS_TIMER_read_state(void);
void SYS_TIMER_set_reload(uint32_t val);
int  SYS_TIMER_read_count_flag(void);
void SYS_TIMER_set_enable(int state);

#endif