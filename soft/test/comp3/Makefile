# and don't touch the rest unless you know what you're doing.
CROSS_COMPILE ?= /opt/riscv/bin/riscv64-unknown-linux-gnu-

CC =		$(CROSS_COMPILE)gcc
LD =		$(CROSS_COMPILE)ld
OBJDUMP =	$(CROSS_COMPILE)objdump
OBJCOPY =	$(CROSS_COMPILE)objcopy
SIZE =		$(CROSS_COMPILE)size

# keep RV32I: the bootloader also emulates DIV/MULH instuctions

CFLAGS = -g -O0 -march=rv32ima -mabi=ilp32 -I. -fdata-sections -ffunction-sections -I../  -Wall
LDFLAGS = -Wl,--gc-sections
OBJS = ./../main.o start.o
LDS = boot.ld
OUTPUT= firmware

#CFLAGS += -DSIMULATION

all: $(OUTPUT) prgr_rom.mif

$(OUTPUT): $(LDS) $(OBJS)
	echo "Step 2"
	${CC} -g -O0 -Wl,--gc-sections -march=rv32ima -mabi=ilp32 -o $(OUTPUT).elf $(LDFLAGS) -nostartfiles $(OBJS) -lm -T $(LDS)
	${OBJCOPY} -O binary $(OUTPUT).elf $(OUTPUT).bin
#   ${OBJDUMP} -D $(OUTPUT).elf > disasm.S
	$(SIZE) $(OUTPUT).elf
#	../tools/genraminit $(OUTPUT).bin 1300 0 0 > $(OUTPUT).ram
#	../tools/genmeminit $(OUTPUT).bin 1300 0 0 > $(OUTPUT).mem
#	${OBJDUMP} -t $(OUTPUT).elf | sort > syms

# $(OUTPUT).coe: $(OUTPUT).bin
# 	python3 makehex.py $^ 256 > $@

prgr_rom.mif: $(OUTPUT).bin
	python3 makehex.py $^ 512 > $(OUTPUT).coe
	python3 makemif.py $^ 512 > $@
	cp -r prgr_rom.mif ./../../xilinx_project/dsi_host/ipcore_dir/prgr_rom.mif
# cp -r prgr_rom.mif ./../../xilinx_project/vivado_test/vivado_test.ip_user_files/mem_init_files/prgr_rom_s7.mif
# cp -r prgr_rom.mif ./../../xilinx_project/vivado_test/vivado_test.sim/sim_1/behav/modelsim/prgr_rom_s7.mif

clean:
	rm -f $(OUTPUT).elf $(OUTPUT).bin $(OBJS) $(OUTPUT).coe prgr_rom.mif

%.o:	%.S
	echo "Step 1"
	${CC} $(CFLAGS) -c $^ -o $@
