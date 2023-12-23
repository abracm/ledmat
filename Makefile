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
.SUFFIXES: .c .xo .o .to .ta .t .elf .hex

.c.xo:
	$(XCC) $(XCFLAG.a)       -o $@ -c $<

.c.o:
	$(CC) $(CFLAGS.a)        -o $@ -c $<

.c.to:
	$(CC) $(CFLAGS.a) -DTEST -o $@ -c $<

.ta.t:
	$(CC) $(LDFLAGS.a) -o $@ $< $(LDLIBS.a)

.elf.hex:
	$(XOBJCOPY) -j .text -j .data -O ihex $< $@



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



## Default target.  Builds all artifacts required for testing
## and installation.
all: $(derived-assets)


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


.SUFFIXES: .c-lint
sources.c-lint = $(sources.c:.c=.c-lint)
$(sources.c-lint):
	sh tests/c-lint.sh $*.c

check-c-lint: $(sources.c-lint)


.SUFFIXES: .c-clang-tidy
sources.c-clang-tidy = $(sources.c:.c=.c-clang-tidy)
$(sources.c-clang-tidy):
	sh tests/clang-tidy.sh $*.c -- $(CFLAGS.a) -DTEST

check-clang-tidy: $(sources.c-clang-tidy)


.SUFFIXES: .c-clang-format
sources.c-clang-format = $(sources.c:.c=.c-clang-format)
$(sources.c-clang-format):
	sh tests/clang-format.sh $*.c

check-clang-format: $(sources.c-clang-format)


check-lint: check-c-lint check-clang-tidy check-clang-format


check-integration:


tests/assert-clean.sh: all
assert-tests = \
	tests/assert-deps.sh  \
	tests/assert-clean.sh \

$(assert-tests): ALWAYS
	+sh $@

check-asserts: $(assert-tests)


## Run all tests.  Each test suite is isolated, so that a parallel
## build can run tests at the same time.  The required artifacts
## are created if missing.
check: check-t check-lint check-integration check-asserts



## Remove *all* derived artifacts produced during the build.
## A dedicated test asserts that this is always true.
clean:
	rm -rf \
		$(derived-assets)

## Flash the binary to the $(DEVICE) available at $(PORT).
deploy: $(NAME).hex
	avrdude \
		-p $(DEVICE) \
		-c arduino   \
		-P $(PORT)   \
		-b $(BAUD)   \
		-U flash:w:$(NAME).hex:i


MAKEFILE = Makefile
## Show this help.
help:
	cat $(MAKEFILE) | sh tools/makehelp.sh


ALWAYS:
