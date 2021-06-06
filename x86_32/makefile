CC=g++
ASMBIN=nasm


all : asm cc link
asm :
	$(ASMBIN) -o intel32.o -f elf -g -l intel32.lst intel32.asm
cc :
	$(CC) -m32 -c -g -O0 main.cpp -std=c++17 &> errors.txt
link :
	$(CC) -m32 -g -o intelx86_32 main.o intel32.o
gdb:
	gdb intelx86_32
clean :
	rm *.o
	rm intelx86_32
	rm errors.txt
	rm intel32.lst
debug: all gdb