/*
 ============================================================================
 Name        : main.c
 Author      : skt
 Version     :
 Copyright   : Your copyright notice
 Description : Hello RISC-V World in C
 ============================================================================
 */

#include <stdint.h>
#include <stdio.h>

#define OUTPORT 0x10000000
#define WRITE_REG(x,y)          *((volatile uint32_t*)x) = (uint32_t)y
#define READ_REG(x,y)           y = (uint32_t)*((volatile uint32_t*)x)

#ifdef __GNUC__
/* With GCC, small printf (option LD Linker->Libraries->Small printf
   set to 'Yes') calls __io_putchar() */
#define PUTCHAR_PROTOTYPE int __io_putchar(int ch)
#else
#define PUTCHAR_PROTOTYPE int fputc(int ch, FILE *f)
#endif /* __GNUC__ */

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


#define HDMI_RECV  ((td_hdmi_recv_struct *) 0x01001000)
#define DSI  ((td_dsi_struct *) 0x01001300)
#define PIX_READER  ((td_axi2stream_struct *) 0x01001200)
#define UART  ((td_hdmi_recv_struct *) 0x01001400)
#define I2C_HDMI  ((td_hdmi_recv_struct *) 0x01001500)
#define I2C_EEPROM  ((td_hdmi_recv_struct *) 0x1001600)
#define GPIO  ((td_hdmi_recv_struct *) 0x01001700)

/*
 */
// riscv32-unknown-elf-elf2hex --bit-width 32 --input test_riscv.elf --output test_riscv.hex

int main(void)
{
    volatile uint32_t y;
    volatile uint32_t z;

    // WRITE_REG(OUTPORT, 0x1234);

    // WRITE_REG(OUTPORT, 0x5678);

    // WRITE_REG(OUTPORT, 0xffff);

    while (1)
    {

        WRITE_REG(0x01001600, 1);
        for (y = 0; y < 100000; y++) {y++; y--;}
        WRITE_REG(0x01001600, 0);
        for (y = 0; y < 100000; y++) {y++; y--;}
        WRITE_REG(0x01001600, 1);
        for (y = 0; y < 100000; y++) {y++; y--;}
        WRITE_REG(0x01001600, 0);
        for (y = 0; y < 100000; y++) {y++; y--;}
        WRITE_REG(0x01001600, 1);
        for (y = 0; y < 200000; y++) {y++; y--;}
        WRITE_REG(0x01001600, 0);
        for (y = 0; y < 100000; y++) {y++; y--;}

        // printf("Hello");

    }




    // WRITE_REG(0x00005000, 0x64337d);

    // READ_REG(0x00005000, y);

    // WRITE_REG(OUTPORT, y);

    // WRITE_REG(OUTPORT, y);

    // WRITE_REG(OUTPORT, y);

    // HDMI_RECV->destination_addr_reg = 0x0010000;
    // HDMI_RECV->pixels_number_reg = 640*480;

    // PIX_READER->source_addr_reg = 0x0010000;
    // PIX_READER->words_number_reg = 640*480*3 >> 2;

    // z = 0x12345678;

    // WRITE_REG(0x10000010, z);

    // z = HDMI_RECV->pixels_number_reg;

    // WRITE_REG(OUTPORT, z);
    // // WRITE_REG(OUTPORT, z);

    // HDMI_RECV->control_reg = 1;

    // WRITE_REG(0x11000000, 0x1); // run external hdmi

    // run clk
    // DSI->dsi_reg_cr |= 0x00000002;
    // while(!(DSI->dsi_reg_isr & 0x00000002)) {};

    // // run lanes
    // DSI->dsi_reg_cr |= 0x00000004;
    // while(!(DSI->dsi_reg_isr & 0x00000004)) {};


    // // while(!(HDMI_RECV->reg_sr & 0x00000001)) {};

    // // PIX_READER->control_reg = 1;
    // // run assembler
    // DSI->dsi_reg_cr |= 0x00000001;



  return 0;
}

PUTCHAR_PROTOTYPE
{
    WRITE_REG(OUTPORT, ch);
    return ch;
}
