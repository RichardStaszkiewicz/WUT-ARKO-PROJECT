CC=g++
# CFLAGS=-m32 -Wall
ASMBIN=nasm

# all:	main.o func.o
# 		$(CC) $(CFLAGS) main.o func.o -o run

# main.o:	main.cpp
# 		$(CC) $(CFLAGS) -c main.cpp -o main.o

# func.o:	func.asm
# 		nasm -f elf func.asm


all : asm cc link
asm :
	$(ASMBIN) -o func.o -f elf -g -l func.lst func.asm
cc :
	$(CC) -m32 -c -g -O0 main.cpp -std=c++17 &> errors.txt
link :
	$(CC) -m32 -g -o test main.o func.o
gdb:
	gdb test
clean :
	rm *.o
	rm test
	rm errors.txt
	rm func.lst
debug: all gdb