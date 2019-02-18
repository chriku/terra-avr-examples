CHIP:=attiny2313
all: main.o
	avr-gcc -std=c99 -mmcu=$(CHIP) -o main.elf main.o
	avr-objcopy -O ihex main.elf main.hex
	avrdude -p $(CHIP) -c dragon_isp -U flash:w:main.hex -v -v
main.o: main.t
	terra main.t

