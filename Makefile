.POSIX:
NAME         = ledmat
DEVICE       = atmega328p
PORT         = /dev/ttyACM0
BAUD         = 115200
CFLAGS.a     = $(CFLAGS)
XCFLAGS.a    = $(CFLAGS) -Os -DF_CPU=16000000UL -mmcu=$(DEVICE)
LDLIBS.a     = $(LDLIBS)
LDLIBS       =
EXEC         = ./
XCC          = avr-gcc
XOBJCOPY     = avr-objcopy
XSIZE        = avr-size
JSIMPL       = node



.SUFFIXES:
.SUFFIXES: .c .xo .o .to .ta .t

.c.xo:
	$(XCC) $(XCFLAG.a)       -o $@ -c $<

.c.o:
	$(CC) $(CFLAGS.a)        -o $@ -c $<

.c.to:
	$(CC) $(CFLAGS.a) -DTEST -o $@ -c $<

.ta.t:
	$(CC) $(LDFLAGS.a) -o $@ $< $(LDLIBS.a)



all:
include deps.mk

sources.xo = $(sources.c:.c=.xo)
sources.o  = $(sources.c:.c=.o)
sources.to = $(sources.c:.c=.to)
sources.ta = $(sources.c:.c=.ta)
sources.t  = $(sources.c:.c=.t)


derived-assets = \
	$(NAME).hex   \
	$(NAME).elf   \
	$(sources.xo) \
	$(sources.o)  \
	$(sources.to) \
	$(sources.ta) \
	$(sources.t)  \



all: $(derived-assets)


$(NAME).hex: $(NAME).elf
	$(XOBJCOPY) -j .text -j .data -O ihex $(NAME).elf $@

$(sources.xo) $(sources.o) $(sources.to): Makefile

$(sources.ta):
	$(AR) $(ARFLAGS) $@ $?

$(NAME).elf: $(sources.xo)
	$(XCC) $(LDFLAGS) -o $@ $(sources.xo)
	$(XSIZE) $@



.SUFFIXES: .mjs-run
tests.mjs-run = $(tests.mjs:.mjs=.mjs-run)
$(tests.mjs-run):
	$(JSIMPL) $*.mjs

check-node: $(tests.mjs-run)


.SUFFIXES: .t-run
sources.t-run = $(sources.t:.t=.t-run)
$(sources.t-run):
	$(EXEC)$*.t

check-c: $(sources.t-run)


check-t: check-node check-c


check-lint:


check-integration:


assert-tests = \

$(assert-tests): ALWAYS
	sh $@

check-asserts: $(assert-tests)


check: check-t check-lint check-integration check-asserts



clean:
	rm -rf \
		$(derived-assets)

deploy: $(NAME).hex
	avrdude \
		-p $(DEVICE) \
		-c arduino   \
		-P $(PORT)   \
		-b $(BAUD)   \
		-U flash:w:$(NAME).hex:i


ALWAYS:
