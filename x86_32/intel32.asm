;=====================================================================
;
; Author:      Richard Staszkiewicz
; Date:        2021-06-07
; Description: Function filles the given arrays with the coordinates (+) of
;              markers found in given bitmap.
;       ####
;       ####
;   ########
;   #######+
;=====================================================================

;=====================================================================
;===================IMPORTANT ADRESSES ON STACK=======================
; in find_markers & main
; [ebp + 8]		-> unsigned char *bitmap (never changing constant)
; [ebp + 12]	-> unsigned int *x_pos (never changing constant)
; [ebp + 16]	-> unsigned int *y_pos (never changing constant)
;
;
; in find_marker & else:




section .text

global find_markers
find_markers:
    push	ebp					;remember last EBP
	mov		ebp, esp			;adress of new EBP

	; begins of data pushing
	mov		eax, 0
	push	eax					;pushed AMOUNT
	mov		eax, [ebp + 12]
	push	eax					;pushed *USED
	mov 	eax, [ebp + 8]
	add 	eax, 10
	add		eax, [eax]


	;jmp		main				;call main function (to be implemented in here)

	mov		eax, [ebp + 12]		;return 0
	mov		esp, ebp			;delete all local variables
	pop		ebp
	ret


;============================================
; THE STACK
;============================================
;
; larger addresses
;
;  |             ...               |
;  | parameter - int *y_pos        | EBP+20
;  ---------------------------------
;  | parameter - int *x_pos        | EBP+16
;  ---------------------------------
;  | parameter - char *used        | EBP+12
;  ---------------------------------
;  | parameter - char *bitmap      | EBP+8
;  ---------------------------------
;  | return address (main.cpp)     | EBP+4
;  ---------------------------------
;  | saved ebp                     | EBP, ESP (find markers)
;  ---------------------------------
;  | amount                        | EBP-4
;  ---------------------------------
;  | *used  -> beginning           | EBP-8				EBP+36
;  ---------------------------------
;  | *image -> beginning           | EBP-12				EBP+32
;  ---------------------------------
;  | width  -> const.              | EBP-16				EBP+28
;  ---------------------------------
;  | length -> const.              | EBP-20				EBP+24
;  ---------------------------------
;  | curr_y -> const.              | EBP-24				EBP+20
;  ---------------------------------
;  | curr_x -> const.              | EBP-28				EBP+16
;  ---------------------------------
;  | curr_used -> flex.            | EBP-32				EBP+12
;  ---------------------------------
;  | curr_img -> flex.             | EBP-36				EBP+8
;  ---------------------------------
;  | return address (mainL)        | EBP-40				EBP+4
;  ---------------------------------
;  | saved ebp                     | EBP, ESP (find_marker)
;  ---------------------------------
;  | curr_y -> flex.               | EBP-4
;  ---------------------------------
;  | curr_x -> flex.               | EBP-8
;  ---------------------------------
;  | curr_used -> flex.            | EBP-12
;  ---------------------------------
;  | curr_img -> flex.             | EBP-16
;
; \/                              \/
; \/ the stack grows in this      \/
; \/ direction                    \/
;
; lower addresses
;
;
;============================================
