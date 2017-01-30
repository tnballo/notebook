# Pearls of Wisdom from "the Alien Book"

Sikorski, Michael, and Andrew Honig. *Practical Malware Analysis: The Hands-on Guide to Dissecting Malicious Software.* San Francisco: No Starch Press, 2012.

#### Chp. 4 - A Crash Course in x86 Disassembly

* Instructions you'll often see for optimization reasons (note this is Intel syntax, not AT&T, so ```<instruc> <dest>,<src>```):

    * ```xor eax, eax``` - set a register to zero (pg. 75).

    * ```mov eax, ss:[esp]``` - directly read top of stack without affecting the stack pointer (pg. 79).
     
     * ```test eax, eax``` - test against itself, to check if NULL (pg. 80).

* Malware will must change endianness during network communication x86 programs are little-endian and network data is big-endian. An important indicator, like an IP address, will in little endian format while locally in memory and big-endian format while if transferred over the network (pg. 70).

* A function containing a seemly random combination of ```xor, or, and, shl, ror, rol ``` is likely an encryption or compression function (pg. 76).

* By common convention, local parameters and variables within a stack frame are referenced relative to (i.e. offsets from) ```EBP``` (pg. 77).

* The ```pusha``` and ```pushad``` instructions push the 16-bit and 32-bit registers onto the stack, respectively.  ```popa``` and ```popad``` restore them. These are rarely used by compilers, so seeing them is likely an indicator of human-written assembly or shellcode.







