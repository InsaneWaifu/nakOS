INPUT(boot.o log.o boot2.o commonboot.o)

SECTIONS {
    .boot  0x7C00: AT(0)
    {
        boot.o(.text)
        log.o(.text)
        commonboot.o(.text)
        . = 0x1FE;
        BYTE(0x55)
        BYTE(0xAA)
    }

    .boot2  0x500: AT(0x200)
    {
        boot2.o(.*)
        FILL(0xC001);
        . = ALIGN(512) + 256;
        /* Why do we add 256? Align operates on the location counter. This sections header sets it to 0x500.
        so while its at 0x200 in the file align treats it as if it was 0x500, and so the alignment will actually
        end up being 0x100 (256) bytes different than the expected*/
    }

    SECTORS_TO_READ = SIZEOF(.boot2) / 512;
    KERNEL_START_SECTOR = (( SIZEOF(.boot) + SIZEOF(.boot2) ) / 512) + 1;
}