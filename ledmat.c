// #define F_CPU 16000000UL
#define LED_PIN 0

#include <avr/io.h>
#include <util/delay.h>

int
main(void) {
	DDRB |= (1 << LED_PIN);

	// while (true) {
	while (1) {
		PORTB ^= (1 << LED_PIN);
		_delay_ms(500);
	}
	return 0;
}

/*
int
main(void) {
	DDRB |= (1 << DDB5);

	while (true) {
		PORTB |=  (1 << PORTB5);
		_delay_ms(500);

		PORTB &= ~(1 << LED_PIN);
		_delay_ms(500);
	}
	return 0;
}
*/
