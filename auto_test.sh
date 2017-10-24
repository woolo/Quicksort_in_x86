#!/bin/bash

# Compile
nasm -f elf32 quickSort.asm -o quickSort.o

gcc -m32 -fno-pic quickSort.o -o quickSort

# Do the auto test
echo "================================================="
echo "=================== TEST 0 ======================"
echo "================================================="
./quickSort 98 -55 66 0 24 -74 65 98 115 -52 36 45 75 0
echo ""

for i in {1..5}
do
    echo "================================================="
    echo "================== TEST $i ======================="
    echo "================================================="
    ./quickSort $(shuf -i 0-200 -n 20)
    echo ""
done
