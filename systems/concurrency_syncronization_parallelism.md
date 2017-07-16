# Concurrency, Synchronization, and Parallelism Concepts

**Source:** Bryant, Randal E, and David R. O'Hallaron. *Computer Systems: A Programmer's Perspective*. Pearson, 2015. Print.

###  Concurrency
---

* **Concurrency vs. Parallelism** - Concurrency is necessary but not sufficient for parallelism. Concurrent processes/threads/instructions have an overlap in their execution time, ex. B runs after A has started and before A has finished. However, it’s not necessarily the case that two concurrent items are executed simultaneously, there may just be rapid switching between them that gives the illusion of simultaneous execution (ex. context switching on a single core processor). So a concurrent job might not be any faster than sequential execution (executing A to completion and then B immediately after). Parallel processes/threads/instructions are also concurrent, but they are actually being executed simultaneously, resulting in a speed gain.

    * **Hyper Threading (aka simultaneous multithreading)** - Technique that allows a single CPU to execute multiple flows of control.

    * **Instruction-level parallelism** - Modern processors can execute 2-4 instructions simultaneously in a single clock cycle. A processor that can sustain a rate of greater than 1 instruction per clock cycle is called is "superscalar".

    * **Single instruction, multiple data (SIMD) Parallelism** - A single instruction can operate on multiple data items. Used in image, sound, and video processing.

    * **Concurrent software** - Three main approaches:
    
        * **1. Process-based** -  Kernel automatically interweaves multiple logical flows, each flow has it’s private address space, fully independant. There's a high overhead for process control and sharing data between processes becomes difficult, but it's simple to implement. No descriptors or global vars are shared between processes, just file tables.
        
        * **2. Event-based** -  Programmer manually interweaves flows within the same process by implementing some logic for doing so. The flows share an address space. High code complexity, can't take advantage of multi-core processors. Traditional debugging will work.
        
        * **3. Thread-based** -  Like process-based, the kernel will automatically interweave multiple logical flows. However, they all share the same address space and operate within the context of a single process. Hybrid of process and event-based solutions. More efficient than processes in terms of speed and memory usage. Easy to share data between threads. Unintended sharing can introduce subtle and difficult to debug errors.
        
* **Thread vs. Process** -  A process has context (program: registers, condition codes, stack pointer, program counter, kernel: VM structures, descriptor table, brk pointer) plus code, data, and it’s own stack. A thread has only the program context (not kernel context) and it’s own stack (no replicated code/data). Everything else is shared between all threads in the process, hence far lower overhead. The kernel schedules them in similar ways, but thread-thread context switches are about 2X faster than process-process context switches (less data to save/restore). 

* **Thread Memory Model** - Even though each thread has it’s own stack, the variables it stores there are not necessarily protected from other threads. Abuse of pointers could give peers access to the data of other peers or even the main thread. Whereas processes have a series of parent-child hierarchies, threads don’t - they form a pool. Hence “pthread” stands for “peer thread”. Any peer can reap another, regardless of whether or not they created it. Note the detached mode eliminates the need for explicit reaping.
            
* Mapping variable instances to memory:

    * **Global variables** - Virtual memory contains exactly one instance of any global variable.

    * **Local variables** - Each thread stack contains one instance of each local variable.

    * **Local static variables** - Private in that it’s only accessible inside this function, but also persistent: virtual memory contains exactly one instance of any local static variable. It’s in the data segment along with other global variables, the difference is scope.            
    
* Classes of problems in concurrent programs:

    * **Race conditions** - Outcome depends on arbitrary scheduling decisions elsewhere in the system, causing unreliable behavior.
    
    * **Starvation** - Whereas in deadlock you’ve acquired part of what you need to start, in starvation your request is simply deferred/ignored indefinitely.
    
    * **Deadlock** - Improper resource allocation prevents forward progress. Ex. you’ve locked resource A and need resource B to proceed, but another process has grabbed B and is waiting on A to proceed. Now nobody can proceed.
    
        * 4 conditions must be met for a deadlock to occur:
        
            * **Mutual exclusion** -  Some finite resource that is not sharable.
            
            * **Hold and wait** -  There’s some mechanism to hold one resource and wait for another (ex. mutexes).
            
            * **No preemption** - The system will not preempt the resources in contention.
            
            * **Circular wait** -  ex. process A is waiting on B, B is waiting on A.
            
        * 3 strategies to avoid deadlock:
        
            * **Prevention** -  Structure your system so that a condition leading to deadlock is impossible (best).
            
            * **Avoidance** - When a request that would cause deadlock arrives, reject it.
            
            * **Detection and recovery** -  After a deadlock is detected, break one of the above conditions.
            
###  Synchronization
---

* **Synchronization** - Process of controlling how the flows of each individual thread are interweaved, protecting the integrity of logic and shared data structures. A variable X is shared if and only if multiple threads reference the same instance of X.

    * Note that synchronization overhead can be quite significant, so if a task is split in a way that it requires a great deal of semaphore activities (expensive, fine-grain blocking) the having multiple threads will actually slow down the execution vs a sequential program (i.e don't put synchronization primitives inside the inner loops).

* **Semaphore** - A non-negative global integer used an synchronization value, manipulated by P and V operations. This allows us to enforce mutual exclusion on critical sections. Note that since P and V are system calls, they will hurt performance significantly - but that’s the tradeoff for integrity.

    * **P(s), aka “locking the mutex”** - if s is non-zero, decrement by 1 and return immediately (test and decrement are atomic, uninterruptable). If s is zero, then block: suspend thread until s becomes non-zero. At the point the thread can be restarted with a V operation. After restart, P can decrement s and return control to the called, as it typically would.

    * **V(s) aka “unlocking/releasing the mutex”** -  increment s by 1, also atomically, then check to see if any thread are blocked in the P operation. If so, restart exactly one of those threads, in some indeterminate order. The restarted thread can then finish it’s P operation by decrementing s.

    * **Semaphore invariant** - For a semaphore s, operated on by P and V operations, s >= 0.

    * **Mutex** - Semaphores initialized to 1 are called a mutex. Usually one per shared variable.

* In addition to mutually exclusive access, semaphores can notify other threads of conditions, keeping track of state for shared resources. This gives way to several synchronization strategies:

    * **Producer-Consumer problem** -  There’s a shared bounded buffer. The producer inserts when empty buffer slot becomes available, notifies consumer. The consumer removes an item from the buffer if one is available, notifies the producer.

    * **Reader-Writer Problem** - Reads only read objects, writers modify the object. We should ensure exclusive access for writers but allow an unlimited number of simultaneous readers.

        * **First readers-writers** - Favors readers, don’t keep them waiting unless a writer has already acquired the lock. Reader arriving later than a writer gets priority, so a stream of readers can starve the writer.

        * **Second readers-writers** - Favors writers, once a writer is ready to write it should write ASAP. Writers arriving later than readers gets priority, so a stream of writers can starve the readers.

    * **Pre-threading** - Master thread creates a pool of workers, and places tasks into a buffer as they come in. The workers remove tasks from the buffer and then work on them. This is much more efficient than creating/destroying a thread for every task as they come in.
    
* **Thread safety** -  A function is thread safe if and only if it will always produce correct results when called repeatedly from multiple threads. Threaded functions should only call thread safe functions. All C standard library functions and most syscalls are thread safe.

    * Classes of functions that are NOT thread safe:

        * Functions that do not protect shared variables. 
        Fix: Use P and V semaphore operations,  despite performance cost.

        * Functions rely on persistent state across multiple invocations (ex. static local vars in C).
        Fix: Rewrite it to pass state as part of argument, so caller is responsible for persistence

        * Functions that return a pointer to a static variable.
        Fix: Either rewrite function so caller passes address of variable to store result, or  lock-and-copy (use P and V to protect function calls, copy the static var into some new location).

        * Functions that call thread-unsafe functions.
        Fix: Call only thread safe alternatives.

    * **Reentrant functions** - A function is reentrant if it contains no accesses to shared global variables, every variable it accesses is declared as a local variable and stored on the stack for that function. Reentrant functions are a subset of thread safe functions.


    


