/*
 * elf_portable.h - Minimal ELF-32 type definitions for platforms that do not
 * ship <elf.h> (e.g. macOS / Apple platforms).
 *
 * Only the types and fields actually used by simulation/main.cpp are defined
 * here.  On Linux the standard system <elf.h> is used instead (see the
 * conditional include in main.cpp).
 *
 * Struct layouts match the ELF-32 ABI specification exactly, so the structs
 * can be cast directly onto a raw ELF binary loaded into memory.
 */

#ifndef ELF_PORTABLE_H
#define ELF_PORTABLE_H

#include <stdint.h>

/* ---- Scalar type aliases (ELF-32 ABI §1.1) ---- */
typedef uint32_t Elf32_Addr;
typedef uint16_t Elf32_Half;
typedef uint32_t Elf32_Off;
typedef int32_t  Elf32_Sword;
typedef uint32_t Elf32_Word;

#define EI_NIDENT 16

/* ---- ELF-32 file header ---- */
typedef struct {
    unsigned char e_ident[EI_NIDENT]; /* Magic number and other info     */
    Elf32_Half    e_type;             /* Object file type                */
    Elf32_Half    e_machine;          /* Architecture                    */
    Elf32_Word    e_version;          /* Object file version             */
    Elf32_Addr    e_entry;            /* Entry point virtual address     */
    Elf32_Off     e_phoff;            /* Program header table file offset */
    Elf32_Off     e_shoff;            /* Section header table file offset */
    Elf32_Word    e_flags;            /* Processor-specific flags        */
    Elf32_Half    e_ehsize;           /* ELF header size in bytes        */
    Elf32_Half    e_phentsize;        /* Program header table entry size */
    Elf32_Half    e_phnum;            /* Program header table entry count */
    Elf32_Half    e_shentsize;        /* Section header table entry size */
    Elf32_Half    e_shnum;            /* Section header table entry count */
    Elf32_Half    e_shstrndx;         /* Section name string table index */
} Elf32_Ehdr;

/* ---- ELF-32 program (segment) header ---- */
typedef struct {
    Elf32_Word    p_type;             /* Segment type                    */
    Elf32_Off     p_offset;           /* Segment file offset             */
    Elf32_Addr    p_vaddr;            /* Segment virtual address         */
    Elf32_Addr    p_paddr;            /* Segment physical address        */
    Elf32_Word    p_filesz;           /* Segment size in file            */
    Elf32_Word    p_memsz;            /* Segment size in memory          */
    Elf32_Word    p_flags;            /* Segment flags                   */
    Elf32_Word    p_align;            /* Segment alignment               */
} Elf32_Phdr;

/* ---- ELF-32 section header ---- */
typedef struct {
    Elf32_Word    sh_name;            /* Section name (string tbl index) */
    Elf32_Word    sh_type;            /* Section type                    */
    Elf32_Word    sh_flags;           /* Section flags                   */
    Elf32_Addr    sh_addr;            /* Section virtual addr at execution */
    Elf32_Off     sh_offset;          /* Section file offset             */
    Elf32_Word    sh_size;            /* Section size in bytes           */
    Elf32_Word    sh_link;            /* Link to another section         */
    Elf32_Word    sh_info;            /* Additional section information  */
    Elf32_Word    sh_addralign;       /* Section alignment               */
    Elf32_Word    sh_entsize;         /* Entry size if section holds table */
} Elf32_Shdr;

/* ---- ELF-32 symbol table entry ---- */
typedef struct {
    Elf32_Word    st_name;            /* Symbol name (string tbl index)  */
    Elf32_Addr    st_value;           /* Symbol value                    */
    Elf32_Word    st_size;            /* Symbol size                     */
    unsigned char st_info;            /* Symbol type and binding         */
    unsigned char st_other;           /* Symbol visibility               */
    Elf32_Half    st_shndx;           /* Section index                   */
} Elf32_Sym;

#endif /* ELF_PORTABLE_H */
