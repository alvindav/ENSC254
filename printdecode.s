.global decode_text

decode_text:
	MOV R8, R1			//to check for question mark

	CMP R1, #0			//space
	MOVEQ R1, #32

	CMP R1, #1			//newline
	MOVEQ R1, #10

	CMP R1, #6			//a
	MOVEQ R1, #97

	CMP R1, #7			//b
	MOVEQ R1, #98

	CMP R1, #8			//c
	MOVEQ R1, #99

	CMP R1, #9			//d
	MOVEQ R1, #100

	CMP R1, #10			//e
	MOVEQ R1, #101

	CMP R1, #11			//f
	MOVEQ R1, #102

	CMP R1, #12			//g
	MOVEQ R1, #103

	CMP R1, #13			//h
	MOVEQ R1, #104

	CMP R1, #14			//i
	MOVEQ R1, #105

	CMP R1, #15			//j
	MOVEQ R1, #106

	CMP R1, #16			//k
	MOVEQ R1, #107

	CMP R1, #17			//l
	MOVEQ R1, #108

	CMP R1, #18			//m
	MOVEQ R1, #109

	CMP R1, #19			//n
	MOVEQ R1, #110

	CMP R1, #20			//o
	MOVEQ R1, #111

	CMP R1, #21			//p
	MOVEQ R1, #112

	CMP R1, #22			//q
	MOVEQ R1, #113

	CMP R1, #23			//r
	MOVEQ R1, #114

	CMP R1, #24			//s
	MOVEQ R1, #115

	CMP R1, #25			//t
	MOVEQ R1, #116

	CMP R1, #26			//u
	MOVEQ R1, #117

	CMP R1, #27			//v
	MOVEQ R1, #118

	CMP R1, #28			//w
	MOVEQ R1, #119

	CMP R1, #29			//x
	MOVEQ R1, #120

	CMP R1, #30			//y
	MOVEQ R1, #121

	CMP R1, #31			//z
	MOVEQ R1, #122

	CMP R8, R1
	MOVEQ R1, #63

	MOV PC, LR
