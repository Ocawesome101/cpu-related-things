jump a5, .main
.ret
pop r9
store r9, ._6V1q8_p2
.l0
pop r9
pop r8
push r9
idjump a5, r8
.wchar
pop r9
pwrite r9 , 0 , 0 , 0
.l1
.main
pushi .l3
pushi 65
pushi 0
jump a5, .ret
.l3
pop r9
store r9, ._6Sg4f_example
pushi .l4
load r9, ._6Sg4f_example
push r9
jump a5, .wchar
.l4
pushi .l5
pushi .l6
pushi 10
pushi 2
jump a5, .ret
.l6
jump a5, .wchar
.l5
.l2
halt
._Ij6ko_ch
*dw4 0
._6V1q8_p1
*dw4 0
._6V1q8_p2
*dw4 0
._6Sg4f_example
*dw4 0

