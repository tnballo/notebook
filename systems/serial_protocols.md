# Serial Protocols

**References:**

1. [Sparkfun - Serial Communication](https://learn.sparkfun.com/tutorials/serial-communication)

### General Communication Concepts
---

* **Baud rate** - maximum number of times per second that a line can change state, i.e. how often do you take measurements to interpret a 1 or a 0.

* **Serial vs Parallel communication** - serial is “pin efficient” you only need two wires (transmitter and receiver) for full duplex communication, sending/receiving one bit at a time. Note that clocks must be synced. Parallel is faster, multiple data lines allow multiple bits to be sent simultaneously.

* **Synchronous communication** (ex. SPI) - data transmission between two parties is synchronized using a common clock signal, data is transmitted in a steady stream. No extra bits are required to mark the start/end of each data block transmitted, so it’s faster.

* **Asynchronous communication** (ex. UART) - data transmitted at irregular intervals, device’s internal clocks are not synced but speed (in baud) must be agreed upon beforehand. Extra bits are required to mark the start/end of each data block transmitted, so it’s slower.

* **Communication modes** - setups allowing two parties to exchange data:

    * **Simple** - can only transmit in one direction

    * **Half-duplex **- can transmit in one direction at a time, but direction can be switched back/forth.

    * **Full-duplex** - data can be simultaneously transmitted in both directions.

### UART
---
* **Universal Asynchronous Receiver/Transmitter (UART)** - interface for converting processor’s parallel data buses for serial communication. Provides:

    * Hardware flow control - detects data overruns on receiver/transmitted FIFOs

    * Reciever/transmitter handshakes

    * Transfer rate of 115 Kbps (standard UART, high speed variant exists)

* **Anatomy of a serial byte**  - can be transmitted using a standard (ex. RS-232) supported by hardware (ex. UART device):

    * 1 start bit
    
    * 5-8 data bits

    * 1 parity bit (optional). 

        * Even parity sets the bit if the number of 1s is odd, else the bit remains zero.

        * Odd parity sets the bit if the number of 1s is even, else the bit remains zero.

        * Received knows if you’re using even or odd and checks accordingly.

        * Recall parity bits can only detect an odd number of errors so multiple errors could look like valid data.

    * 1-2 stop bits

    * Example: 8E2 means 1 start bit (always), 8 data bits, even parity bit, 2 stop bits.

    * Example: 7N1 means 1 start bit (always), 7 data bits, no parity bit, 1 stop bit.

### SPI
---

* **Serial Peripheral Interconnect (SPI)** - a serial protocol with a single master device and one or more slaves being synchronized. Always full duplex, can achieve multiple Mbps speed. Master controls clock.
    * 4 wires: 

        * Serial clock (SCLK)

        * Master output, slave input (MOSI/SIMO)
        
        * Master input, slave output (MISO/SOMI)

        * SS - slave select

    * Pros:

        * Fast, easy point-to-point communication

        * Constant data flow

        * No addressing needed

        * Universally supported

    * Cons:

        * Requires more pins, master needs 1 SS for each slave. Slaves always need the 4.

        * No flow control

        * No slave acknowledgement

        * No arbitration

### I<sup>2</sup>C
---

* **Inter-integrated Circuit (I<sup>2</sup>C)** - a single, 2-line bus connects multiple devices, any device can be the master for the duration of a transmission. Each device has a unique 7-bit address:

    * Addressing:
    
        * 7 bit addresses
        
        * 16 reserved addresses, so 112 total usable

    * 2 wires:

        * Serial Data Line (SDA)

        * Serial Clock line (SCL)

    * 2 master modes (master-transmitter and master-receiver):

        * Master-transmitter initiates connection and sends data to slave.

        * Master-receiver initiates connection and reads data from slave.

        * In both cases master sets clock and terminates the connection.

    * Pros:

        * Any device can be the master for a communication

        * Collision detection and arbitration

        * Low pin count, just a two line bus

* **I<sup>2</sup>C logical flow** - how communication works:

    1. **Start condition (SCL high, SDA low)** - SCL and and SDA are high by default, this is the idle state. To start a communication, master leaves SCL high and pulls SDA low. This alerts slaves that a transmission is about to occur.

    2. **Address frame** - Master sends 7 bit address, but a bit indicating mode, 1 for reading (master-receiver) or 0 for writing (master transmitter). Slave ACKs by pulling SDA low after it receives address frame.

    3. **Data frames** - master continuously generates clock pulses and either sends data (master-transmitter) or reads data from slave (master-receiver). After the initial addressing frame, you can have an arbitrary number of data frames for the communication.

    4. **Stop condition** - once all data frames are done, master changes SCL low to high and leaves it (back to default), then changes SDA low to high as well. In normal communication SDA would not change while SCL is high, so this indicates a stop.

  
