0000cb4c <__mulsi3>:    ;a0 = a0*a1
    cb4c:	mv	a2,a0       ;a2 = a0
    cb50:	li	a0,0        ;a0 = 0
    cb54:	and	a3,a1,1     ;a3 = LSB of a1 (Loop Starting Point)
    cb58:	beqz	a3,cb60 
    cb5c:	add	a0,a0,a2    ;a0 += a2 if LSB of a1 is 1
    cb60:	srl	a1,a1,0x1   ;shift a1 right 1 bit
    cb64:	sll	a2,a2,0x1   ;shift a2 left 1 bit
    cb68:	bnez	a1,cb54     ;Loop if a1!=0
    cb6c:	ret