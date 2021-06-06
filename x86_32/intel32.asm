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
;=====================================================================
;============================================
;
; THE STACK
;============================================
;
; larger addresses
;
;  |             ...               |
;  | parameter - int height        | EBP+28
;  ---------------------------------
;  | parameter - int width         | EBP+24
;  ---------------------------------
;  | parameter - int *y_pos        | EBP+20
;  ---------------------------------
;  | parameter - int *x_pos        | EBP+16
;  ---------------------------------
;  | parameter - char *used        | EBP+12
;  ---------------------------------
;  | parameter - char *image       | EBP+8
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
;  | height -> const.              | EBP-20				EBP+24
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
;  ---------------------------------
;
;
; \/                              \/
; \/ the stack grows in this      \/
; \/ direction                    \/
;
; lower addresses
;
;
;====================REGISTERS USAGE========================
; EAX			Accumulator / function return value 1
; ECX			Accumulator / function return value 2
; EDX			in find_marker: PRINT FLAG



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
	push	eax					;pushed *IMAGE
	mov		eax, [ebp + 24]
	push	eax					;pushed width
	mov		eax, [ebp + 28]
	push	eax					;pushed height
	mov		eax, -1
	push	eax					;pushed current y coordinate
	mov		eax, -1
	push	eax					;pushed current x coordinate
	mov		eax, [ebp + 12]
	push	eax					;pushed current pos in USED
	mov		eax, [ebp + 8]
	push	eax					;pushed current adress in IMAGE


main_ly:
	mov		eax, [ebp - 24]
	inc 	eax
	mov		[ebp - 24], eax		;increment curr_y position
	mov		eax, -1
	mov		[ebp - 28], eax		;set curr_x to -1 (we begin next row)

	mov		eax, [ebp + 28]
	cmp		[ebp - 24], eax		; compare curr_y with height
	je		exit				; if the curr_y is equal to height, finish


main_lx:
	mov		eax, [ebp - 28]
	inc		eax
	mov		[ebp - 28], eax		;increment curr_x position

	cmp		eax, [ebp + 24]		;compare curr_x with width
	je		main_ly				;if curr_x is equal width, jump to ly

	call	find_marker			;call the function checking for marker
	cmp		eax, 0
	je		main_con			;if the EAX is equal 0, don't save the coordinates

	mov		eax, [ebp + 16]		;current pos in ANSWER_X
	mov		ecx, [ebp - 28]
	mov		[eax], DWORD ecx	;save current_x in ANSWER_X
	add		eax, 4
	mov		[ebp + 16], eax		;actualise current pos in ANSWER_X

	mov		eax, [ebp + 20]		;current pos in ANSWER_Y
	mov		ecx, [ebp - 24]
	mov		[eax], DWORD ecx	;save current_y in ANSWER_Y
	add		eax, 4
	mov		[ebp + 20], eax		;actualise current pos in ANSWER_Y

	mov		eax, [ebp - 4]
	inc		eax
	mov		[ebp - 4], EAX		;increment amount of found markers

main_con:
	mov		eax, [ebp - 32]
	inc		eax
	mov		[ebp - 32], eax		;increment position in USED

	mov		eax, [ebp - 36]
	add		eax, 3
	mov		[ebp - 36], eax		;increment position in IMAGE

	jmp		main_lx				;jump to next x



exit:
	mov		eax, [ebp - 4]		;return AMOUNT of found markers
	mov		esp, ebp			;delete all local variables
	pop		ebp
	ret




find_marker:
;	arguments - ons stack
;	return
;		-> register EAX - 0 (no marker), 1 (marker)

	push	ebp
	mov		ebp, esp			;remember the last EBP

	; check if is used & if so, end
	mov		eax, [ebp + 12]
	mov		ecx, [eax]			;read the value of used pixel
	cmp		ecx, 0
	jne		exit_fm				;if is not equal 0, end search
	mov		[eax], DWORD 1		;mark pixel as used (int32 as declared in main.cpp)

	mov		eax, [ebp + 20]
	push	eax					;push current Y (flexible)
	mov		eax, [ebp + 16]
	push	eax					;push current X (flexible)
	mov		eax, [ebp + 12]
	push 	eax					;push current USED (flexible)
	mov		eax, [ebp + 8]
	push 	eax					;push current IMAGE (flexible)
	mov 	eax, DWORD 0
	push	eax					;initiate marker_len (int32)
	push	eax					;initiate marker_width (int32)
	push	eax					;initiate marker_hgh (int32)

	mov		eax, [ebp + 8]
	push	eax					;push current Image pos (get_pixel arg)
	mov		eax, [ebp + 20]
	push	eax					;push current Y (get_pixel arg)
	mov		eax, [ebp + 16]
	push	eax					;push current X (get_pixel arg)
	call	get_pixel
	cmp		eax, 0
	jne		exit_fm				;if pixel is not black (0x000000) jump to end

	pop		eax					;take off X from stack
	pop		eax					;take off Y from stack
	pop		eax					;take off Image pos from stack

exit_fm:
	mov		eax, 1				;return 1

	mov		esp, ebp
	pop		ebp
	ret


get_pixel:
; arguments: on stack ([ebp+8] -> x, [ebp+12] -> y, [ebp+16] -> image_pos)
; return: Pixel colour in EAX 0x00BBGGRR
	push	ebp
	mov 	ebp, esp
	push	ebx

	mov		ebx, [ebp + 16]		;pixel adress in image to EBX
	movzx	eax, BYTE [ebx]			;load B
	movzx	ecx, BYTE [ebx + 1]		;load G
	shl		ecx, 8
	or		eax, ecx			;accumulate
	movzx	ecx, BYTE [ebx + 2]		;load R
	shl		ecx, 16
	or		eax, ecx			;accumulate

	pop		ebx
	mov		esp, ebp
	pop		ebp
	ret