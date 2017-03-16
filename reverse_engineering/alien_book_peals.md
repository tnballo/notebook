# Pearls of Wisdom from "the Alien Book"

**Source:** Sikorski, Michael, and Andrew Honig. *Practical Malware Analysis: The Hands-on Guide to Dissecting Malicious Software.* San Francisco: No Starch Press, 2012.

### Chp. 4 - A Crash Course in x86 Disassembly
---

* Instructions you'll often see for optimization reasons (note this is Intel syntax, not AT&T, so ```<instruc> <dest>,<src>```):

    * ```xor eax, eax``` - set a register to zero (pg. 75).

    * ```mov eax, ss:[esp]``` - directly read top of stack without affecting the stack pointer (pg. 79).
     
    * ```test eax, eax``` - test against itself, to check if NULL (pg. 80).

* Malware will must change endianness during network communication x86 programs are little-endian and network data is big-endian. An important indicator, like an IP address, will in little endian format while locally in memory and big-endian format while if transferred over the network (pg. 70).

* A function containing a seemly random combination of ```xor, or, and, shl, ror, rol ``` is likely an encryption or compression function (pg. 76).

* By common convention, parameters and variables are referenced relative to (i.e. offsets from) ```ebp```, if we're within a stack frame (pg. 77).

    * Aside: The stack grows downward, so negative offsets from ```ebp``` indicate variables local to a function (within frame) while positive offsets from ```ebp``` indicate parameters passed to the function by the caller (above current frame, bottom of previous/callee frame).

* The ```pusha``` and ```pushad``` instructions push the 16-bit and 32-bit registers onto the stack, respectively.  ```popa``` and ```popad``` restore them. These are rarely used by compilers, so seeing them is likely an indicator of human-written assembly or shellcode (pg. 80).

### Chp. 5 - IDA Pro
---

* Useful shortcuts:

    * ```spacebar``` - switch between graph and text views in the disassembly window (pg. 89).
    
    *  ```g ``` - pressed from the disassembly window, specify a virtual address or named location to jump to. For raw file offsets (when opening a file as binary) use ```Jump > Jump to File Offset``` instead (pg.  94).
    
    * ```x``` - pressed after clicking a function name, shows cross-references to it, i.e. it's call sites. Also works for data, ex. references to  a particular string (pg. 96).
    
    * ```p``` - create a function where IDA has failed to disassemble one, use ```Alt-p``` to modify settings (pg. 96).
    
    * ```:``` - add a comment to single line. Use ```;``` to add a comment that will propagate to all cross references to this line (pg. 100).
    
    * ```o``` - change whether the selected operand is a memory reference or just numerical data. Useful if IDA mislabels a large constant as an address (pg. 101).
    
    * ```u``` - undefine functions, code, or data. Useful when IDA can't correctly interpret the bytes, follow up with (pg. 103):
    
        * ```c``` - define raw bytes as code.
        
        * ```d``` - define raw bytes as data.
        
        * ```a``` - define raw bytes as ASCII strings.

    * ```t``` - assign struct to a memory reference for improved readability, must create the struct first (pg. 130, next chapter).
    
    * ```insert``` - add a structure via the structure subview (pg. 156, next chapter).

* Two potential reasons to open a file as a raw binary - as opposed to a detected format like PE (pg. 88):

    * Malware may append additional code/data to PE files, this content may not be loaded into memory by the OS's loader - which IDA emulates when opening a pre-detected filetype. Loading the binary allows you to pull in the header and individual sections (ex. ```.rsrc```).
    
    * If a binary contains shellcode, you an disassemble it.

* In any given function, IDA can only label parameters and local variables used in the in binary - more might have existed in the source code, so you can't assume it's found everything (pg. 98). 

### Chp. 6 - Recognizing C Code Constructs in Assembly
---

* In disassembly, global variables are referenced by memory address (absolute pointer) and local variables are referenced by stack address (relative to ```ebp``` within a frame) (pg. 80).

* An ```if``` statement will always result in a conditional jump in the disassembly, but obviously not all conditional jumps are related to ```if``` statements (pg. 113).

* A ```for``` loop in disassembly can be identified by looking for it's 4 components: counter initialization, comparison, it's execution instructions, and counter increment/decrement (pg. 116). A ```while``` loop is similar, but the disassembly is slightly simpler (pg. 118).

* Calling conventions:

    * ```cdecl``` - params pushed onto stack right to left (last pushed first), caller cleans up stack after the call returns, return values passed in ```eax``` (pg. 119).
    
    * ```stdcall``` - like ```cdecl``` but callee cleans arguments from frame, so you'll see instructions like ```add esp, 12h``` in the callee instead of after the call site in the caller (pg. 120).
    
    * ```fastcall``` - most variable across compilers, but generally: first two params passed in ```edx``` and ```ecx```, additional params pushed right to left, and caller does cleanup. More efficient since register access is faster than stack memory access (pg. 120).
    
* Instead of pushing function call arguments onto the stack (ex. ```push ecx```) the compiler might move them to a stack pointer-relative location (ex. ```mov [esp+4], ecx```). In the latter case you don't need to increment the stack pointer for cleanup after the call (pg. 121).

*  A ```switch``` statement will be implemented in disassembly either like an ```if``` statement series (several conditional jumps, sometimes impossible to tell apart from an ```if``` series) or as a jump table (optimization for large, contiguous switch statements where offsets to multiple memory locations are defined in a table and the switch variable indexes the table) (pg. 121).

    * Ex. Backdoors often use ```switch``` statements to select an action based on a single byte value.

*  In the disassembly, arrays are accessed using the base address as a starting point and indexed using element-sized offsets - so you may be able to infer element type/size by analyzing indexing logic. This is true whether the array is global or local (pg. 127).

    * Ex. Malware might use an array of string pointers to hostnames as a means of selecting connection options.

* Like arrays, stucts are accessed using a base address and offsets to individual members. It might be difficult to determine if nearby data types are part of a struct or just happen to be contiguous in memory (pg. 128).

    * Ex. Malware will maintain structs for it's own internal purposes, as well as for making Windows API calls - many of which require stucts passed by reference.

### Chp. 7 - Analyzing Malicious Windows Programs
---

* Handles are references to items opened/created by the OS (window, process, module, etc). Like pointers, they reference objects or memory locations. Unlike pointers they can't be used in arithmetic operations - although some functions return handles representing values that can be used as pointers. The information stored in a handle is undocumented and they should only be manipulated by the Windows API (pg. 137).

* Malware may use file mapping functions to load files into memory and manipulate them (ex. parse and modify PE header), emulating the functionality of the Windows loader by creating in-memory executables dynamically (pg. 138).

    * ```MapCreateFileMapping``` - load a file from disk to memory.

    * ```MapViewOfFile``` - returns a pointer to the base address of the mapping, can be used to read/write anywhere in the file.

* Malware may try to access a disk directly through it's namespace (ex. ```\\.\PhysicalDisk1```) to bypass the normal API and treat this disk as a file - this could allow it to read/write data in unallocated sectors without creating/accessing files (pg. 138).

* Malware uses the Windows Registry for persistence or configuration data, so if you see functions ```RegOpenKeyEx```, ```RegSetValueEx```, or ```RegGetValueEx``` be sure to identify the registry keys accessed/modified (pg. 141).

* Network communication will be preceeded by a call to ```WSAStartup```, which allocates resources for networking libraries, a prerequisite to using network functions (pg. 144).

    * Client functionality will use the following functions, in order: ```socket```, ```connect```, ```send``` and ```recv``` as necessary.
    
    * Server functionality will use the following functions, in order: ```socket```, ```bind```, ```listen```, ```accept```, ```send``` and ```recv``` as necessary.
    
* To create a remote shell, malware could open a socket, populate the I/O streams (stdin, stdout, stderr) of the ```STARTUPINFO``` struct with the socket's handle, and pass this struct as a parameter to ```CreateProcess``` along with a path to an executable. When the spawned process reads and writes, it will be doing so over a remote connection (pg. 148). 

* DLL files, like EXE files, use the PE format. Despite being used very differently, they have essentially identical makeup. The only "physical" difference is a single flag in the header indicating which of the two the file should treated as, and the fact the DLLs will have more exports than imports. (pg. 146).

* Mutexes (synchronization primitives for concurrent access to shared resources) often use hard coded names in order to appear consistent to threads accessing them, which may not communicate otherwise. This makes them a reliable host-based indicator. Additionally malware may attempt to access an existing mutex by name, before creating it, to test that it's the only instance running on it's host (pg. 152).

* Malware might implement a Component Object Model (COM) server in order to inject code into other processes, especially through Browser Helper Objects (BHOs) for Internet Explorer. Neccessary imports: ```DllCanUnloadNow```, ```DllGetClassObject```, ```DllInstall```, ```DllRegisterServer```, and ```DllUnregistserServer```.

* The Native API, which bypasses the standard Windows API for syscalls, is often used in malware and almost never used in legitimate software.

    * Flow of normal API Call: ```User App``` > ```Kernel32.dll``` > ```Ntdll.dll``` > ```Ntoskrnl.exe``` > ```Kernel Data Structures```
    
    * Flow of native API Call: ```User App``` > ```Ntdll.dll``` > ```Ntoskrnl.exe``` > ```Kernel Data Structures```


