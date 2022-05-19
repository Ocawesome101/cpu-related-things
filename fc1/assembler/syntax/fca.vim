" Vim syntax file
" Language: FC-1 assembly
" Maintainer: Ocawesome101

if exists("b:current_syntax")
  finish
endif

" macros/comments
syn match fcaComment ";.*$"
syn match fcaMacro ";\$"
syn match fcaMacroExpand "\$[^ ]*"
syn keyword fcaMacroBounds macro
syn keyword fcaMacroBounds end
syn match fcaMacroArgument "\$\d+"
syn match fcaMacroArgument "\$\$"
syn match fcaMacroArgument "\$@"
syn match fcaMacroID "\#"

syn match fcaSpecial "\*"
syn match fcaSpecial ","

" directives
syn keyword fcaDirective offset
syn keyword fcaDirective dw
syn match fcaDirective "dw\d*"

" labels
syn match fcaLabel "\.[a-zA-Z_-]*"

" registers
syn match fcaRegister "a[0-5]"
syn match fcaRegister "r[0-9]"

" numbers
syn match fcaNumber "\<\d\+\>"
syn match fcaNumber "\<0x\x\+\>"

" strings
syn region fcaString start=+"+ end=+"+ contains=All
syn region fcaString start=+'+ end=+'+ contains=All

" instructions
syn keyword fcaInstruction nop idload load move imm idstore store push pushi pop compare jump idjump rjump add addi sub subi mult multi div divi lshift lshifti rshift rshifti not and andi or ori xor xori devid pread pisready pwrite seti irq clri halt

hi def link fcaComment Comment
hi def link fcaMacro Special
hi def link fcaMacroExpand Macro
hi def link fcaMacroBounds PreCondit
hi def link fcaMacroArgument Special
hi def link fcaMacroID Number
hi def link fcaDirective Macro
hi def link fcaSpecial Operator
hi def link fcaLabel Function
hi def link fcaRegister Special
hi def link fcaInstruction Keyword
hi def link fcaNumber Number
hi def link fcaString String
