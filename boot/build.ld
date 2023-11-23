INPUT(kernel_bootstrap.o libnakOS.a)

SECTIONS
{

    /* Section for the kernel code */
    .header : AT(0x0) {
        LONG( ((SIZEOF(.text)+SIZEOF(.data)) / 512)+1 )
        LONG( BOOTSTRAP_START )
        FILL(0xBEAFDEED)
    }
    . = 0x10000;
    .text  :
    AT(0x200)
    {
        KERNEL_START = .;
        libnakOS.a(.text*)
        libnakOS.a(.rodata*)
        FILL(0xEAEA)
        . = ALIGN(512);
        kernel_bootstrap.o(.text)
    }



    .data : AT (0x200+SIZEOF(.text)) {
        libnakOS.a(.data*)
        libnakOS.a(.eh_frame*)
        FILL(0xDEADBEEF)
        . = ALIGN(512);
        . = . + 511;
        BYTE(0x00)
        KERNEL_END = .;
    }
    .bss : AT (0x200+SIZEOF(.text)+SIZEOF(.data)) {
        BSS_START = .;
        libnakOS.a(.bss*)
        BSS_SIZE_DWORDS = (. - BSS_START) / 4;
    }
    
    /IGNORE/ : {
        *(.comment*)
        *(.note.*)
    }
}