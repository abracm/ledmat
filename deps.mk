sources.c = \
	src/processor.c \

sources.mjs = \
	src/main.mjs \
	src/processor.mjs \
	src/worklet.mjs \

tests.mjs = \
	tests/js/processor.mjs \

src/processor.o	src/processor.lo	src/processor.to:	src/processor.h

src/processor.ta:	src/processor.to

src/processor.t-run:	src/processor.t


src/processor.o	src/processor.lo	src/processor.to:

src/processor.ta:

tests/js/processor.mjs-t: tests/js/processor.mjs
