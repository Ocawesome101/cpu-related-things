" Vim syntax file
" Language:   TCLL
" Maintainer: Ocawesome101

syn keyword tcllTodo contained TODO NOTE FIXME

syn region tcllString start=+"+ end=+"+
syn region tcllChar start=+'+ end=+'+

syn match tcllOperator "[@\$=\+;!<>&~\^:,\*/\-]"
syn match tcllComment "//.*$" contains=tcllTodo

syn match tcllNumber "\<\d\+\>"
syn match tcllNumber "\<0x\x\+\>"

syn keyword tcllType int char array void
syn keyword tcllKeyword asm fn while for if else var

hi def link tcllTodo Todo
hi def link tcllComment Comment
hi def link tcllType Type
hi def link tcllKeyword Keyword
hi def link tcllOperator Operator
hi def link tcllString String
hi def link tcllChar SpecialChar
hi def link tcllNumber Number
