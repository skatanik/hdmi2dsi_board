# ******* project, board and chip name *******
# -nostdlib
F32C-COMPILER-PATH=/opt/riscv/bin
RISCV32-GCC=$(F32C-COMPILER-PATH)/riscv64-unknown-linux-gnu-gcc
RISCV32-OBJCOPY=$(F32C-COMPILER-PATH)/riscv64-unknown-linux-gnu-objcopy
RISCV32-DUMP=$(F32C-COMPILER-PATH)/riscv64-unknown-linux-gnu-objdump

prgr_rom.mif:
#L/opt/riscv/riscv64-unknown-linux-gnu/lib32/ilp32/ -lgcc_s
firmware.elf: sections.ld start.s ./../main.c
	$(RISCV32-GCC) -march=rv32i -mabi=ilp32 -Wl,-Bstatic,-lc,-T,sections.ld,--strip-debug -ffreestanding -nostdlib -O1 -o firmware.elf start.s ./../main.c #--verbose

firmware.bin: firmware.elf
	$(RISCV32-OBJCOPY) -O binary firmware.elf /dev/stdout > firmware.bin
#	$(RISCV32-DUMP) -dS ./../main.o > obj_dumb.log

firmware.coe: firmware.bin
	python3 makehex.py $^ 256 > $@

prgr_rom.mif: firmware.bin
	python3 makehex.py $^ 256 > firmware.coe
	python3 makemif.py $^ 256 > $@
	cp -r prgr_rom.mif ./../../xilinx_project/vivado_test/vivado_test.ip_user_files/mem_init_files/prgr_rom_s7.mif
	cp -r prgr_rom.mif ./../../xilinx_project/vivado_test/vivado_test.sim/sim_1/behav/modelsim/prgr_rom_s7.mif

clean:
	rm -r *.coe *.bin *.elf
