#include <stdio.h>
#include <stdbool.h>

/*
export const isPacketSizeCorrect = bytes => {
	return bytes.length === 9 || bytes.length === 10;
};

export const byteNamesFromPositions = bytes => {
	assert(isPacketSizeCorrect(bytes));

	const state          = bytes[0];
	const digits         = bytes.slice(1, bytes.length - 3);
	const checksum       = bytes[bytes.length - 3];
	const newLine        = bytes[bytes.length - 2];
	const carriageReturn = bytes[bytes.length - 1];
	return {
		state,
		digits: bytes.length === 9 ? digits.concat("0") : digits,
		checksum,
		newLine,
		carriageReturn,
	};
};
*/

typedef char byte;

char VALID_STATES[] = {
	'I',  /// timer was reset
	'C',  /// both hands are on the timer
	'A',  /// timer is ready to start
	' ',  /// timer is running, no hands are touching it
	'L',  /// left  hand is on the timer
	'R',  /// right hand is on the timer
	'S',  /// timer is now stopper
};

struct Packet{
    char state;
    char digits[6]; //replace magic number - comes from packet length
    unsigned int checksum;
    char newLine;
    char carriageReturn;
};

int byteNamesFromPositions(byte bytes[],unsigned int length, struct Packet * packet){
    
    packet->state = bytes[0];
    packet->digits[0] = bytes[1];
    packet->digits[1] = bytes[2];
    packet->digits[2] = bytes[3];
    packet->digits[3] = bytes[4];
    packet->digits[4] = bytes[5];
    packet->digits[5] = length == 9 ? '0' : bytes[6],
    packet->checksum = (unsigned)bytes[length - 3];
    packet->newLine = bytes[length - 2];
    packet->carriageReturn = bytes[length - 1];
    
    return 0;
}

bool checksValidState(char state){
    
    bool hasValidState = false;
    
    for (int i = 0; i < 8; i++){
        if (VALID_STATES[i] == state){
            hasValidState = true;
        } 
    }

    if (hasValidState == false){
        return false;
    } else {
        return true;
    }
}

bool checksValidDigits(char digits[6]){
    for (int i = 0; i < 6; i++){
        if (digits[i] < '0' || 
            digits[i] > '9'){
            return false;
        }
    }
    return true;
}

bool computeChecksum(char digits[6], unsigned checksum){
    int total_digits = 64; //speedstacks signal checksum begins at 64
    for (int i = 0; i < 6; i++){
        total_digits += digits[i] - '0'; // need to offset the ascii code
    }
    if ((unsigned)total_digits == checksum){
        return true;
    } else {
        return false;
    }
}

int main(void){
    
    byte bytes[10] = {
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
    unsigned int length = 10;
    struct Packet packet;
    byteNamesFromPositions(bytes, length, &packet);    
    
    if (!checksValidState(packet.state)){
        return 1;
    }    
    
    if (!checksValidDigits(packet.digits)){
        return 1;
    }
    
    if (!computeChecksum(packet.digits, packet.checksum)){
        return 1;
    }
    
    return 0;
}

/*
export const decodePacket = bytes => {
	if (!isPacketSizeCorrect(bytes)) {
		return null;
	}

	const { state, digits, checksum } = byteNamesFromPositions(bytes);

	if (!VALID_STATES.has(state)) {
		return null;
	}

	if (!digits.every(d => VALID_DIGITS.has(d))) {
		return null;
	}

	if (checksum.charCodeAt(0) !== computeChecksum(digits)) {
		return null;
	}

	const [
		minutes,
		decaseconds,
		seconds,
		deciseconds,
		centiseconds,
		milliseconds,
	] = digits.map(digitToNumber);

	return {
		state,
		minutes,
		decaseconds,
		seconds,
		deciseconds,
		centiseconds,
		milliseconds,
	};
};

*/
