.POSIX:
NAME         = ledmat
DEVICE       = atmega328p
PORT         = /dev/ttyACM0
BAUD         = 115200

COMMFLAGS    = -mmcu=$(DEVICE)
CPPFLAGS     = -DF_CPU=16000000UL $(COMMFLAGS)
LDFLAGS      = $(COMMFLAGS)
CFLAGS       = -Os
CC           = avr-gcc
OBJCOPY      = avr-objcopy
SIZE         = avr-size


.SUFFIXES:
.SUFFIXES: .c .o

.c.o:
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

all: $(NAME).hex

$(NAME).hex: $(NAME).elf
	$(OBJCOPY) -j .text -j .data -Oihex $< $@

sources.o = \
	$(NAME).o

$(sources.o): Makefile

$(NAME).elf: $(sources.o)
	$(CC) $(LDFLAGS) -o $@ $(sources.o)
	$(SIZE) $@

clean:
	rm -rf $(NAME).o $(NAME).elf $(NAME).hex

deploy: $(NAME).hex
	avrdude \
		-p $(DEVICE) \
		-c arduino   \
		-P $(PORT)   \
		-b $(BAUD)   \
		-U flash:w:$(NAME).hex:i
