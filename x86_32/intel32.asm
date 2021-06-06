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
;  | amount                        |
;  ---------------------------------
;  | *used  -> beginning           | EBP+36
;  ---------------------------------
;  | *image -> beginning           | EBP+32
;  ---------------------------------
;  | width  -> const.              | EBP+28
;  ---------------------------------
;  | height -> const.              | EBP+24
;  ---------------------------------
;  | curr_y -> const.              | EBP+20
;  ---------------------------------
;  | curr_x -> const.              | EBP+16
;  ---------------------------------
;  | curr_used -> flex.            | EBP+12
;  ---------------------------------
;  | curr_img -> flex.             | EBP+8
;  ---------------------------------
;  | return address (mainL)        | EBP+4
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
;  | marker_len -> flex.           | EBP-20
;  ---------------------------------
;  | marker_width -> flex.         | EBP-24
;  ---------------------------------
;  | marker_hgh-> flex.            | EBP-28
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
	mov		edx, 1				;PRINT FLAG set to true

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

	;markers potential length
	jmp		get_len
	and		edx, ecx			;bitwise AND via print flag
	mov		[ebp - 20], eax		;move result to proper place on stack


exit_fm:
	mov		eax, edx			;return edx

	mov		esp, ebp
	pop		ebp
	ret

;==========================================================================
;============================EXTRA  FUNCTIONS =============================
;=========================================================================

get_pixel:
; description: return chosen pixels RGB
; arguments: on stack
; 			[ebp+8] -> x
; 			[ebp+12] -> y
;			[ebp+16] -> image_pos
; return:
; 		EAX -> Pixel colour 0x00BBGGRR
	push	ebp
	mov 	ebp, esp
	push	ebx
	push	ecx

	mov		ebx, [ebp + 16]		;pixel adress in image to EBX
	movzx	eax, BYTE [ebx]			;load B
	movzx	ecx, BYTE [ebx + 1]		;load G
	shl		ecx, 8
	or		eax, ecx			;accumulate
	movzx	ecx, BYTE [ebx + 2]		;load R
	shl		ecx, 16
	or		eax, ecx			;accumulate

	pop		ecx
	pop		ebx
	mov		esp, ebp
	pop		ebp
	ret


get_len:
; description: return potential length of arm, starting with given coordinates pixel
; arguments: on stack
; 			[ebp+28] -> [ebp-4] -> x
;			[ebp+20] -> [ebp-8] -> image_pos
;			[ebp+24] -> [ebp-12] -> used_pos
;			[ebp+64] -> width const.
;			[ebp+32] -> y
; return:
; 		EAX -> counted length
;		ECX -> 1 executed, 0 error

	push	ebp
	mov		ebp, esp
	mov		eax, [ebp + 28]
	push	eax 				;push posx
	mov		eax, [ebp + 20]
	push	eax					;push image_pos
	mov		eax, [ebp + 24]
	push	eax					;push used_pos
	push	ebx
	push	edx

	mov 	ecx, 0		;At first, ERROR FLAG is not set

check_l:
	mov		ebx, [ebp - 4]
	inc		ebx
	mov		[ebp - 4], ebx	;increment posx
	mov		ebx, [ebp - 8]
	add		ebx, 3
	mov		[ebp - 8], ebx	;increment pos in image
	mov		ebx, [ebp - 12]
	inc		ebx
	mov		[ebp - 12], ebx	;increment pos in used
	mov		ebx, [ebp - 4]
	cmp		ebx, [ebp + 64]
	je		end_len			;if the X is the border, end

	mov 	ebx, [ebp - 12]
	mov		edx, [ebx]		;used value
	add		ecx, edx		;in ERROR FLAG will be stored the sum of used pixels
	mov		[ebp - 12], DWORD 1	;set pixel as used

	push	eax
	mov		ebx, [ebp - 8]
	push	ebx				;push image pos on stack (get_pixel)
	mov		ebx, [ebp + 32]
	push	ebx				;push ypos on stack (get_pixel)
	mov		ebx, [ebp - 4]
	push 	ebx				;push xpos on stack (get_pixel)
	call	get_pixel
	cmp		eax, 0
	pop		eax				;pop xpos
	pop		eax				;pop ypos
	pop		eax				;pop image pos
	pop		eax				;return to original EAX
	je		check_l

	cmp		edx, 1			;if last pixel was used, it is irrelevant
	jne		end_len			;last pixel was not used
	dec		ecx


end_len:
	mov		eax, [ebp - 4]	;ending x
	mov		ebx, [ebp + 28]	;orginal x
	sub		eax, ebx
	dec		eax				;x = (ex - ox) - 1
	cmp		ecx, 0
	mov		ecx, 1
	je		exit_len		; if ecx was 0, move onward with 1
	dec		ecx				;if ecx was not 0, move onward with 0

exit_len:
	pop		edx
	pop		ebx
	mov		esp, ebp
	pop		ebp
	ret
