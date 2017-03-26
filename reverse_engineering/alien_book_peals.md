# Pearls of Wisdom from "the Alien Book"

**Source:** Sikorski, Michael, and Honig, Andrew. *Practical Malware Analysis: The Hands-on Guide to Dissecting Malicious Software.* San Francisco: No Starch Press, 2012.

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
    
    * ```p``` - create a function where IDA has failed to disassemble one, use ```Alt-p``` to modify settings, ex. editing function boundaries (pg. 96).
    
    * ```:``` - add a comment to single line. Use ```;``` to add a comment that will propagate to all cross references to this line (pg. 100).
    
    * ```o``` - change whether the selected operand is a memory reference or just numerical data. Useful if IDA mislabels a large constant as an address (pg. 101).
    
    * ```u``` - undefine functions, code, or data. Useful when IDA can't correctly interpret the bytes, follow up with (pg. 103):
    
        * ```c``` - define raw bytes as code.
        
        * ```d``` - define raw bytes as data.
        
        * ```a``` - define raw bytes as ASCII strings.

    * ```t``` - assign struct to a memory reference for improved readability, must create the struct first (pg. 130, next chapter).
    
    * ```insert``` - add a structure via the structure subview (pg. 156, next chapter).
    
    * ```ctrl+k``` - open stack frame display, which shows local variables (pg.348, chp. 15).

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

* **Handle** - references to item opened/created by the OS (window, process, module, etc). Like pointers, they reference objects or memory locations. Unlike pointers they can't be used in arithmetic operations - although some functions return handles representing values that can be used as pointers. The information stored in a handle is undocumented and they should only be manipulated by the Windows API (pg. 137).

* Malware may use file mapping functions to load files into memory and manipulate them (ex. parse and modify PE header), emulating the functionality of the Windows loader by creating in-memory executables dynamically (pg. 138).

    * ```MapCreateFileMapping``` - load a file from disk to memory.

    * ```MapViewOfFile``` - returns a pointer to the base address of the mapping, can be used to read/write anywhere in the file.

* Malware may try to access a disk directly through it's **namespace** (ex. ```\\.\PhysicalDisk1```) to bypass the normal API and treat this disk as a file - this could allow it to read/write data in unallocated sectors without creating/accessing files (pg. 138).

* Malware uses the Windows Registry for persistence or configuration data, so if you see functions ```RegOpenKeyEx```, ```RegSetValueEx```, or ```RegGetValueEx``` be sure to identify the registry keys accessed/modified (pg. 141).

* Network communication will be preceeded by a call to ```WSAStartup```, which allocates resources for networking libraries, a prerequisite to using network functions (pg. 144).

    * Client functionality will use the following functions, in order: ```socket```, ```connect```, ```send``` and ```recv``` as necessary.
    
    * Server functionality will use the following functions, in order: ```socket```, ```bind```, ```listen```, ```accept```, ```send``` and ```recv``` as necessary.
    
* To create a remote shell, malware could open a socket, populate the I/O streams (stdin, stdout, stderr) of the ```STARTUPINFO``` struct with the socket's handle, and pass this struct as a parameter to ```CreateProcess``` along with a path to an executable. When the spawned process reads and writes, it will be doing so over a remote connection (pg. 148). 

* DLL files, like EXE files, use the PE format. Despite being used very differently, they have essentially identical makeup. The only "physical" difference is a single flag in the header indicating which of the two the file should treated as, and the fact the DLLs will have more exports than imports. (pg. 146).

* **Mutexes** (synchronization primitives for concurrent access to shared resources) often use hard coded names in order to appear consistent to threads accessing them, which may not communicate otherwise. This makes them a reliable host-based indicator. Additionally malware may attempt to access an existing mutex by name, before creating it, to test that it's the only instance running on it's host (pg. 152).

* Malware might implement a Component Object Model (COM) server in order to inject code into other processes, especially through Browser Helper Objects (BHOs) for Internet Explorer. Neccessary imports: ```DllCanUnloadNow```, ```DllGetClassObject```, ```DllInstall```, ```DllRegisterServer```, and ```DllUnregistserServer``` (pg. 157).

* The **Native API**, which bypasses the standard Windows API for syscalls, is often used in malware and almost never used in legitimate software (pg. 160).

    * Flow of normal API Call: ```User App``` > ```Kernel32.dll``` > ```Ntdll.dll``` > ```Ntoskrnl.exe``` > ```Kernel Data Structures```
    
    * Flow of native API Call: ```User App``` > ```Ntdll.dll``` > ```Ntoskrnl.exe``` > ```Kernel Data Structures```

### Chp. 15 - Anti-Dissassembly
---

* Anti-disassembly relies on subverting the disassembler's algorithm. There are two algorithms:

    * **Linear-dissemblers** process bytes sequentially and blindly, using the size of the current disassembled instruction to determine the start of the next. If next is invalid, the increment until the happen to find a series of bytes corresponding to a valid instruction. They have no notion of control flow and can't deal with "rouge" bytes (i.e. never executed as an instruction) so it's easy for the attacker to get them to malign offsets and interpret subsequent code incorrectly (pg. 330).
    
    * **Flow-oriented disassemblers** take into account control flow and build a list of locations to disassemble next (i.e. jump targets). They may still get "confused" (ex. if the rouge bytes following a jump that will always be taken aren't valid instructions), but they are generally more robust/reliable (pg. 332).
    
* Two anti-disassembly techniques (jump instructions with same target, jump instructions with constant condition) introduce rouge bytes that confuse the dissembler but can safely be ignored. "Impossible disassembly" introduces rouge bytes such that a single byte is actually part of two different instructions - current dissembler's can't cope with this scenario and these will have be be patched manually to be equivalent to the original's execution (pg. 337).

* Tactics for obscuring control flow:

    * **Non-standard use of function pointers** - if the code loads a function pointer into the local variable and then uses that variable to make calls, IDA will only tag the load as a cross reference and not the calls - resulting in incorrect control flow graphs (pg 340).
    
    * **Return pointer abuse** - a function might obscure itself by calculating it's true start address and pushing it onto the stack, then using ```retn``` to pop that value and jump to it. IDA can't handle these cases and will need manual re-analysis of the function (pg. 342).
    
    * **Structured Exception Handler (SEH) abuse** - you can add a new head record to the SEH linked list (push handler address, push pointer to last record, i.e. current ```fs:[0]```, then repoint ```fs:[0]``` to ```esp```, i.e. your new record), then trigger an exception to call it, and carefully restore the stack when done. IDA will assume the handler is a function without references and may even fail to disassemble it (pg. 345). 

### Chp. 18 - Packers and Unpacking
---

* The **unpacking stub** is responsible for 3 things: unpacking the original executable into memory, resolving all imports of the original executable, and transfering execution to the **original entry point (OEP)** . The most common way to resolve the original imports is for the stub to only import ```LoadLibrary``` (which it uses to load libaries the original import table requires) and ```GetProcAddress``` (which it uses to get the address of each function the original requires, to reconstruct the table) (pg. 385).

* Indicators of a packed program (pg. 387):

    * Few imports, especially if only ```LoadLibrary``` and ```GetProcAddress```
    
    * Section names associated with a packer (ex. ```UPX0```)
    
    * Abnormal section sizes (ex. ```.text``` section has ```SizeOfRawData``` of zero, but ```VirtualSize``` is non-zero, in PE header)
    
    * IDA can only find recognize a small amount of code, OllyDbg throws warnings about packing

* To obscure the **tail jump** (point where unpacking stub transfers control to the OEP), the stub will attempt to use ```retn``` or ```call``` instructions, or even OS functions ```NtContinue``` or ```ZwContinue``` (pg. 386).

    * A tail jump that uses a literal ```jmp``` instruction will often have a target extremely far away and outside of the function, this will stand out in red in IDA's control flow graph - since IDA can't determine where the jump goes, as it expects a target within the function and the target location didn't contain valid instructions when the unpacking stub started (pg. 392).
    
    * One way to potentially find a tail jump is setting a breakpoint at ```GetProcAddress```, which most unpackers will have to use it when reconstructing the import table. This may get you close to the OEP. Likewise, you can set a breakpoint at a function likely to be called early in original executable - ```GetVersion``` and ```GetCommandLineA``` for command line programs, ```GetModuleHandleA``` for GUI programs. (pg. 395).
    
    * Another way to fine the OEP is to use OllyDbg's Run Trace option to set a breakpoint on the ```.text``` section. The section in the PE header so the loader can allocate memory for it, but it'll be missing from the packed executable. The OEP is always withing the ```.text``` section, it'll likely be the first instruction called within it (pg. 395).
    
    * Aside: the stack watch method (pg. 394) relies on the fact that the unpacking stub will save some state before starting it's operations and restore it before passing control to the unpacked program. To use this method:
    
        * In OllyDbg, find first stack push and note the stack address.
        
        * In the memory dump, press ```Ctrl+G``` ("Go" shortcut), enter this stack address, press ```Ok```.
        
        * Right click the first value at this address, then ```Breakpoint > Hardware, on access > Dword```.
        
        * Continue to this breakpoint, should be very close to the tail jump (be sure to snapshot VM before doing so - if this method fails for your particular virus, the virus will run and the machine will be infected!).

* For manual unpacking, if you can get a debugger to the point where the stub is about to tail jump, you can dump the unpacked executable from memory. At that point you'll need to reconstruct the import table and change the entry point in the PE header to the OEP using OllyDump, ImpRec, etc (pg. 390).

* For simple unpackers, use OllyDbg's ```Plugins > OllyDump > Find OEP by Section Hop```. This is a heuristic approach that won't always be accurate - it assumes the unpacker is in one section and the executable is in another, the attempts to break  when control transfers from one section to another. The step-over method ignores function calls and won't find the OEP if transfer is done via a call that doesn't return. The step-into method has a better chance, but is prone to false positives (pg. 391).

* In a packed DLL, the unpacking stub is placed where ```DllMain``` should be. OllyDbg supports debugging DLLs with ```loadDll.exe```, but it will call ```DllMain``` before breaking - so the stub may already have executed by the time a breakpoint is hit and it'll be hard to determine OEP. The workaround is flipping the appropriate bit (0x2000 place set to 1 for DLLs) of the ```Characteristics``` field in the ```IMAGE_FILE_HEADER``` section of the PE header to mark the file as an executable and not a DLL - then proceed as normal and revert when done (pg. 401).





    
