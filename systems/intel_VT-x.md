# Intel VT-x Fundamentals

**References:**

1. ["Intel’s Virtualization Extensions (VT-x): So you want to build a hypervisor?” by Jacob I. Torrey](http://www.cs.dartmouth.edu/~sergey/cs108/2014/TorreyGuestLecture-Hypervors.pdf), see [lecture video](https://www.youtube.com/watch?v=FSw8Ff1SFLM)

2. ["Hardware Virtualization: the Nuts and Bolts" by Johan De Gelas](http://www.anandtech.com/show/2480)

3. [Intel 64 and IA-32 architectures software developer’s manual combined volumes](https://software.intel.com/en-us/articles/intel-sdm#combined)

### General Virtualization Concepts
---

* **Virtual Machine Montior (VMM, aka Hypervisor)** - software, firmware, or hardware that creates and operates virtual machines, managing the execution of their OSs. Can think of it as a kernel that's running applications, except the applications are guest operating systems. It multi-plexes between OSs. Two types:

    * **Type-1 (bare-metal/native)** - VMM runs directly on hardware, so the VMM itself controls hardware and presents subsets to guest VMs. Generally uses a control domain (dom0) for hardware interaction, don't want driver code running inside the VMM (large volume of potentially insecure code).
    
        * Ex. Xen, VMWare ESX, Hyper-V.
            
     * **Type-2 (hosted)** - software VMM that runs atop a host OS, making it another application. The host OS controls hardware and presents subsets to the VMM, which in turn isolates it's guests VMs from the host OS. Hardware drivers are provided by the host OS.
     
        * Ex. VirtualBox, KVM, VMWare Player.

* **Full vs Paravirtualization** - in full virtualization, the VMM emulates all hardware interactions, so the guest thinks it's running atop native hardware. In paravirtualization (PV) the guest knows it's running atop a hypervisor and call's the VMM's API directly for certain kind of requests (disk I/O, network I/O, etc). PV drivers are still used for performance reasons.

* **Intel Vanderpool Technology (VT-x)** - architecture support for full virtualization in Intel processors, the goal is to largely eliminate the need for paravirtualization.

* **Memory abstraction** - VMM translates guest physically addresses to machine physical addresses using EPTs.

    * **Extended Page Table (EPT)** - paging allows an OS/VMM to organize physical memory and provide processes/guests with an abstract and contiguous view of memory.  PTs support multiple permissions per page (X, R, W, or any combo) and uses multiple layers (ex. page directory > page table > page address). EPTs add another level since you also have sepeation between guests (multiple OSs), some page faults can be managed by the OS but others trigger a VM exit and are resolved by the VMM.

    * **CR3 Register** - contains pointer to a set of page tables (EPT PTR), one per guest, stored in VMCS.
    
    * **Translation Lookaside Buffer (TLB)** - caches previous address translations, typically one for code and one for data.
    
    * **VM process ID (VPID)** - add a word to each TLB line with the VM (guest) ID, avoid performance hit from VM exit TLB flush (TLB can now cache entries for multiple guests, possibly simultaneously, in a controlled manner).

### Operating Modes
---
* **System Managment Mode (SMM)** - an x86 operating mode in which normal OS execution halts so that system code (power managment, hardware control, OEM firmware, etc) can run at a higher privilege. Fully hidden in hardware from OS/hypervisor.

* **System Managment Mode Transfer Montior (STM)** - aka Dual Monitor Mode, like a VMM for that manages VMs containing SMM code.

* **Ring Hierarchy** - a model for reasoning about the privilege of code executing at a given level. Each ring is configured to trap on certain classes of events.

    * **Ring 3** - applications. Confined by process isolation boundaries, limited by the OS's abstractions.
    
    * **Rings 2 and 1** - unused privilege levels. Originally thought of by hardware designers but very rarely adopted in practice.
    
    * **Ring 0** - the OS kernel (VMX non-root mode). A baremetal kernel would have full access to the hardware, but a virtualized kernel is limited by the VMM's abstractions.
    
    * **Ring -1** - the VMM/hypervisor (VMX root mode). Almost unrestricted access to the hardware.
    
    * **Ring -2** - SMM. Unrestricted access to the hardware, but monitored by the STM.
    
    * **Ring -3** - STM. Create/mange SMM VMs. Unrestricted access to the hardware.

### VMX
---

* **Virtual Machine Extensions (VMX)** - an extra instruction set to support virtualization at the hardware level, allows for higher performance VMMs with smaller code bases. Adds 10 instructions (descriptions from Intel SDM):

    * VMCS-maintenance instructions:

        * **VMPTRLD** - Takes a single 64-bit source operand in memory. It makes the referenced VMCS active and current.

        * **VMPTRST** - Takes a single 64-bit destination operand that is in memory. Current-VMCS pointer is stored into the destination operand.

        * **VMCLEAR** - Takes a single 64-bit operand in memory. The instruction sets the launch state of the VMCS referenced by the operand to “clear”, renders that VMCS inactive, and ensures that data for the VMCS have been written to the VMCS-data area in the referenced VMCS region.

        * **VMREAD** - Reads a component from the VMCS (the encoding of that field is given in a register operand) and stores it into a destination operand.

        * **VMWRITE** - Writes a component to the VMCS (the encoding of that field is given in a register operand) from a source operand.

    * VMX management instructions:

        * **VMLAUCH** - Launches a virtual machine managed by the VMCS. A VM entry occurs, transferring control to the VM.

        * **VMRESUME** - Resumes a virtual machine managed by the VMCS. A VM entry occurs, transferring control to the VM.

        * **VMXOFF** - Causes the processor to leave VMX operation.
    
        * **VMXON** - Takes a single 64-bit source operand in memory. It causes a logical processor to enter VMX root operation and to use the memory referenced by the operand to support VMX operation.

    * VMX-specific TLB-management instructions:

        * **INVEPT** - Invalidate cached Extended Page Table (EPT) mappings in the processor to synchronize address translation in virtual machines with memory-resident EPT pages.

        * **INVVPID** -  Invalidate cached mappings of address translation based on the Virtual Processor ID (VPID).

    * Guest-available instructions:

        * **VMCALL** - Allows a guest in VMX non-root operation to call the VMM for service. A VM exit occurs, transferring control to the VMM.

        * **VMFUNC** -  This instruction allows software in VMX non-root operation to invoke a VM function, which is processor functionality enabled and configured by software in VMX root operation. No VM exit occurs.

 * **Root and Non-Root Operation** - VMM operates in root mode, guest software (it's managed OSs running in VMs) operate in non-root mode. VMX transitions:
 
     * **VMX Entry** - into non-root mode.
     
     * **VMX Exit** - non-root to root mode. Some events (ex. CPUID, RDTSC) always trigger a VM exit.
     
      * **VMXON** - SMM to root mode.
      
      * **VMXOFF** - root mode to SMM.

### VMCS
---

* **Virtual Machine Control Structure (VMCS)** - somewhat analogous to a Process Control Block (PCB) but for guest machines. Stores guest and host state, exit conditions, and pointers to related structures. One VMCS PTR per processor (for currently active VMCS). Not directly accessible, requires VMREAD/VMWRITE.

    * VMCS can be configured to trap (hand execution to SMM with all guest registers/state and exit condition) on any of the following: interrupts, memory faults, IO access, privileged instructions).
    
* **VMCS Logical Groups:** - six total:

    1. **Guest-state Area** - guest processor state, saved on VM exits and loaded on VM entries.

    2. **Host-state Area** - host processor state, saved on VM entries, loaded on VM exits.
    
    3. **VM-exection Control Fields** - control processor behavior during VMX non-root operation.

    4. **VM-exit Control Fields** - control VM exits.

    5. **VM-entry Control Fields** - control VM entries.

    6. **VM-exit Information Fields** - read-only fields, on VM exit contain information on the cause and nature of the exit.

### Related Intel Technologies
---

* **VT-d** - does MMU-style translations, but for device DMA operations. Can protect against malicious devices trying to attack hypervisor memory or OS memory.

* **EPT/VPID** - makes memory management and cache separation easier.
