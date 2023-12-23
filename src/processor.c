#include <stdbool.h>
#include <stdio.h>

static const unsigned char SMALL = 9;

typedef char byte;

enum State {
	STATE_RESET      = 'I',  /// timer was reset
	STATW_READY      = 'A',  /// timer is ready to start
	STATE_RUNNING    = ' ',  /// timer is running, no hands are touching it
	STATE_BOTH_HANDS = 'C',  /// both hands are on the timer
	STATE_LEFT_HAND  = 'L',  /// left  hand is on the timer
	STATE_RIGHT_HAND = 'R',  /// right hand is on the timer
	STATE_STOPPED    = 'S',  /// timer is now stopped
};

// FIXME: line break
static const char VALID_STATES[] = {
	STATE_RESET,
	STATW_READY,
	STATE_RUNNING,
	STATE_BOTH_HANDS,
	STATE_LEFT_HAND,
	STATE_RIGHT_HAND,
	STATE_STOPPED,
};

enum Constants {
	DIGITS_COUNT = 6,
};

struct Packet {
	char         state;
	char         digits[DIGITS_COUNT];
	unsigned int checksum;
	char         newline;
	char         carriage_return;
};

static int
decode_packet(const byte bytes[], unsigned int length, struct Packet *packet) {

	packet->state = bytes[0];
	for (int i = 0; i < DIGITS_COUNT; i++) {
		packet->digits[i] = bytes[i + 1];
	}
	if (length == SMALL) {
		packet->digits[DIGITS_COUNT - 1] = '0';
	}
	packet->checksum        = (unsigned int)bytes[length - 3];
	packet->newline         = bytes[length - 2];
	packet->carriage_return = bytes[length - 1];

	return 0;
}

static bool
checks_valid_state(char state) {
	bool has_valid_state = false;

	for (unsigned int i = 0; i < sizeof(VALID_STATES); i++) {
		if (VALID_STATES[i] == state) {
			has_valid_state = true;
		}
	}

	return has_valid_state;
}

static bool
checks_valid_digits(const char digits[DIGITS_COUNT]) {
	for (int i = 0; i < DIGITS_COUNT; i++) {
		if (digits[i] < '0' || digits[i] > '9') {
			return false;
		}
	}
	return true;
}

static const unsigned int CHECKSUM_INITIAL_VALUE =
	64;  // speedstacks signal checksum begins at 64

static bool
compute_checksum(const char digits[DIGITS_COUNT], const unsigned int checksum) {
	unsigned int total_digits = CHECKSUM_INITIAL_VALUE;
	for (int i = 0; i < DIGITS_COUNT; i++) {
		total_digits += (unsigned int)digits[i] -
		                (char)'0';  // need to offset the ascii code
	}
	return total_digits == checksum;
}



int
decode_status(byte bytes[sizeof(struct Packet)], struct Packet *packet) {

	decode_packet(bytes, sizeof(struct Packet), packet);

	if (!checks_valid_state(packet->state)) {
		return 1;
	}

	if (!checks_valid_digits(packet->digits)) {
		return 1;
	}

	if (!compute_checksum(packet->digits, packet->checksum)) {
		return 1;
	}

	return 0;
}

#ifdef TEST
int
main(void) {
	byte bytes[sizeof(struct Packet)] = {
		'S',
		'0',
		'0',
		'0',
		'0',
		'0',
		'0',
		'@',
		'\n',
		'\r',
	};
	struct Packet packet;
	decode_status(bytes, &packet);
	printf("sizeof(struct Packet): %ld\n", sizeof(struct Packet));
	return 0;
}
#endif
