MEMORY
{
    flash (rx)  : ORIGIN = 0x10000000, LENGTH = 8M
    sram  (rwx) : ORIGIN = 0x20000000, LENGTH = 256K
}

SECTIONS
{
    ez.boot :
    {
        _boot_start = .;
        KEEP(*(ez.boot))
        FILL(0)
        . = _boot_start + 252; /* ensure ez.boot fits in the first 252 bytes */
        . += 4;                /* add 4 bytes of padding for the CRC placeholder */
    } > flash
}
