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

JSIMPL       = node



.SUFFIXES:
.SUFFIXES: .c .o

.c.o:
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@



all: $(NAME).hex


$(NAME).hex: $(NAME).elf
	$(OBJCOPY) -j .text -j .data -Oihex $< $@

sources.c = \
	src/processor.c \

tests.mjs = \
	tests/js/processor.mjs \

sources.o = $(sources.c:.c=.o)

$(sources.o): Makefile

$(NAME).elf: $(sources.o)
	$(CC) $(LDFLAGS) -o $@ $(sources.o)
	$(SIZE) $@



.SUFFIXES: .mjs-run
tests.mjs-run = $(tests.mjs:.mjs=.mjs-run)
$(tests.mjs-run):
	$(JSIMPL) $*.mjs

check-node: $(tests.mjs-run)


check-c:


check: check-node check-c



clean:
	rm -rf $(sources.o) $(NAME).elf $(NAME).hex

deploy: $(NAME).hex
	avrdude \
		-p $(DEVICE) \
		-c arduino   \
		-P $(PORT)   \
		-b $(BAUD)   \
		-U flash:w:$(NAME).hex:i
