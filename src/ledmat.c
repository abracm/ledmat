#include <avr/io.h>
#include <stdbool.h>
#include <util/delay.h>


int
main(void) {
	DDRB |= (1 << DDB5);

	while (true) {
		PORTB ^= (1 << PORTB5);
		_delay_ms(500);
	}

	return 0;
}
