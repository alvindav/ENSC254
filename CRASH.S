.global CrashModeA
.global CrashModeB
.global CrashModeC
.global findHex
.global printOPCODE
.global printSPACE
.global printBYTE
.global print2BYTES
.global printVAR
.global printNEW

CrashModeA:
	LDR R8, =0xE000102C //transmitter
	LDR R9, =0xE0001030 //uploading from teraterm/ writing to teraterm

	BL printCRASH
	BL printSPACE
	BL printOPCODE
	BL printSPACE

	CMP R2, #0
	BLEQ printZPC

	CMP R2, #0
	BEQ checkUpload

	AND R12, R10, #0b00110000
	CMP R12, #0b00010000

	BLEQ printBYTE
	BLNE print2BYTES

	BL printSPACE
	BL printZPC

	LDR R2, =0x41220000
	B checkUpload	//?????????????????????

CrashModeB:
	LDR R8, =0xE000102C //transmitter
	LDR R9, =0xE0001030 //uploading from teraterm/ writing to teraterm

	BL printCRASH
	BL printSPACE
	BL printOPCODE
	BL printSPACE

	MOV R11, R0
	AND R12, R10, #0b01000000
	CMP R12, #0b01000000
	BLNE printBYTE

	AND R12, R10, #0b01000000
	CMP R12, #0b01000000
	BLEQ print2BYTES

	BL printSPACE

	MOV R11, R1
	AND R12, R10, #0b00100000
	CMP R12, #0b00100000
	BLNE printBYTE

	AND R12, R10, #0b01000000
	CMP R12, #0b01000000
	BLEQ print2BYTES

	BL printSPACE
	BL printZPC

	LDR R2, =0x41220000
	B checkUpload

CrashModeC:
	LDR R8, =0xE000102C //transmitter
	LDR R9, =0xE0001030 //uploading from teraterm/ writing to teraterm

	BL printCRASH
	BL printSPACE
	BL printOPCODE
	BL printSPACE

	CMP R2, #0
	BLEQ printZPC
	BEQ checkUpload

	BL printVAR

	BL printZPC

	LDR R2, =0x41220000
	B checkUpload

printVAR:
	PUSH {R14}			//match1
	MOV R8, #20			//for operand loading
	B VAR

VAR:
	PUSH {R2}
	LDR R2, =memory
	BL loadOperand		//R0 should contain the two byte operand
	MOV R11, R0			//R11 should hold operand because print 2bytes needs it
	BL print2BYTES
	BL printSPACE
	POP {R2}
	SUBS R2, #1
	BNE VAR				//go back if there are more operands
	POP {R15}			//match1 //go back to CrashModeC

printBYTE:
//one byte operand
	PUSH {R14}
	AND R12, R11, #0b11110000				//print first 4 bits operand
	LSR R12, R12, #4
	BL findHex
	STRB R12, [R9]

	AND R12, R11, #0b00001111				//print last 4 bits operand
	BL findHex
	STRB R12, [R9]
	POP {R15}

print2BYTES:
	PUSH {R14}

	AND R12, R11, #0b1111000000000000				//print first 4 bits operand
	LSR R12, R12, #12
	BL findHex
	STRB R12, [R9]

	AND R12, R11, #0b111100000000				//print second 4 bits operand
	LSR R12, R12, #8
	BL findHex
	STRB R12, [R9]

	BL printSPACE

	AND R12, R11, #0b11110000						//print third 4 bits operand
	LSR R12, R12, #4
	BL findHex
	STRB R12, [R9]

	AND R12, R11, #0b00001111						//print last 4 bits operand
	BL findHex
	STRB R12, [R9]

	POP {R15}
printCRASH:
	PUSH {R14}
	MOV R12, #67
	STRB R12, [R9]

	MOV R12, #82
	STRB R12, [R9]

	MOV R12, #65
	STRB R12, [R9]

	MOV R12, #83
	STRB R12, [R9]

	MOV R12, #72
	STRB R12, [R9]

	POP {R15}
printSPACE:
	PUSH {R14}
	MOV R12, #32//space character
	STRB R12, [R9]
	POP {R15}

printNEW:
	PUSH {R14}
	MOV R12, #10//newline character
	STRB R12, [R9]
	MOV R12, #13//carriage return
	STRB R12, [R9]
	POP {R15}

printOPCODE:
	PUSH {R14}

	AND R12, R10, #0b11110000 				//print first 4 bits opcode
	LSR R12, R12, #4
	BL findHex
	STRB R12, [R9]

	AND R12, R10, #0b00001111				//print last 4 bits opcode
	BL findHex
	STRB R12, [R9]

	POP {R15}

printZPC:
	PUSH {R14}

	AND R12, R4, #0b11110000 				//print first 4 bits ZPC
	LSR R12, R12, #4
	BL findHex
	STRB R12, [R9]

	AND R12, R4, #0b00001111				//print last 4 bits ZPC
	BL findHex
	STRB R12, [R9]
	MOV R4, #0
	POP {R15}


findHex:
	PUSH {R14}

	CMP R12, #0
	MOVEQ R12, #48

	CMP R12, #1
	MOVEQ R12, #49

	CMP R12, #2
	MOVEQ R12, #50

	CMP R12, #3
	MOVEQ R12, #51

	CMP R12, #4
	MOVEQ R12, #52

	CMP R12, #5
	MOVEQ R12, #53

	CMP R12, #6
	MOVEQ R12, #54

	CMP R12, #7
	MOVEQ R12, #55

	CMP R12, #8
	MOVEQ R12, #56

	CMP R12, #9
	MOVEQ R12, #57

	CMP R12, #10
	MOVEQ R12, #65

	CMP R12, #11
	MOVEQ R12, #66

	CMP R12, #12
	MOVEQ R12, #67

	CMP R12, #13
	MOVEQ R12, #68

	CMP R12, #14
	MOVEQ R12, #69

	CMP R12, #15
	MOVEQ R12, #70

	POP {R15}
