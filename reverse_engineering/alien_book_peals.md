# Pearls of Wisdom from "the Alien Book"

**Source:** Sikorski, Michael, and Andrew Honig. *Practical Malware Analysis: The Hands-on Guide to Dissecting Malicious Software.* San Francisco: No Starch Press, 2012.

#### Chp. 4 - A Crash Course in x86 Disassembly

* Instructions you'll often see for optimization reasons (note this is Intel syntax, not AT&T, so ```<instruc> <dest>,<src>```):

    * ```xor eax, eax``` - set a register to zero (pg. 75).

    * ```mov eax, ss:[esp]``` - directly read top of stack without affecting the stack pointer (pg. 79).
     
    * ```test eax, eax``` - test against itself, to check if NULL (pg. 80).

* Malware will must change endianness during network communication x86 programs are little-endian and network data is big-endian. An important indicator, like an IP address, will in little endian format while locally in memory and big-endian format while if transferred over the network (pg. 70).

* A function containing a seemly random combination of ```xor, or, and, shl, ror, rol ``` is likely an encryption or compression function (pg. 76).

* By common convention, parameters and variables are referenced relative to (i.e. offsets from) ```EBP```, if we're within a stack frame (pg. 77).

    * Aside: The stack grows downward, so negative offsets from ```EBP``` indicate variables local to a function (within frame) while positive offsets from ```EBP``` indicate parameters passed to the function by the caller (above current frame, bottom of previous/callee frame).

* The ```pusha``` and ```pushad``` instructions push the 16-bit and 32-bit registers onto the stack, respectively.  ```popa``` and ```popad``` restore them. These are rarely used by compilers, so seeing them is likely an indicator of human-written assembly or shellcode (pg. 80).

#### Chp. 5 - IDA Pro

* Useful shortcuts:

    * ```spacebar``` - switch between graph and text views in the disassembly window (pg. 89).
    
    *  ```G ``` - pressed from the disassembly window, specify a virtual address or named location to jump to. For raw file offsets (when opening a file as binary) use ```Jump > Jump to File Offset``` instead (pg.  94).
    
    * ```X``` - pressed after clicking a function name, shows cross-references to it, i.e. it's call sites. Also works for data, ex. references to  a particular string (pg. 96).
    
    * ```P``` - create a function where IDA has failed to disassemble one, use ```ALT-P``` to modify settings (pg. 96).
    
    * ```:``` - add a comment to single line. Use ```;``` to add a comment that will propagate to all cross references to this line (pg. 100).
    
    * ```O``` - change whether the selected operand is a memory reference or just numerical data. Useful if IDA mislabels a large constant as an address (pg. 101).
    
    * ```U``` - undefine functions, code, or data. Useful when IDA can't correctly interpret the bytes, follow up with (pg. 103):
    
        * ```C``` - define raw bytes as code.
        
        * ```D``` - define raw bytes as data.
        
        * ```A``` - define raw bytes as ASCII strings.

* Two potential reasons to open a file as a raw binary - as opposed to a detected format like PE (pg. 88):

    * Malware may append additional code/data to PE files, this content may not be loaded into memory by the OS's loader - which IDA emulates when opening a pre-detected filetype. Loading the binary allows you to pull in the header and individual sections (ex. ```.rsrc```).
    
    * If a binary contains shellcode, you an disassemble it.

* In any given function, IDA can only label parameters and local variables used in the in binary - more might have existed in the source code, so you can't assume it's found everything (pg. 98). 







