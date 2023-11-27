# ledmat
Arduino-based project to make a tournament display for speedcubing and speedstacking that is compatible with all major timers. Uses MAX7219 driven LED matrices as the display.

First assemble the hardware according to the schematics. A full tutorial will be up shortly. Instructions given below are for the software only.

1. Install the [Arduino IDE](https://www.arduino.cc/en/main/software).
2. Download the libraries [MD_Parola](https://github.com/MajicDesigns/MD_Parola) and [MD_MAX2XX](https://github.com/MajicDesigns/MD_MAX72XX) using 'Clone or download' -> 'Download ZIP'.
3. Extract the ZIPs to get two folders called MD_Parola-master and MD_MAX72XX-master. 
4. Move these folders to the Documents\Arduino\Libraries folder (On Windows only. more info on library installation can be found [here](https://www.arduino.cc/en/guide/libraries))
5. Open MD_MAX72XX-master\src\MD_MAX72XX.h. If it does not display well in notepad, try wordpad.
6. Search for USE_PAROLA_HW and replace the 1 next to it with a 0. Search for your hardware (usually USE_FC16_HW, see the full tutorial for more information) and replace the 0 next to it with a 1. Save the file and close it.
7. Download this repository and extract the ledmat.ino file. Open it, set the board to Arduino Nano in the Tools menu. Also make sure the correct Port is selected.
8. Upload the sketch, plug in the stackmat and enjoy!

## TODOs

- Setup github actions to run `make all check` (Pedro)
- Translate the JS bitstream processor into C for the arduino
- code first prototype of working display

## Improvements on existing displays

- we could show the state before the start of the attempt instead of just zeros - show when hands are on timer, when competitor is ready
- instead of displaying 0:00.00 format from the getgo, we could start display only the three rightmost digits and add the other ones as needed while the timer keeps running
- the Gen 5 timer has an annoying feature that, when in 2-pad mode, it switches off and on three times after the timer is stopped, which is reproduced on the display, we should try to avoid this behaviour

## Speedstacks timer signal protocol

The Speedstacks timers send a digital audio signal thorugh the data port ([example](https://imgur.com/mRPrlxn)). This is a guide how to interpret the signal.

The timer sends the signal with a fixed rate of 1200 bits per second (check if this is correct and consistent across all timer generations). It sends a packet that are 90 or 100 bytes long to convey a single time to be displayed.

### Idle values

The bitstream user a standard idle value (0 or 1) to inform when a byte or a packet ended. The idle value varies across timer generations (see section below on timer generations).

Each byte is proceeded by a non-idle value, to show that the byte has begun, and followed by an idle value, to show that it has ended.

Each packet is separated by an unspecificed number of idle values (check if we can tell an exact amount and if it is consistent across timers). Therefore, to check if a packet has ended, you just need to check if you can read ten or more equal values in a row, as that couldn't happen if a byte was being transmitted.

### Packets

A time to be displayed is sent as a packet that can be 9 or 10 bytes long. The lenght of the packet is determined by the timer generation (see section below on timer generations).

Because of the non-idle value and idle value that go before and after each byte, the bytes take 10 bits to be transmitted, and the packet lenghts are therefore 90 or 190 bits.

These are what each byte consists of:

#### byte 1: state of the timer

The first byte is an ASCII code for one of the following letters, which represent the state the timer is in:

- "L" (Left hand on timer)
- "R" (Right hand on timer)
- "C" (Both hands on timer)
- "A" (Ready to start)
- "I" (Reset)
- "S" (Stopped)
- " " (Running and no hands on sensor)

#### byte 2-6 or 2-7: time itself

These are the bytes that convey the time information. Byte 7 may or may not be a part of this depending on the timer generation (see section below on timer generations).

Here is the breakdown on byte-by-byte:
- 2: minutes
- 3: tens of seconds
- 4: units of seconds
- 5: tenths of a second
- 6: hundreths of a second
- 7 (if in use): thousands of a second (check - if 7th byte no used to convey time information, does timer simply not transmit thousands of a second?)

The byte represents the ASCII code for the digit, which is the digit + 48 

#### 3rd to last byte: checksum

This byte is a checksum of the previous bytes (2-6 or 2-7), to ensure the reading is correct.

It it the sum of the values (not the ASCII codes) of all digits + 64.

#### 2nd to last and last bytes: unnecessary line breaks?

These bytes are the ASCII codes for \n (newline) and \r (carriage return). Is this just useless?

### Processing a byte

After reading the 10 bits necessary for a byte (non-idle value + byte + idle value), you must first discard the 1st and the last bits of the byte.

Then, you must place the bits in reverse order. E.g. (11001001 becomes 10010011)

Finally, the bits must be inverted to arrive at the final byte (10010011 becomes 01101100).

### Example of interpreting a packet from start to finish

WIP

### Speedstacks timer generations

#### Generation 3
![Gen 3](https://www.thecubicle.com/cdn/shop/products/stackmatprob2_0925d91d-ffe0-473b-9856-1e3056b8bc1d_1024x1024@2x.jpg?v=1581453337)
- Packet length: 10 bytes
- Idle value: 1

#### Generation 4
![Gen 4](https://www.thecubicle.com/cdn/shop/products/speedstacksg4timerb11_30526b04-d9a7-4c1e-bb20-e91c23038348_580x.jpg?v=1581453340)
- Packet length: 9 bytes (dobule check)
- Idle value: 0 (double check)

#### Generation 5
![Gen 5](https://www.thecubicle.com/cdn/shop/products/StackMat_20G5_20Timer_1200x1200.jpg?v=1620844103)
- Packet length: need to check
- Idle value: need to check

can we easily support other non-speedstacks timers? testing needed

### Useful sources

- Odder's Stacktimer Signal Processor [link](https://github.com/Kubiverse/StackmatSignalProcessor): reference on how to process the stackmat signal bitstream (for Gen 4 timers)
- JFly's [explanation](https://www.jflei.com/2014/08/21/dialup-stackmat/) on the speedstacks timer signal and reading it in a phone
- freundTech's [explanation](https://old.reddit.com/r/Cubers/comments/64czya/wip_stackmat_timer_support_for_twistytimer_app/dg19s4y/) on what the speedstacks timer signal bitstream is composed of
