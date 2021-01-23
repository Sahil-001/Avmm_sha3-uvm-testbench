CC              = arm-linux-gnueabihf-gcc
AR              = arm-linux-gnueabihf-ar
CFLAGS		= -Wall -O3 -fPIC
INCLUDES        = -I ../testbench/tiny_sha3

DEBUG = NONE

DFLAGS = -mtriple=arm-linux-gnueabihf -d-version=CYCLONE_V -w -O3 -release -boundscheck=off 

all: avmm_sha3_de10

clean:
	rm -f avmm_sha3_de10.o avmm_sha3_de10 read_dev write_dev sha3_de10.o libsha3_de10.a read_dev.o write_dev.o

read_dev: read_dev.d
	CC=arm-linux-gnueabihf-gcc ldc2 $(DFLAGS) -of$@ -L-lphobos2-ldc -L-ldruntime-ldc $^

write_dev: write_dev.d
	CC=arm-linux-gnueabihf-gcc ldc2 $(DFLAGS) -of$@ -L-lphobos2-ldc -L-ldruntime-ldc $^

avmm_sha3_de10.o: ../testbench/avmm_sha3_de10.d
	ldc2 $(DFLAGS) -c $^

avmm_sha3_de10: avmm_sha3_de10.o libsha3_de10.a
	CC=arm-linux-gnueabihf-gcc ldc2 $(DFLAGS) -of$@ -L-luvm-ldc -L-lesdl-ldc -L-lz3 -L-lphobos2-ldc -L-ldruntime-ldc $^

sha3_de10.o: ../testbench/tiny_sha3/sha3.c
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

libsha3_de10.a: sha3_de10.o
	$(AR) r $@ $^

