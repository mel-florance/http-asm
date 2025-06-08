.PHONY: all build compress run

all: build

build:
	mkdir -p build/ && mkdir -p bin/
	nasm -f elf64 -o build/server.o ./server.asm
	ld -o bin/server -s -T link.ld -nostdlib build/server.o

compress: build
	/usr/bin/upx --ultra-brute ./bin/server

run: build
	./bin/server