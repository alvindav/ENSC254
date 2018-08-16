.global Atype
.global Btype
.global Ctype
.global locateZregister
.global stackPop
.global storeZregister
.global storeGlobal
.global locateGlobal
.global stackPush

Atype:
	AND R12, R10, #0b00110000

	CMP R12, #0b00110000 //no operands
	MOVEQ R2, #0		//R2 number of operands
	BEQ Atype_instruction

	MOV R2, #1

	PUSH {R12}
	CMP R12, #0b00100000
	BLEQ RegisterIndicator          //after calling, R11, should contain the first 16bit operand
	MOVEQ R0, R11                   //move R11 into the first operand R0 //ZPC incremented
	POP {R12}
	BEQ Atype_instruction           //continue to instruction

	PUSH {R12}
	CMP R12, #0b00010000
	BLEQ OneByte_Constant			//after calling, R11 should contain the OneByte constant //ZPC incremented
	MOVEQ R0, R11                   //move R11 into the first operand R0
	POP {R12}
	BEQ Atype_instruction           //continue to instruction

	CMP R12, #0b00000000
	BLEQ TwoByte_Constant			//after calling, R11 should contain the TwoByte constant //ZPC incremented twice
	MOVEQ R0, R11                   //move R11 into the first operand R0
	B Atype_instruction             //continue to instruction

Btype:
	TST R10, #0b01000000			//AND the 6th bit,
	BLNE RegisterIndicator			//If 1, one-byte register indicator

	TST R10, #0b01000000
	BLEQ OneByte_Constant			//If 0, one-byte constant
	MOV R0, R11						//Assign located value to operand 1

	BL storeOperands

	TST R10, #0b00100000			//AND the 5th bit
	BLNE RegisterIndicator			//If 1, one-byte register indicator

	TST R10, #0b00100000
	BLEQ OneByte_Constant			//if 0, one-byte constant
	MOV R1, R11						//Assign located value to operand 2

	BL storeOperands

	B Btype_instruction				//with the operands, now check instruction

Ctype:
	LDRB R8, [R7, R4]					//load variable operand indicator
	ADD R4, #1								//increment ZPC

	TST R10, #0b00100000
	MOVEQ R2, #2
	BEQ TwoOperands

	MOV R2, #0								//reset # of operands tracker
	B VariableOperand

OneByte_Constant:
	LDRB R11, [R7, R4]
	ADD R4, #1
	MOV PC, LR

TwoByte_Constant:
    PUSH {R14}
    PUSH {R2}
    LDR R2, =Z_memory
    MOV R12, R4                     //R12 should contain the offset, in this case, it is the ZPC
    BL loadHalfword
    POP {R2}
    ADD R4, #2                      //increment ZPC twice, the byte after the lower order twobyte constant
	POP {R15}

RegisterIndicator:
	PUSH {R14}
	PUSH {R2}
	LDRB R12, [R7, R4] 				//R12 contains destination
	ADD R4, #1					//increment ZPC

	CMP R12, #0x00					//Zstack
	BLEQ stackPop					//after calling, R11 should contain the 16bit value popped from the stack

	CMP R12, #0x00				//R12 should have returned after stackPop
	POPEQ {R2}
	POPEQ {R15}						//if R12 contained the Zstack destination, return


	RSBS R2, R12, #0x0f			//check if its localZregister
	BLPL loadZregister				//after calling, R11 now contains the value within the Zregister

	RSBS R2, R12, #0x0f			//R12 should have returned after loadZregister
	POPPL {R2}
	POPPL {R15}


	SUBS R2, R12, #0x10			//check if its globalZregister
	BLPL loadGlobal					//after calling, R11 now contains the value within the Zregister

	POP {R2}
	POP {R15}


VariableOperand:
	AND R9, R8, #0b11000000
	//R9 will hold the current 2Bits
	//R8 will hold the variable operand indicator

	CMP R9, #0b11000000
	BEQ Ctype_Var


	PUSH {R8, R9}
	CMP R9, #0b10000000
	BLEQ RegisterIndicator
	POP {R8, R9}

	PUSH {R8, R9}
	CMP R9, #0b01000000
	BLEQ OneByte_Constant
	POP {R8, R9}

	PUSH {R8, R9}
	CMP R9, #0b00000000
	BLEQ TwoByte_Constant
	POP {R8, R9}

                        //R11 should contain the operand value
	ADD R2, #1						//R2 holds how many operands we have
	BL storeOperands
	LSL R8, R8, #2				//to the 7th and 6th bit
	B VariableOperand

TwoOperands:
	AND R9, R8, #0b11000000
	//R9 will hold the current 2Bits
	//R8 will hold the variable operand indicator

	CMP R9, #0b11000000
	BEQ storeTwo


	PUSH {R8, R9}
	CMP R9, #0b10000000
	BLEQ RegisterIndicator
	POP {R8, R9}

	PUSH {R8, R9}
	CMP R9, #0b01000000
	BLEQ OneByte_Constant
	POP {R8, R9}

	PUSH {R8, R9}
	CMP R9, #0b00000000
	BLEQ TwoByte_Constant
	POP {R8, R9}

                        //R11 should contain the operand value
	BL storeOperands
	LSL R8, R8, #2				//to the 7th and 6th bit
	B TwoOperands

storeTwo:
	PUSH {R2, R8, R9}
	LDR R2, =memory							//for operand loading

	LDRB R8, [R2, #20]
	LDRB R9, [R2, #21]
	LSL R8, R8, #8
	ADD R0, R8, R9

	LDRB R8, [R2, #24]
	LDRB R9, [R2, #25]
	LSL R8, R8, #8
	ADD R1, R8, R9

	POP {R2, R8, R9}
	B Ctype_Two								//R0 and R1 contain the FIRST and SECOND operands

storeOperands:
    PUSH {R8, R9}
	PUSH {R2}
	LDR R2, =memory					//access mymemory
	LDRB R12, [R2, #16]				//#16 contains current variable offset

    PUSH {R11}
    LSR R8, R11, #8                 //make R8 hold the higher order byte
    POP {R11}
    MOV R9, R11                     //make R9 hold the 16bits but only store the least significant

	STRB R8, [R2, R12]				//store higher order byte
	ADD R12, #1						//update variable offset
	STRB R9, [R2, R12]              //store lower order byte

	ADD R12, #3
	STRB R12, [R2, #16]				//update variable offset in memory

	POP {R2}

	POP {R8, R9}
	MOV PC, LR


stackPop://stack values assumed to be 16bit
	PUSH {R14}
	PUSH {R12}						//in case R12 contains something important	//check if this interferes
	MOV R12, #0xB					//should be the 20th localZregister
	BL loadZregister				//R11 should contain the value within the 20th localZregister
									//20th localZregister = ZStackPointer = zstack offset

	CMP R11, #0						//cannot pop if 0
	POPEQ {R12}
	POPEQ {R15}

	LDR R2, =Z_stack				//make R2 the memory address of the Zstack for the loadHalfword function
	MOV R12, R11                    //make R12 the ZStack offset                for the loadHalfword function
    SUB R12, #2						//grab the top most value in the stack
    BL loadHalfword                     //R11 should contain the value popped from the stack
	MOV R0, R11


	SUB R12, #1						//Decrement the ZStackPointer
	MOV R11, R12					//move ZSP value into R11, because storeZregister takes R11 as the value to store
	MOV R12, #0xB					//should be the 20th localZregister offset
	BL storeZregister

	MOV R11, R0
	POP {R12}						//in case R12 contains something important 	//check if this interferes
	POP {R15}

stackPush:
	PUSH {R14}
	PUSH {R2}
	PUSH {R11}

	MOV R12, #0xB					//should be the 20th localZregister
	BL loadZregister				//R11 should contain the value within the 20th localZregister
									//20th localZregister = ZStackPointer = zstack offset

	MOV R2, R5				//make R2 the memory address of the Zstack for the storeHalfword function
	MOV R12, R11                    //make R12 the ZStack offset                for the storeHalfword function
    POP {R11}						//restore the value
    BL storeHalfword                //R11 should contain the value to store after calling


	ADD R12, #1						//increment the ZStackPointer ((store halfword incremented by 1 already)
	MOV R11, R12					//move ZSP value into R11, because storeZregister takes R11 as the value to store
	MOV R12, #0xB					//should be the 20th localZregister offset
	BL storeZregister
	POP {R2}

	POP {R15}


locateZregister:					//local
	PUSH {R14}
  PUSH {R11}                      //in case R11 contains something important

	SUB R12, #1
	LSL R12, R12, #1    			//A = location of Z registers within set of 32
	LSL R11, R6, #6				    //B = multiply nesting depth by 64
	ADD R12, R12, R11				//C = offset of your local Z register within a given Z procedure

	POP {R11}                       //in case R11 contains something important
	POP {R15}

loadZregister:						//local //R12 should contain the destination when called
	PUSH {R14}
	PUSH {R12}								//in case R12 contains something important //check if this interferes
	BL locateZregister				//after calling, R12 should contain the offset of the localZregister

	PUSH {R2}
	LDR R2, =Z_registers            //pass in Z_registers memory locaiton
	                                //R12 contains the offset
	BL loadHalfword                 //R11 should contain the value obtained
	POP {R2}

	POP {R12}							//in case R12 contains something important //check if this interferes
	POP {R15}

storeZregister:
	PUSH {R14}
	BL locateZregister				//after calling, R12 should contain the offset of the localZregister

	PUSH {R2}
	LDR R2, =Z_registers
	BL storeHalfword				//R2 needs to hold the memory location
	POP {R2}

	POP {R15}

locateGlobal:
	PUSH {R14}
	PUSH {R11}
	PUSH {R2}
	SUB R12, #16
	MOV R12, R12, LSL #1			//A = location of globalZregister

	LDR R2, =memory
	LDR R11, [R2, #56]

	ADD R12, R12, R11

	POP {R2}
	POP {R11}
									//R12 contains the high order byte of the global Zregister
	POP {R15} 						//R12 now contains the offset for the globalZregister

loadGlobal:
	PUSH {R14}
	PUSH {R12}
	BL locateGlobal                 //after calling, R12 should contain the offset of the globalZregister in Zmemory

	PUSH {R2}
	LDR R2, =Z_memory
	BL loadHalfword                     //R11 should contain the value obtained
	POP {R2}

	POP {R12}
	POP {R15}

storeGlobal:
    PUSH {R14}
    BL locateGlobal                 //R12 should contain the offset of the globalZregister in Zmemory

    PUSH {R2}
    LDR R2, =Z_memory
    BL storeHalfword
    POP {R2}

	POP {R15}

loadHalfword:
	PUSH {R14}

	//when called:
    //R2 = memory location
    //R12 = offset

	LDRB R8, [R2, R12]				//higher order byte of constant
	ADD R12, #1
	LDRB R9, [R2, R12]				//Lower order byte of constant

    LSL R8, R8, #8                  //make R8 the higher byte
    ADD R11, R8, R9                 //add higher byte + lower byte (R8 + R9)

    //when returned:
	//R8 = higher order byte
	//R9 = lower order byte
	//R11 = 16 bit value
	//R12 = new offset

	POP {R15}

storeHalfword:
    //R2 should hold the memory to store to
    //R11 should hold the full 16 bit value to store
    //R12 should hold the offset of the memory
    PUSH {R14}

    PUSH {R8, R9}                   //in case R8 and R9 contain something important

    PUSH {R11}
    LSR R8, R11, #8                 //make R8 hold the higher order byte
    POP {R11}
    MOV R9, R11                     //make R9 hold the 16bits but only store the least significant

    STRB R8, [R2, R12]
    ADD R12, #1
    STRB R9, [R2, R12]


    POP {R8, R9}

    POP {R15}
