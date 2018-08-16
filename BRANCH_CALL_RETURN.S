.global Branch
.global Call
.global Returns


Branch: //do we need to change this to R3??
	//R12 should contain the branch byte
	TST R12, #0b01000000
	BNE Bshort						//if 6th bit is 1, short branch
	B Blong							//if 6th bit is 0, long branch

Bshort:
	AND R12, R12, #0b00111111

	CMP R12, #0						//return value of 0
	POPEQ {R15}

	CMP R12, #1
	ADDEQ R4, #1 						//return value of 1
	POPEQ {R15}

	ADD R4, R4, R12					//branching formula
	SUB R4, R4, #2					//branching formula
	B decode
Blong:
	LDRB R11, [R7, R4] 				//R11 holds the second branch byte
	ADD R4, #1

	AND R12, R12, #0b00111111 		//AND R12
	MOV R12, R12, LSL #8			//MULTIPLY BY 256

	ADD R12, R12, R11 				//add the second branch byte to the first

	ANDS R11, R12, #0b0010000000000000

	ADDEQ R12, #0b00000000000000000000000000000000	//if topmost bit is 0, signextend 0
	ADDNE R12, #0b11111111111111111100000000000000	//if topmost bit is 1, signextend 1
	ADD R4, R4, R12
	SUB R4, #2

	B decode
	//ZPCnew = (ZPCold + Offset)-2


Call:
	//R0 must be the new Zprocedure (first operand)
	//R1 must be the designated destination
	//R2 must be the # of inputs - 1 ((w/o first operand)
	//PUSH {R14}
	PUSH {R0, R1, R8, R9, R11}				//in case R8, R9, R11 contains something important
	MOV R8, #0						//value to zero out Zregisters
	MOV R9, #0						//register offset counter

	PUSH {R2}

	ADD R6, #1						//add one to your function nesting depth
	MOV R12, #0x1					//start of Zregisters
	BL locateZregister				//after calling, R12 now contains the localZregister offset for given Zprocedure

	LDR R2, =Z_registers
	BL zeroZregister
	MOV R12, #0x1
	BL locateZregister				//Zregisters are now 0'd, R12 still contains original localZregister offset

	POP {R2}						//cmp r2, #1 because we loaded the 1st operand already
	CMP R2, #1						//if there is more than one input, store into localZregisters //check this
	MOVPL R8, #24					//R8 contains the second operand memory offset (if any)
	PUSHPL {R2}						//save number of inputs
	BLPL inputOperands				//place them in the appropriate localZregisters
	POPPL {R2}						//restore number of inputs

	MOV R12, #0x1					//find location of zregisters once agian
	BL locateZregister

	LDR R8, =Z_registers			//old ADD R12, #22
	ADD R12, #23					//store into 22nd local zregister (lower order byte)
	STRB R2, [R8, R12]				//store # of Zprocedure inputs into 22nd local Zregister ?????

	ADD R12, #2						//24th local zregister ((lower order byte))
	STRB R4, [R8, R12]				//store ZPC into 24th Zregister

	ADD R12, #4						//28th local zregister ((lower order byte))
	STRB R1, [R8, R12]

	CMP R1, #0xff					//if no destination, storeF
	BLHI storeF						//unsigned higher

	MOV R0, R0, LSL #2				//calculate ZPC new //operand*4
	ADD R0, #1						//calculate ZPC new //+1

	MOV R4, R0						//ZPCnew

	POP {R0, R1, R8, R9, R11}
	//LDR R7, =Z_memory

	B decode	//continue execution at current ZPC

storeF:
	SUB R12, #1
	STRB R1, [R8, R12]
	ADD R12, #1
	STRB R1, [R8, R12]
	MOV PC, LR


zeroZregister:
	STRB R8, [R2, R12]

	CMP R9, #32
	MOVEQ PC, LR

	ADD R12, #1
	ADD R9, #1
	B zeroZregister


inputOperands://you really need to check this later
	PUSH {R2}
	LDR R2, =memory
	LDRB R9, [R2, R8]				//load most significant byte first
	ADD R8, #1						//change offset

	LDR R2, =Z_registers
	STRB R9, [R2, R12]				//store most significant byte first
	ADD R12, #1						//update Zregister offset

	LDR R2, =memory
	LDRB R9, [R2, R8]				//load least siginificant byte

	LDR R2, =Z_registers
	STRB R9, [R2, R12]				//store least significant byte

	ADD R8, #3						//go to next memory location
	ADD R12, #1						//update Zregister offset
	POP {R2}
	SUBS R2, #1						//number of inputs left

	MOVEQ PC, LR
	B inputOperands

	/*
		3. The Zprocedure call could have had up to
		7 inputs (the very first operand to a call instruction
		is always the call target and it isnt
		an input to a Zprocedure). Write the second
		operand of the call instruction into the
		first Zprocedure-local Zregister, the third
		operand into the second one and so on, until
		you run of out operands
	*/

Returns:
	//check if any values are important
	//obtain your return value and save it into an ARM register
	//r0 should hold return value
	PUSH {R0}
	BL clearStack

	PUSH {R2}
	LDR R2, =Z_registers

	MOV R12, #0x1					//find location of current zregisters
	BL locateZregister
	ADD R12, #24					//24th current local Zregister (contains old ZPC) (higher order byte)
	LDRB R0, [R2, R12]		//load old ZPC higher order
	LSL R0, R0, #8				//make it higher order byte
	ADD R12, #1						//24th local zregister (lower)
	LDRB R4, [R2, R12]		//load old zpc lower order
	ADD R4, R4, R0				//full old ZPC

	SUB R6, #1						//decrement nesting depth by one

	ADD R12, #3						//28th localzregister (higher)
	LDRB R0, [R2, R12]		//load destination zregister(higher)
	LSL R0, R0, #8				//make it higher
	ADD R12, #1
	LDRB R1, [R2, R12]		//load destination zregister (lower)
	ADD R12, R0, R1				//r12 now holds destination zregister
	POP {R2}
	POP {R0}

	CMP R12, #0xff
	BHI decode		//no return registers

	MOV R11, R0								//store functions take R11 as the value to store
											//store functions take R12 as destination
	BL storeFunction

	ADD R4, #1
	B decode		//continue execution with the instruction at ZPC


clearStack:
	PUSH {R14}
	BL stackPop					//call stackPop
	CMP R11, #0					//is the ZSP at 0, aka is stack empty?
	POPEQ {R15}				//if 0, go back

	B clearStack				//pop again
