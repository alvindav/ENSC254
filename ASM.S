.global asm_main
.global Z_memory
.global Z_stack
.global Z_registers
.global Z_instructions
.global memory
.global decode_instructions_loop
.global checkUpload

.align 4
Z_memory: .space 2000000 //should hold 2 megabytes //will hold the uploaded zprogram, this is the zmemory
.align 4

Z_stack: .space 1000000 //should hold 1 megabyte
.align 4

Z_registers: .space 1000000 //should hold 1 megabyte
.align 4

Z_instructions: .space 256
.align 4

memory: .space 1000000
.align 4

asm_main:
	MOV R0, #0 //operands
	MOV R1, #0 //operands
	LDR R2, =0x41220000 //switches
	MOV R3, #0 //branch instruction
	MOV R4, #0 //ZPC //pointer offset
	LDR R5, =Z_stack //ZSP
	MOV R6, #0 //function call nesting depth
	LDR R7, =Z_memory
	LDR R8, =0xE000102C //transmitter
	LDR R9, =0xE0001030 //UART
	MOV R10, #0 //current opcode
	MOV R11, #0 //pointer offset max
	MOV R12, #0 //random values

start:
	LDR R12, =#0x20
	LDR R11, =0xE0001004
	STR R12, [R11]

	MOV R12, #62
	LDR R11, =0xE0001018
	STR R12, [R11]

	MOV R12, #6
	LDR R11, =0xE0001034
	STR R2, [R8]

	LDR R12, =#0x117
	LDR R11, =0xE0001000
	STR R12, [R11]

	LDR R12, =memory
	STR R2, [R12, #0] //Switches
	STR R8, [R12, #4] //Transmitter
	STR R9, [R12, #8] //Upload/Writing

	MOV R11, #20
	STRB R11, [R12, #16]

	MOV R11, #0x4000
	STR R11, [R12, #56] //globals location //is it STRH
	//#12 contains max offset
	//#16 contains current variable offset
	//#20 contains variable 1
	//#24 contains variable 2
	//#28 contains variable 3
	//#32 contains variable 4
	//#36 contains variable 5
	//#40 contains variable 6
	//#44 contains variable 7
	//#48 contains variable 8
	//#52 contains the stack pointer
	//#56 contains the globals location
	//#60 contains ???? number of operands
	//#64 contains state of debug

	MOV R11, #0
	MOV R12, #0

checkUpload:
		LDR R2, =0x41220000
    LDR R12, [R2]           //load the value of the switches into R12
    TST R12, #0b10000000    //if 7th switch is up, clear the Zmemory
    BNE clearMemory         //branch if 7th bit is set //calls checkInput
    B checkUpload           //keep checking until upload mode

checkInput:
  	LDR R12, [R8]						//R8 = 0xE000102C transmitter
  	TST R12, #0b10				  //if 2nd bit of receiver is 0, there is an input
  	BEQ startUpload

    LDR R12, [R2]
    TST R12, #0b10000000    //if switch7 is still up, continue to check for input
    BNE checkInput

    LDR R0, =memory
    STR R11, [R0, #12]      //after finishing upload mode, store the max zmemory offset into memory
  	B checkHeader

startUpload:
    LDRB R10, [R9]          //load byte from UART R9 = 0xE0001030
    STRB R10, [R7, R11]     //store into Zmemory
    ADD R11, #1             //increment R11, the max zmemory offset
    B checkInput            //go back to checking input


checkHeader:
    LDR R10, =#100000       //debounce
    BL debounce

    LDR R12, [R2]
    TST R12, #0b01000000    //if 6th switch is up, we are in header mode
    BLNE headerMode
    BL debugSwitch

    B decode_instructions_loop

headerMode:
  	LDRB R8, [R7, #4]						//higher order byte first instruction zpc
  	LDRB R9, [R7, #5]						//lower order byte first instruction zpc
  	LSL R8, R8, #8
  	ADD R8, R8, R9
  	MOV R4, R8								  //start ZPC here

  	MOV R8, #0x0C
  	LDR R12, =memory
  	STRH R8, [R12, #56]         //globals location	//is it STRH
		STR R4, [R12, #68]			//first instructionZPC

  	MOV R8, #0
  	MOV R9, #0
  	MOV R12, #0

    MOV PC, LR

debugSwitch:
		LDR R12, =memory
		LDR R8, [R2]
    AND R8, R8, #0b00100000
    STR R8, [R12, #64]          //state of debug, if 1, debug is on
                                //if 0, debug is off
    MOV R8, #0
    MOV R12, #0

    MOV PC, LR


clearMemory:
    LDR R10, =#100000 //debounce
    BL debounce

  	LDR R10, =#250000 //Zstack
  	LDR R11, =#500000 //Zmemory
  	MOV R12, #0
  	BL clearZStack
  	BL clearZ

  	LDR R0, =Z_registers
  	LDR R10, =#250000
  	BL clearZreg

  	MOV R10, #0
  	MOV R11, #0
  	LDR R8, =0xE000102C //transmitter
    B checkInput

clearZStack:
  	STRB R12, [R5, R10]
  	SUBS R10, #1
  	MOVMI PC, LR
  	B clearZStack

clearZ:
  	STRB R12, [R7, R11]
  	SUBS R11, #1
  	MOVMI PC, LR
  	B clearZ

clearZreg:
  	STRB R12, [R0, R10]
  	SUBS R10, #1
  	MOVMI PC, LR
  	B clearZreg

debounce:
    SUBS R10, #1
    MOVEQ PC, LR
    B debounce

decode_instructions_loop:
  	BL checkZPC
  	LDRB R10, [R7, R4] 						//Take OPCODE from Zmemory
  	ADD R4, #1								    //Increment ZPC

  	AND R12, R10, #0b11000000 		//Check if R10 is an A-type
  	CMP R12, #0b10000000 					//If CMP returns the zero flag, go to Atype
  	BEQ Atype								      //go to Atype

  	CMP R12, #0b11000000 					//if CMP returns the zero flag, go to Ctype
  	BEQ Ctype								      //go to Ctype

  	B Btype									      //if not Atype or Ctype, go to Btype

checkZPC:
  	LDR R2, =memory
  	LDR R0, [R2, #12]
  	CMP R0, R4
		MOV R12, #20
		STRB R12, [R2, #16]	//reset the variable operands offset

  	MOVHI PC, LR

  	LDR R2, =0x41220000
  	MOV R4, #0
  	B checkUpload
