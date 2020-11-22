/*
 ============================================================================
 Name        : main.c
 Author      : skt
 Version     :
 Copyright   : Your copyright notice
 Description : Hello RISC-V World in C
 ============================================================================
 */

#include <stdio.h>

#define OUTPORT 0x10000000
#define WRITE_REG(x,y)          *((volatile uint32_t*)x) = (uint32_t)y
#define READ_REG(x,y)           y = (uint32_t)*((volatile uint32_t*)x)
/*
 * Demonstrate how to print a greeting message on standard output
 * and exit.
 *
 * WARNING: This is a build-only project. Do not try to run it on a
 * physical board, since it lacks the device specific startup.
 */
// riscv32-unknown-elf-elf2hex --bit-width 32 --input test_riscv.elf --output test_riscv.hex

// #ifdef __GNUC__
// /* With GCC, small printf (option LD Linker->Libraries->Small printf
//    set to 'Yes') calls __io_putchar() */
// #define PUTCHAR_PROTOTYPE int __io_putchar(int ch)
// #else
// #define PUTCHAR_PROTOTYPE int putc(int ch, FILE *f)
// #endif /* __GNUC__ */

int main(void)
{
    // volatile int a = 0x7658;
	// volatile int i = 0;

    volatile uint32_t y;

    // printf("Hello RISC-V World!" "\n");

    WRITE_REG(OUTPORT, 0x1234);

    WRITE_REG(OUTPORT, 0x5678);

    WRITE_REG(OUTPORT, 0xffff);

    WRITE_REG(0x00005000, 0x64337d);

    READ_REG(0x00005000, y);

    WRITE_REG(OUTPORT, y);

    // *((volatile uint32_t*)OUTPORT) = (uint32_t) 0x1234;
    // // a = 12;
	// *((volatile uint32_t*)OUTPORT) = (uint32_t) 0x5678;
    // // a = 234;
    // *((volatile uint32_t*)OUTPORT) = (uint32_t) a;
	// *((volatile uint32_t*)OUTPORT) = (uint32_t) 0xffff;
  return 0;
}

// PUTCHAR_PROTOTYPE
// {
//   /* Place your implementation of fputc here */
//   /* e.g. write a character to the LPUART1 and Loop until the end of transmission */
//  *((volatile uint32_t*)OUTPORT) = ch;

//   return ch;
// }
