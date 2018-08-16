.global Atype_instruction
.global Btype_instruction
.global Ctype_Two
.global Ctype_Var
.global loadOperand
.global toTera
.global storeFunction
.global decode
//fix comparison values

Atype_instruction:
	AND R12, R10, #0b00001111				//check which instruction to call, store in R12

	CMP R12, #2
	BEQ OP0_2 //PRINT

	CMP R12, #5
	BEQ OP1_5 //INC

	CMP R12, #6
	BEQ OP1_6 //DEC

	CMP R12, #8
	BEQ OP0_8 //RET_POPPED

	CMP R12, #11
	BEQ OP1_B //RET

	CMP R12, #13
	BEQ OP0_D //VERIFY

	CMP R12, #15
	BEQ OP1_F //CALL_IN

	B CrashModeA

Btype_instruction:
	MOV R2, #2
	AND R12, R10, #0b00011111				//check which instruction to call, store in R12

	CMP R12, #1 //JE
	BEQ OP2_01

	CMP R12, #2 //JL
	BEQ OP2_02

	CMP R12, #3
	BEQ OP2_03

	CMP R12, #20 //ADD
	BEQ OP2_14

	CMP R12, #21 //SUB
	BEQ OP2_15

	CMP R12, #22 //MUL
	BEQ OP2_16

	CMP R12, #23 //DIV
	BEQ OP2_17

	CMP R12, #24 //MOD
	BEQ OP2_18

	CMP R12, #25 //CALL_2S//fix
	BEQ OP2_19

	CMP R12, #26 //CALL_2N//fix
	BEQ OP2_1A

	CMP R12, #10 //TEST_ATTR
	BEQ OP2_0A

	CMP R12, #11 //SET_ATTR
	BEQ OP2_0B

	CMP R12, #12 //CLEAR_ATTR
	BEQ OP2_0C

	B CrashModeB

Ctype_Two:
	AND R12, R10, #0b00011111				//check which instruction to call, store in R12
	MOV R2, #2
	LDR R8, =memory
	STRB R2, [R8, #60]						//holds # of operands

	CMP R12, #1 //JE
	BEQ OP2_01

	CMP R12, #2 //JL
	BEQ OP2_02

	CMP R12, #20 //ADD
	BEQ OP2_14

	CMP R12, #21 //SUB
	BEQ OP2_15

	CMP R12, #22 //MUL
	BEQ OP2_16

	CMP R12, #23 //DIV
	BEQ OP2_17

	CMP R12, #24 //MOD
	BEQ OP2_18

	CMP R12, #25 //CALL_2S
	BEQ OP2_19

	CMP R12, #26 //CALL_2N
	BEQ OP2_1A

	CMP R12, #10 //TEST_ATTR
	BEQ OP2_0A

	CMP R12, #11 //SET_ATTR
	BEQ OP2_0B

	CMP R12, #12 //CLEAR_ATTR
	BEQ OP2_0C

	B CrashModeC

Ctype_Var:
	AND R12, R10, #0b00001111				//check which instruction to call, store in R12
	LDR R8, =memory
	STRB R2, [R8, #60]						//holds # of operands
	MOV R8, #20								//FIRST OFFSET

	CMP R12, #5
	BEQ	OPVAR_05 //PRINT_CHAR

	CMP R12, #6
	BEQ OPVAR_06 //PRINT_NUM

	CMP R12, #8
	BEQ OPVAR_08 //PUSH

	CMP R12, #9
	BEQ OPVAR_09 //PULL

	CMP R12, #24
	BEQ OPVAR_18 //NOT

	B CrashModeC

//0
OP0_2: //PRINT
	LDRB R0, [R7, R4] 			//R0 contains the encoded string ((higher byte)
	ADD R4, #1					//increment ZPC
	LSL R0, R0, #8				//shift to higher

	LDRB R1, [R7, R4]			//R1 contains lower byte
	ADD R4, #1					//increment ZPC
	ADD R0, R0, R1				//R0 now contains the 16 bits

	BL Encoded
	PUSH {R2, R12}
	LDR R2, =0xE000102C
	BL bufferCheck
	POP {R2, R12}
	TST R0, #0b1000000000000000 //16th bit
	BEQ OP0_2
	B decode

bufferCheck:
	LDR R12, [R2]
	TST R12, #0b100000000000000
	MOVEQ PC, LR
	B bufferCheck

Encoded:
	PUSH {R14}
	LDR R9, =0xE0001030 //uploading from teraterm/ writing to teraterm

	AND R1, R0, #0b0111110000000000
	LSR R1, R1, #10
	BL decode_text
	STR R1, [R9]

	AND R1, R0, #0b0000001111100000
	LSR R1, R1, #5
	BL decode_text
	STR R1, [R9]

	AND R1, R0, #0b0000000000011111
	BL decode_text
	STR R1, [R9]

	POP {R15}


OP0_8: //RET_POPPED
	BL stackPop	//after calling, R11 should hold popped value
	MOV R0, R11 //R0 needs to hold operand for returns
	B Returns

OP0_D: //VERIFY --> can be optional or
	LDR R8, =memory		//access memory
	LDR R9, [R8, #12]	//load max zpc
	LDR R0, [R8, #68]	//load start of instructions
	BL summer			//R12 will contain the sum

	LDRB R0, [R7, #28]	//16 bit number in the header
	LDRB R1, [R7, #29]
	LSL R0, #8
	ADD R1, R0, R1

	LDR R0, =#0xffff
	AND R0, R0, R12

	CMP R0, R1
	BEQ prepareBranch
	B CrashModeA

summer:
	LDRB R1, [R7, R0]
	ADD R12, R1
	CMP R9, R0
	MOVEQ PC, LR

	ADD R0, #1
	B summer

prepareBranch:
	LDRB R12, [R7, R4]
	ADD R4, #1
	B Branch
//1
OP1_5: //INC
	ADD R0, #1
	MOV R11, R0
	SUB R4, #1					//need to grab register location
	LDRB R12, [R7, R4]
	BL storeFunction
	ADD R4, #1
	B decode

OP1_6: //DEC
	SUB R0, #1
	MOV R11, R0
	SUB R4, #1					//need to grab register location
	LDRB R12, [R7, R4]
	BL storeFunction
	ADD R4, #1
	B decode

OP1_B: //RET
	B Returns					//R0 should hold the operand return value

OP1_F: //CALL_IN
	MOV R2, #0					//R0 should hold the zprocedure to call
	LDR R1, =#0xffff 				//throw away result
	B Call

branchCheck:
	TST R12, #0b01000000
	ADDNE R4, #1				//add if long branch
	B decode

OP2_01: //JE
	LDRB R12, [R7, R4]			//R12 now contains the branch byte
	ADD R4, #1					//increment the ZPC
	TST R12, #0b10000000
	BEQ flipJE
	BNE JE

	flipJE:
		CMP R0, R1
		BNE Branch
		B branchCheck

	JE:
		CMP R0, R1
		BEQ Branch				//if equal branch, if not, continue below
		B branchCheck


OP2_02: //JL
	LDRB R12, [R7, R4]				//R12 now contains the branch byte
	ADD R4, #1						//increment the ZPC
	TST R12, #0b10000000
	BEQ flipJL
	BNE JL

	flipJL:
		CMP R0, R1
		BGE Branch
		B branchCheck

	JL:
		CMP R0, R1
		BLT Branch					//if signed less than, branch, if not, continue below
		B branchCheck

OP2_03: //JG
	LDRB R12, [R7, R4]
	LSL R0, R0, #16					//sign extend
	LSL R1, R1, #16					//sign extend
	TST R12, #0b10000000
	BEQ flipJG
	BNE JG

	flipJG:
		CMP R0, R1
		LSRLE R0, R0, #16			//undo shift
		LSRLE R1, R1, #16			//undo shift
		BLE Branch
		B branchCheck
	JG:
		CMP R0, R1
		LSRGT R0, R0, #16			//undo shift
		LSRGT R1, R1, #16			//undo shift
		BGT Branch
		B branchCheck

OP2_14: //ADD
	PUSH {R0, R1}
	ADD R11, R1, R0
	LDRB R12, [R7, R4]
	ADD R4, #1
	BL storeFunction
	POP {R0, R1}
	B decode

OP2_15: //SUB
	PUSH {R0, R1}
	SUB R11, R0, R1
	LDRB R12, [R7, R4]
	ADD R4, #1
	BL storeFunction
	POP {R0, R1}
	B decode

OP2_16: //MUL
	BL alexa
	BL mul
	MOV R11, R0
	BL despacito
	LDRB R12, [R7, R4]
	ADD R4, #1
	BL storeFunction
	B decode

OP2_17: //DIV
	BL alexa
	BL div
	MOV R11, R0
	BL despacito
	LDRB R12, [R7, R4]
	ADD R4, #1
	BL storeFunction
	B decode

OP2_18: //MOD
	BL alexa
	BL mod
	BL despacito
	MOV R11, R0
	LDRB R12, [R7, R4]
	ADD R4, #1
	BL storeFunction
	B decode

alexa:
	PUSH {R0-R7, R10}
	MOV PC, LR

despacito:
	POP {R0-R7, R10}
	MOV PC, LR

OP2_19: //CALL_2S
	//R0 contains the Zprocedure to call
	LDRB R12, [R7, R4] //r12 contains the destination z register
	MOV R1, R12    		//r1 contains the destination z register of the call
	B Call

OP2_1A: //CALL_2N
	//R0 must be the new Zprocedure (first operand)
	//R1 must be the designated destination
	//R2 must be the # of inputs - 1 ((w/o first operand)
	LDR R1, =#0xffff
	B Call
	//upon return from this call you will throw away result of Zprocedure

OP2_0A: //TEST_ATTR
	B CrashModeB
	//retrieve 6 bytes which correspond to the attribute set of an object

OP2_0B: //SET_ATTR
	B CrashModeB
	//retrieve the 6 bytes

OP2_0C: //CLEAR_ATTR
	B CrashModeB
	//retrieve the 6 bytes


//VAR
OPVAR_05: //PRINT_CHAR
	BL loadOperand					//r0 should contain the ASCII operand
	PUSH {R2, R12}
	LDR R2, =0xE000102C
	BL bufferCheck
	POP {R2, R12}
	LDR R9, =0xE0001030 //uploading from teraterm/ writing to teraterm
	STR R0, [R9]
	B decode


OPVAR_06: //PRINT_NUM
	BL loadOperand //r0 now contains the current operand
					//careful of register changes
	BL alexa
	BL PRINT_NUM
	BL despacito
	BL printSPACE

	B decode

toTera:
	LDR R9, =0xE0001030
	STR R0, [R9]
	MOV PC, LR

OPVAR_08: //PUSH
	BL loadOperand //R0 should hold the operand to PUSH
	MOV R11, R0
	BL stackPush
	B decode

OPVAR_09: //PULL
	ADD R4, R2
	ADD R4, #1			//grab the register indicator after all inputs
	LDRB R12, [R7, R4]	//R12 should hold the indicator
	ADD R4, #1
	PUSH {R12}
	BL stackPop			//R0 should hold value
	POP {R12}
	MOV R11, R0			//store function needs value in R11 to store
	BL storeFunction
	B decode


OPVAR_18: //NOT
	B CrashModeC 	//changed

storeFunction: //r12 should hold the register indicator
	PUSH {R14}
	PUSH {R0}

	CMP R12, #0x00
	BLEQ stackPush

	PUSH {R12}
	RSBS R0, R12, #0x0f
	BLPL storeZregister
	POP {R12}

	PUSH {R12}
	SUBS R0, R12, #0x10
	BLPL storeGlobal
	POP {R12}

	POP {R0}
	POP {R15}

loadOperand:
	PUSH {R2}
	LDR R2, =memory
	LDRB R0, [R2, R8]
	ADD R8, #1
	LDRB R1, [R2, R8]
	ADD R8, #3

	LSL R0, R0, #8
	ADD R0, R0, R1
	POP {R2}
	SUB R2, #1
	MOV PC, LR

decode:
	LDR R8, =memory
	LDRB R2, [R8, #60]	//holds number of operands

	MOV R12, #20
	STRB R12, [R8, #16]	//reset the variable operands offset

	LDR R8, =memory //transmitter
	LDRB R12, [R8, #64]

	LDR R8, =0xE000102C //transmitter
	LDR R9, =0xE0001030 //uploading from teraterm/ writing to teraterm

	TST R12, #0b00100000
	BNE debugMode

	//LDR R2, =0x41220000 //switches
	B decode_instructions_loop

debugMode:
	BL printOPCODE
	BL printSPACE
	B decode_instructions_loop
