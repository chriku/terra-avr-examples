CHIP:=attiny2313
all: main.o sleep.o
	avr-gcc -std=c99 -mmcu=$(CHIP) -o main.elf main.o sleep.o
	avr-objcopy -O ihex main.elf main.hex
	avrdude -p $(CHIP) -c dragon_isp -U flash:w:main.hex -v -v
sleep.o: sleep.c
	avr-gcc -c -std=c99 -mmcu=$(CHIP) -o sleep.o sleep.c
main.o: main.t
	terra main.t

