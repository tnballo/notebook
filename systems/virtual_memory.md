# Virtual Memory Concepts

**Source:** Bryant, Randal E, and David R. O'Hallaron. *Computer Systems: A Programmer's Perspective*. Pearson, 2015. Print.

###  Virtual Memory in General
---

* **Virtual Memory (VM)** - At a high level, virtualizing a resource means presenting some manner of abstraction to the resource's user, interposing it on accesses to that resource. Virtual memory is an abstraction for main memory managed by the operating system, allowing memory to be used more efficiently and with fewer errors. Three important capabilities:

    * **Efficiency through caching** - Allows main memory (system DRAM) to act as a cache for files on disk, making active items more quickly accessible and managing the back-and-forth transfer between DRAM and disk (paging).
    
    * **Simplified memory management** - each process is given an uniform linear virtual address space to run in, regardless of where it's actually mapped in physical memory and whether or not some of those mappings are shared with another process.
    
    * **Address space isolation** - the OS can enforce isolation between the address spaces of each process, preventing one process from corrupting another. Likewise userspace applications can't access kernel space.
    
* **Memory Management Unit (MMU)** - hardware that performs address translation, virtual to physical. Virtual address space is usually larger than physical, since physical is capped by DRAM.

* **Translation Lookaside Buffer (TLB)** - speeds up MMU’s translation process by caching page table entries in an on-chip hardware cache. Think of it as the MMU’s tiny, dedicated, set-associative L1 cache that stores exclusively address translations (maps virtual to physical). Contains complete PTEs for a small number of entries. VPN bits are split into TLG tag (TLBT) and TLB index (TLBI).

* **Memory mapping** - the process of initializing a VM area by associating it with a disk object. Area can be backed by (i.e. get its values from):

    * Regular file on disk (ex. An executable)
    
    * Anonymous file (nothing, all zeros)
    
        * First fault allocates a physical page of all zeros (demand-zero page)
        
        * Once written to (dirtied) the page becomes the same as any other

* **A note of efficiency** - DRAM is used as a cache for virtual address space. DRAM is 10x slower than SRAM, but a disk is 10,000x slower than DRAM. With a miss penalty that large, everything about the design of virtual memory is aimed at reducing misses:

    * Large blocks: 4KB-4MB
    
    * Fully associative: any virtual page (VP) can be placed in any physical page (PP)
    
    * Highly sophisticated replacement algorithms (software implementations), you don’t search line by line like in an SRAM cache.
   
    * Never use write-through (too slow), always write-back

###  Paging
---

* **Page** - a unit of virtual and physical memory, like a cache’s block but larger.

* **Page table** - a data structure in memory, maintained by the kernel as part of each process context. In a single-level page table, an array of page table entries (PTEs) that map virtual pages to physical pages. Each entry contains a valid bit (tells us if page is in DRAM cache or not), permissions bits (SUP/READ/WRITE/EXEC), and the physical address for that page. 

    * **Page hit**- reference to a word in VM that is already mapped in physical memory (DRAM cache hit)

    * **Page miss (page fault)** - if referenced word is not in the DRAM cache, it will be loaded from disk, possibly evicting another page. If the evicted page has changed since it was loaded, the contents are written to disk. The page table is updated to reflect the presence of the loaded page.

    * **Demand paging** -  note that we wait until a miss to copy a page to DRAM, there’s no prefetching. This might seem inefficient, but it actually works fine because of temporal and spacial locality (at least as long as the sum of all working sets is smaller than the size of main memory). Think of a cold cache.
    
    * **Page permission bits** - Virtual memory adds permission bits to PTEs, checked by MMU, granular per page per process/table:
    
        * **SUP** - supervisory, can only be accessed by the kernel
        
        * **READ** - readable page
        
        * **WRITE**- writable page
        
        * **EXEC** - added in x86_64, instructions can’t be loaded from this page if exec bit is not set. A defense against buffer overflow, part of the reason return oriented programming developed as a technique.
        
    * Modern operating systems use multi-level page tables with a hierarchical structure. This lets us represent larger memory regions with smaller structures that can be traversed rapidly. Otherwise a 64-bit system would need a single giant (512 GB) page table present in memory at all times. Intel uses a 4 level page table system:
    
        * Page-Map Level-4 (PML4)
        
        * Page Directory Pointer (PDP)
        
        * Page Directory (PD)
        
        * Page Table (PT)
        
* **Shared Objects** - a VM region in process 1 is mapped to the same physical pages as a completely different VM region in process 2.

    * **Public shared objects** can be read/modified by both processes.

    * **Private copy-on-write objects** start out as a shared object both processes can read from. However, as soon as one process attempts to write to the private area, the chunk written is moved out a new portion of the physical address space. If process 2 writes to it, then it’s copy is now half the original, unmodified object and half the modified portion allocated at a new location. Process 1 doesn’t know about the new half and only references the untouched original.
        
###  How Virtual Memory Works in Practice
---

* Each process has it’s own virtual address space, thus it has it’s own page table. Contiguous pages in the virtual address space could, in actuality, be anywhere in the physical address space. Note that if an item is shared shared between processes, like read only shared library code, the each process's disparate page table entry maps to the same physical page. There’s no unnecessary duplication.

 * The cache offset (CO) and cache index (CI) bits in the physical address are exactly identical to the VPO bits in the virtual address. This is no coincidence, it’s done to speed up L1 access. Since the PPO is identical to the VPO, even before the MMU does address translation the VPO/PPO bits can be sent to the cache so it can start working on it’s look up. This creates a little bit of parallelism in L1 cache access.
 
* Kernel address spaces always start with an MSB of 1, user space address spaces always start with an MSB of 0. This is because the kernel lives in the very top of the 64-bit address space.

* **```fork```(syscall for creating a new process)** - copy-on-write greatly reduces physical memory overhead for forked processes, since most of the data is the same. As long as the forked process just reads, it can share the parent’s physical pages. Forked processes writes are treated as private copy-on-write.

* **```execve``` (syscall for executable loading)** - ```execve``` does not create a new process, it loads and runs a new program in a new virtual address space, in the current process. It frees all the structs and page tables used by the current process, then creates new ones. The new segments are backed by the executable file (except the uninitialized data, which is private demand-zero). Note that loading is just a re-write of kernel data structures, nothing is actually copied until it is called for the first time.

    * Linking is greatly simplified, since binary segments and heap can start at the same virtual addresses for every process. Execve allocates virtual pages for .text and .data sections, but marks the PTE invalid, tricking kernel into page faulting and loading the data from memory at runtime - hence only loading when/if needed.

    * A VM “area” is a segment, a contiguous chunk of VM who’s pages are related in some way. Ex. code segment, data segment, etc. All of the segments are outlined in the ELF binary, ```execve``` creates the segments in VM when it loads the binary.

* **Address translation with a single-level page table:**

    * Virtual address is split into Virtual Page Number (VPN, think tag bits from caching) and Virtual Page Offset (VPO, think block offset bits from caching). The corresponding physical address is split into a Physical Page Number (PPN) and a Physical Page Offset (PPO). The VPO and PPO are identical.

    * CPU sends virtual address to the MMU, which then fetches the PTE from the page table stored in cache/memory. If hit, MMU constructs physical address, and CPU is given data stored at this address. If miss (0 valid bit or completely unallocated), then a page fault occurs: exception transfers control to the page fault handler, which selects a victim page in the DRAM cache to write to disk (if modified since load), fetches a new page from disk into memory, then handler returns and the instruction is re-executed and we do the same sequence of events as a hit.

        * Important point: page hits are hardware only, page misses require hardware and software, due to the more complex algorithms for victim replacement.

        * SRAM caches use physical addresses, so you can think of the SRAM cache as sitting between the MMU and DRAM, being hit first.
        
* **Kernel page fault exception handling** - the below steps are performed in sequence within the page fault exception handler, which gains control because of a hardware-triggered interrupt:

    1. Is the virtual address existent for this process? If no, segfault.

    2. Is the access legal (ex. Not an attempt to write to a read-only page)? If no, protection exception.

    3. If yes to previous two questions, handle the page fault by selecting a victim, swapping it out, updating page table, and returning handler.


    

    


