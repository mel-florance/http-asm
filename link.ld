ENTRY(_start)

PHDRS {
  text PT_LOAD FILEHDR PHDRS FLAGS(5);   /* R|X */
  data PT_LOAD               FLAGS(6);   /* R|W */
}

SECTIONS {
  . = 0x400000;

  .text   : { *(.text*) }              :text
  .rodata : { *(.rodata*) }            :text

  . = ALIGN(0x1000);                   /* new page */
  .data   : { *(.data*) }              :data
  .bss    : { *(.bss COMMON) }         :data

  /DISCARD/ : { *(.note*) *(.eh_frame*) *(.comment*) }
}
