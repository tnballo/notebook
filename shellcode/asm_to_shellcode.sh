#!/bin/bash

total_bytes=0
null_bytes=0
bold=$(tput bold)
normal=$(tput sgr0)

print_usgage() {

    printf "\nUsage: $0 <archFlag> <targetFile>.asm"
    printf "\n\n<archFlag>:"
    printf "\n\n\t ${bold}-32${normal} for 32-bit shellcode"
    printf "\n\n\t ${bold}-64${normal} for 64-bit shellcode"
    printf "\n\n"

}

# Check params
if [ -z "$1" ] || [ -z "$2" ]; then

        print_usgage
        exit 1

fi

# Parse filename
file_full=$(basename "$2")
file_extension="${file_full##*.}"
file_name="${file_full%.*}"

if [ $file_extension != "asm" ]; then

    print_usgage
    exit 1

fi

# Assemble and link it
if [ "$1"  == "-32" ]; then

    nasm -f elf32 $file_full
    ld -m elf_i386 $file_name.o -o $file_name

elif [ "$1"  == "-64" ]; then

    nasm -f elf64 $file_full
    ld -m elf_x86_64 $file_name.o -o $file_name

else

    print_usgage
    exit 1

fi


# Format Prolouge
printf "\n\n"
echo -n 'char shellcode[] = "'; 

# Extact opcodes from disassembly
for i in $(objdump -d $file_name | grep "^ " | cut -f2); do 

    echo -n '\x'$i; 
    ((total_bytes += 1))

    if [ $i == 0 ]; then

        ((null_bytes += 1))

    fi

done; 

# Format Epilouge
echo -n '";'; 
printf "\n\nTotal bytes = $total_bytes\nNull bytes = $null_bytes\n\n"

# Clean up
rm $file_name.o 
rm $file_name
