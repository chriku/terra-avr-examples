CHIP:=atmega2560
PORT:=/dev/serial/by-id/usb-Arduino__www.arduino.cc__Arduino_Mega_2560_64938323331351D00140-if00
all: main.o
	avr-gcc -std=c99 -mmcu=$(CHIP) -o main.elf main.o
	avr-objcopy -O ihex main.elf main.hex
	avrdude -p $(CHIP) -P $(PORT) -c wiring  -U flash:w:main.hex -v -v
main.o: main.t
	terra main.t

