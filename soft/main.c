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
//	volatile int i = 0;
//	for(int k = 0; k < 10; k++)
//		i++;
//  printf("Hello RISC-V World!" "\n");
	// *((volatile uint32_t*)OUTPORT) = (uint32_t) 0xffff;
	// *((volatile uint32_t*)OUTPORT) = (uint32_t) 0xffff;
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
