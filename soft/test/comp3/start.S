.section    .boot, "ax", @progbits

.global start
start:
    j _entry

.org 0x8



_entry:
1:
# zero-initialize register file
addi x1, zero, 0
# x2 (sp) is initialized by reset
addi x3, zero, 0
addi x4, zero, 0
addi x5, zero, 0
addi x6, zero, 0
addi x7, zero, 0
addi x8, zero, 0
addi x9, zero, 0
addi x10, zero, 0
addi x11, zero, 0
addi x12, zero, 0
addi x13, zero, 0
addi x14, zero, 0
addi x15, zero, 0
addi x16, zero, 0
addi x17, zero, 0
addi x18, zero, 0
addi x19, zero, 0
addi x20, zero, 0
addi x21, zero, 0
addi x22, zero, 0
addi x23, zero, 0
addi x24, zero, 0
addi x25, zero, 0
addi x26, zero, 0
addi x27, zero, 0
addi x28, zero, 0
addi x29, zero, 0
addi x30, zero, 0
addi x31, zero, 0

# Update LEDs
li a0, 0x10000000
li a1, 54
sw a1, 0(a0)

  la      gp, _gp                 # Initialize global pointer
  la      sp, _fstack

  la t0, _fexception_stack
  csrrw t0, mscratch, t0

# clear the bss segment
  la  t0, _fbss
  la  t1, _end

  sw  zero,0(t0)
  addi  t0, t0, 4
  bltu  t0, t1, 1b

  li a0, 0x10000000
  li a1, 54
  sw a1, 0(a0)

  call    main
