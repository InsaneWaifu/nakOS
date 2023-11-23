all: kernel.bin


clean:
	$(RM) *.bin *.o *.dis

log.o: log.asm 
	nasm log.asm -o $@ -f elf64 

boot.o: commonboot.o boot.asm
	nasm boot.asm -o $@ -f elf64 

commonboot.o: commonboot.asm
	nasm commonboot.asm -o $@ -f elf64 

boot2.o: commonboot.o boot2.asm
	nasm boot2.asm -o $@ -f elf64 

kernel_bootstrap.o: kernel_bootstrap.asm 
	nasm kernel_bootstrap.asm -o $@ -f elf64 



kernel.bin: boot.o log.o kernel_bootstrap.o boot2.o libnakOS.a build.ld
	ld --oformat binary -o bootloader.bin -T bootloader.ld --orphan-handling=error -Map output.map
	ld --oformat binary -s -o kern_standalone.bin -T build.ld  --orphan-handling=error -Map os.map 
	cat bootloader.bin kern_standalone.bin > kernel.bin

