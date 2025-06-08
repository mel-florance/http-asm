build_and_run:
	mkdir -p build/ && mkdir -p bin/
	nasm -f elf64 -o build/server.o ./server.asm
	ld -o bin/server -s -T link.ld -nostdlib build/server.o
	/usr/bin/upx --ultra-brute ./bin/server
	./bin/server
