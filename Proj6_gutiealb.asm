TITLE Project 6    (Proj6_gutiealb.asm)

; Author: Alberto Ramses Gutierrez
; Last Modified: 3/19/23
; OSU email address: gutiealb@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number:  6               Due Date: 3/19/23
; Description: This program uses macros, string primitives, and procedure calls to get 10 signed numbers from the user, get the average and sum, then converts them to strings and prints them.

INCLUDE Irvine32.inc

; (insert macro definitions here)
mGetString MACRO prompt,input,count

	;preserve registers
	PUSH	EAX
	PUSH	ECX
	PUSH	EDX

	;print prompt
	MOV		EDX, OFFSET prompt
	CALL	WriteString

	;store input
	MOV		EDX, OFFSET input
	MOV		ECX, SIZEOF	input
	CALL	ReadString
	MOV		count, EAX

	;restore registers
	POP		EDX
	POP		ECX
	POP		EAX

ENDM

mDisplayString MACRO string
	;preserve register
	PUSH	EDX

	;print string
	MOV		EDX, OFFSET string
	CALL	WriteString

	;restore register
	POP		EDX

ENDM
; (insert constant definitions here)
.data

; (insert variable definitions here)
userNum		SDWORD	?
numSum		SDWORD	?
numAvg		SDWORD	?
storage		BYTE	10 DUP(?)
printRdy	BYTE	10 DUP(?)
numList		SDWORD	10 DUP(?)
convertStr	BYTE	11 DUP(?)
userStr		BYTE	11 DUP(?)
intro1		BYTE	"PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures",13,10
			BYTE	"Written by: Alberto Ramses Gutierrez",13,10,0
intro2		BYTE	"Please provide 10 signed decimal integers.",13,10  
			BYTE	"Each number needs to be small enough to fit inside a 32 bit register. After you have finished inputting the raw numbers I will display a list of the integers, their sum, and their average value.",13,10,0
numPrompt	BYTE	"Please enter a signed number: ",0
numError	BYTE	"ERROR: You did not enter a signed number or your number was too big",13,10,0
numsEnt		BYTE	"You entered the following numbers: ",13,10,0
msgSum		BYTE	"The sum of these numbers is: ",13,10,0
msgAvg		BYTE	"The truncated average is: ",13,10,0
goodbye		BYTE	"Thanks for playing!",0
.code
main PROC

; (insert executable instructions here)
	mDisplayString	intro1
	mDisplayString  intro2
	MOV		ECX, 10
	
	;prepare to move userNum into numList
	MOV		EDI, OFFSET numList

_numLoop:
	PUSH	OFFSET userStr
	PUSH	OFFSET convertStr
	PUSH	OFFSET numError
	PUSH	userNum
	CALL	ReadVal

	;userNum now has number. will be entered into numList to fill array
	MOV		EAX, userNum
	MOV		[EDI], EAX
	ADD		EDI, 4
	LOOP	_numLoop

	MOV		EAX, 0			;clear EAX for calculation
	MOV		ESI, OFFSET numList
	MOV		ECX, 10
	;calculate sum of numList
_sumLoop:
	ADD		EAX, [ESI]
	ADD		ESI, 4
	LOOP	_sumLoop
	MOV		numSum, EAX		;save Sum into numSum

	;calculate avg of numbers
	MOV		EAX, numSum
	MOV		EBX, 10
	IDIV	EBX
	MOV		numAvg, EAX		;save average into numAvg


	;loop to print num array
	mDisplayString	numsEnt
	MOV		ESI, OFFSET numList
	MOV		ECX, 10
_numLoop2:
	PUSH	OFFSET storage
	PUSH	OFFSET printRdy
	PUSH	[ESI]
	CALL	WriteVal
	ADD		ESI, 4
	LOOP	_numLoop2

	;print numSum as string
	mDisplayString	msgSum
	PUSH	OFFSET storage
	PUSH	OFFSET printRdy
	PUSH	numSum
	CALL	WriteVal

	;print numAvg as string
	mDisplayString	msgAvg

	PUSH	OFFSET storage
	PUSH	OFFSET printRdy
	PUSH	numAvg
	CALL	WriteVal

	mDisplayString	goodbye
	Invoke ExitProcess,0	; exit to operating system
main ENDP

; (insert additional procedures here)
ReadVal PROC
	LOCAL	sLen:DWORD	;build stack frame, make sLen for macro call

	;preserve registers
	PUSH	EDX
	PUSH	EDI
	PUSH	ESI
	PUSH	ECX
	PUSH	EAX
	PUSH	EBX

_inputLoop:
    mGetString numPrompt, userStr, sLen

    ; Check for valid input (digit or sign)
    MOV     ECX, sLen
    MOV     ESI, OFFSET userStr
    MOV     EDI, 0            ; Used to store sign: 0 for positive, 1 for negative
    MOV     EBX, 0            ; Clear EBX for storing number

    CLD                         ; Clear direction flag for forward LODSB
    LODSB
    CMP     AL, '-'             ; Check for negative sign
    JE      _negSign
    CMP     AL, '+'             ; Check for positive sign
    JE      _posSign
    CMP     AL, '0'             ; Check if first character is a digit
    JB      _error
    CMP     AL, '9'
    JA      _error
    JMP     _convLoop

_negSign:
    MOV     EDI, 1              ; Mark as negative
    JMP     _convLoop

_posSign:
    JMP     _convLoop

_convLoop:
    LODSB
    CMP     AL, 0               ; End of string?
    JE      _doneConv
    CMP     AL, '0'             ; Validate digit
    JB      _error
    CMP     AL, '9'
    JA      _error

    SUB     AL, '0'             ; Convert to numeric value
    IMUL    EBX, 10             ; Multiply previous value by 10
    ADD     EBX, EAX            ; Add new digit
    JMP     _convLoop

_doneConv:
    CMP     EDI, 1
    JNE     _storeVal
    NEG     EBX                 ; Apply negative sign if necessary

_storeVal:
    MOV     userNum, EBX
    JMP     _end

_error:
    mDisplayString numError
    JMP     _inputLoop

_end:
    POP     EDI
    POP     ESI
    POP     EDX
    POP     ECX
    POP     EBX
    POP     EAX
    RET     16
ReadVal ENDP

; WriteVal Procedure - Converts signed integer to string and displays it
WriteVal PROC
    PUSH    EBP
    MOV     EBP, ESP

    PUSH    EAX
    PUSH    EBX
    PUSH    ECX
    PUSH    EDX
    PUSH    EDI

    ; Convert number to string
    MOV     EAX, [EBP+8]        ; Get the number
    MOV     EDI, [EBP+16]       ; Destination for string
    MOV     ECX, 10             ; Divisor for conversion

    ; Handle negative numbers
    CMP     EAX, 0
    JGE     _convertLoop
    NEG     EAX                 ; Make positive for conversion
    MOV     BYTE PTR [EDI], '-' ; Add negative sign
    INC     EDI

_convertLoop:
    XOR     EDX, EDX
    IDIV    ECX
    ADD     DL, '0'
    MOV     [EDI], DL
    INC     EDI
    CMP     EAX, 0
    JNE     _convertLoop

    ; Reverse the string
    MOV     ESI, [EBP+16]
    MOV     EDI, [EBP+12]
    MOV     ECX, 10             ; Reverse the string
    CLD
    REP MOVSB

    ; Display the string
    mDisplayString printRdy

    ; Clean up and return
    POP     EDI
    POP     EDX
    POP     ECX
    POP     EBX
    POP     EAX
    POP     EBP
    RET     4
WriteVal ENDP
END main
