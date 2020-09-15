CROSS=riscv32-unknown-elf-
CFLAGS=

# ---- BASYS 3 Board ----
#TODO: automate synthesis and simulation via Makefile
basys3_sections.lds: sections.lds
	$(CROSS)cpp -P -DBASYS3 -o $@ $^

basys3_fw.elf: basys3_sections.lds start.s firmware.c
	$(CROSS)gcc $(CFLAGS) -DBASYS3 -march=rv32i -Wl,-Bstatic,-T,basys3_sections.lds,--strip-debug -ffreestanding -nostdlib -o basys3_fw.elf start.s firmware.c

basys3_fw.hex: basys3_fw.elf
	$(CROSS)objcopy -O verilog basys3_fw.elf basys3_fw.hex

basys3_fw.bin: basys3_fw.elf
	$(CROSS)objcopy -O binary basys3_fw.elf basys3_fw.bin

basys3_fw.s: basys3_sections.lds start.s firmware.c
	$(CROSS)gcc $(CFLAGS) -DBASYS3 -S -march=rv32i -Wl,-Bstatic,-T,basys3_sections.lds,--strip-debug -ffreestanding -nostdlib start.s firmware.c

# ---- Clean ----

clean:
	rm -f testbench.vvp testbench.vcd
	rm -f basys3_fw.elf basys3_fw.hex basys3_fw.bin basys3_fw.s cmos.log
