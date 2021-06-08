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

	call	get_pixel
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
	call	get_len
	and		edx, ecx			;bitwise AND via print flag
	mov		[ebp - 20], eax		;move result to proper place on stack

	;markers potential width
	call	get_hgh
	and		edx, ecx			;bitwise and via print flag
	mov		[ebp - 24], eax		;move result to proper place on stack

before_shifts:
	;markers potential height
	mov		eax, [ebp - 8]		;current Xpos
	mov		ecx, [ebp - 20]		;markers len
	add		eax, ecx
	mov		[ebp - 8], eax		;actualise Xpos to corner of the marker

	mov		ecx, [ebp - 20]		;markers length
	lea		ecx, [ecx + 2*ecx]	;get amount of byte shift
	mov		eax, [ebp - 16]		;currnet image pos
	add		eax, ecx
	mov		[ebp - 16], eax		;actualise IMGpos to corner of the marker

	mov		ecx, [ebp - 20]
	mov		eax, [ebp - 12]
	add		eax, ecx
	mov		[ebp - 12], EAX		;actualise USEDpos to corner of the marker

	call	get_hgh
	and		edx, ecx
	mov		[ebp - 28], eax


	;TEST 1: Check equal arm length
	mov		eax, [ebp - 20]		;marker len
	mov		ecx, [ebp - 28]		;marker hgh
	cmp 	eax, ecx
	mov		eax, DWORD 1		;generally - pass
	je		t1_pass
	mov		eax, DWORD 0		;fail

t1_pass:
	and 	edx, eax			;bitwise AND

	;TEST 2/3 prep
	mov		eax, [ebp - 24]		;width
	cmp		eax, 0
	je		test4				;if has no oother descriptor, continue to TEST4

	;TEST 2 (check equal width), TEST 3 (check standing arm interior) main
ch_std:
	mov		eax, [ebp - 8]		;current x
	dec 	eax
	mov		[ebp - 8], eax		;decrement x

	mov		eax, [ebp - 12]		;current pos in USED
	dec		eax
	mov		[ebp - 12], eax		;decrement pos in USED

	mov		eax, [ebp - 16]		;current pos in IMG
	sub		eax, 3
	mov		[ebp - 16], eax		;decrement pos in IMG

	call	get_hgh

	mov		ecx, [ebp - 28]		;anticipated hgh
	cmp		ecx, eax			;check if the same heights
	je		estd
	mov		edx, DWORD 0		;if not equal, set print flag to 0
estd:
	mov		eax, [ebp - 8]
	dec 	eax
	mov		[ebp - 8], eax		;decrement current X

	mov		eax, [ebp + 16]		;original X
	mov		ecx, [ebp - 20]		;marker len
	add		eax, ecx			;marker corners X
	mov		ecx, [ebp - 8]		;current X
	sub		eax, ecx			;delta X from ending
	mov		ecx, [ebp - 24]		;marker width
	cmp		eax, ecx
	jne		ch_std				;if the whole width is checked, end the loop


	;TEST 4 preparation (already position set to last pixel in width)
test4:
	mov		eax, [ebp - 20]		;potential length
	mov		ecx, [ebp - 24]		;potential width
	sub		eax, ecx			;already checked amount by TEST3
	dec		eax					;without descriptor
	cmp		eax, 0
	jl		test5
	je		t4_end

	;TEST 4 - checking lying arm interrior
ch_lyi:
	mov		eax, [ebp - 8]		;current x
	dec 	eax
	mov		[ebp - 8], eax		;decrement x

	mov		eax, [ebp - 12]		;current pos in USED
	dec		eax
	mov		[ebp - 12], eax		;decrement pos in USED

	mov		eax, [ebp - 16]		;current pos in IMG
	sub		eax, 3
	mov		[ebp - 16], eax		;decrement pos in IMG

	call	get_hgh				;ret in ECX will not be used

	mov		ecx, [ebp - 24]		;anticipated height (width)
	cmp		ecx, eax
	je		elyi				;if equal, go on
	mov		edx, DWORD 0		;else unset print flag
elyi:
	mov		eax, [ebp - 8]		;current X
	mov		ecx, [ebp + 16]		;orginal X
	cmp		eax, ecx
	je		test5				;checked everything, including start pixel
	jmp		ch_lyi				;check next pixel on the left


t4_end:
	mov		eax, [ebp - 8]		;current x
	dec 	eax
	mov		[ebp - 8], eax		;decrement x

	mov		eax, [ebp - 12]		;current pos in USED
	dec		eax
	mov		[ebp - 12], eax		;decrement pos in USED

	mov		eax, [ebp - 16]		;current pos in IMG
	sub		eax, 3
	mov		[ebp - 16], eax		;decrement pos in IMG


test5:
	;TEST5, TEST6, TEST7 - test vertical edges

	;TEST5: left edge
	mov		eax, [ebp - 8]		;current x
	cmp		eax, 0
	je		test6				;if the marker is touching the left edge, continue to next test

	mov		eax, [ebp - 24]		;marker width
	cmp		eax, 0
	je		test6				;if the marker has no width, continue to next test

	;decrementing to (x - 1, y) position
	mov		eax, [ebp - 8]		;current x
	dec 	eax
	mov		[ebp - 8], eax		;decrement x

	mov		eax, [ebp - 12]		;current pos in USED
	dec		eax
	mov		[ebp - 12], eax		;decrement pos in USED

	mov		eax, [ebp - 16]		;current pos in IMG
	sub		eax, 3
	mov		[ebp - 16], eax		;decrement pos in IMG

	mov		eax, [ebp - 24]		;amount to check is equal to anticipated marker width
	call	edge_v
	and		edx, ecx			;bitwise AND via print falg & correctness raport

	;incrementing to (x, y) position
	mov		eax, [ebp - 8]		;current x
	inc 	eax
	mov		[ebp - 8], eax		;decrement x

	mov		eax, [ebp - 12]		;current pos in USED
	inc		eax
	mov		[ebp - 12], eax		;decrement pos in USED

	mov		eax, [ebp - 16]		;current pos in IMG
	add		eax, 3
	mov		[ebp - 16], eax		;decrement pos in IMG


test6:
	;TEST 6: right edge
	mov		eax, [ebp - 8]		;current x
	mov		ecx, [ebp - 20]		;marker len
	add 	eax, ecx
	inc		eax					;make it point toward one more right
	mov		[ebp - 8], eax		;increment x by len + 1

	mov		eax, [ebp - 12]		;current pos in USED
	mov		ecx, [ebp - 20]		;marker len
	add		eax, ecx
	inc		eax
	mov		[ebp - 12], eax		;increment pos in USED by len + 1

	mov		eax, [ebp - 16]		;current pos in IMG
	mov		ecx, [ebp - 20]		;marker len
	lea		ecx, [ecx + 2*ecx]	;each pixel has 3 bytes
	add		eax, ecx
	add		eax, 3
	mov		[ebp - 16], eax		;increment pos in IMG by 3*(len + 1)

	mov		eax, [ebp + 28]		;width
	cmp		[ebp - 8], eax
	je		test7				;if the marker is on the right edge, skip the test

	mov		eax, [ebp - 28]		;potential height to EAX argument
	call	edge_v
	and		edx, ecx			;bitwise AND between PRINT & CORRECTNESS flags


test7:
	;TEST 7: internal edge (currently we are at the pixel behind corner one)
	mov		eax, [ebp - 8]		;currnet X
	mov		ecx, [ebp - 24]		;markers width
	sub		eax, ecx
	sub		eax, 2
	mov		[ebp - 8], eax		;transposed X

	mov		eax, [ebp - 12]		;current USED (ECX is still markers width)
	sub		eax, ecx
	sub		eax, 2
	mov		[ebp - 12], eax		;transposed USED (X)

	mov		eax, [ebp - 16]		;current IMG (ECX is still markers width)
	lea		ecx, [ecx + 2*ecx]
	sub		eax, ecx
	sub		eax, 6
	mov		[ebp - 16], eax		;transposed IMG (X)


	mov		ecx, [ebp - 24]		;markers width
	mov		eax, [ebp - 4]		;current Y
	add		eax, ecx
	inc 	eax
	mov		[ebp - 4], eax		;transposed Y

	mov		eax, [ebp + 28]		;width of bitmap
	imul	eax, ecx			;store to EAX amount to move by (ECX is markers width)
	mov		ecx, [ebp - 12]		;current USED
	add		ecx, eax			;add counted delta
	mov		[ebp - 12], ecx		;transposed USED; TBD -width

	mov		ecx, [ebp - 16]		;current IMG
	lea		eax, [eax + eax*2]	;delta*3
	add		ecx, eax
	mov		[ebp - 16], ecx		;transposed IMG; TBD -3width

	mov		eax, [ebp + 28]		;width of bitmap
	mov		ecx, [ebp - 12]		;current USED
	add		ecx, eax
	mov		[ebp - 12], ecx		;finally transposed USED (Y)

	mov		ecx, [ebp - 16]		;current IMG
	lea		eax, [eax + 2*eax]	;3*width
	add		ecx, eax
	mov		[ebp - 16], ecx		;finally transposed IMG (Y)

	mov		eax, [ebp - 28]		;markers height
	mov		ecx, [ebp - 24]		;markers width
	sub		eax, ecx
	sub		eax, 1				;amount of pixels to check
	cmp		eax, 0
	jbe		exit_fm				;if amount of pixels to check is negativw, continue

	jmp		edge_v
	and		edx, ecx			;bitwise AND between PRINT & CORRECTNESS flags


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

	mov		ebx, [ebp + 16]			;pixel adress in image to EBX
	movzx	eax, BYTE [ebx]			;load B
	movzx	ecx, BYTE [ebx + 1]		;load G
	shl		ecx, 8
	or		eax, ecx				;accumulate
	movzx	ecx, BYTE [ebx + 2]		;load R
	shl		ecx, 16
	or		eax, ecx				;accumulate

	pop		ecx
	pop		ebx
	mov		esp, ebp
	pop		ebp
	ret

;=========================================================================================

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
	mov		[ebx], DWORD 1	;set pixel as used

	push	eax
	mov		ebx, [ebp - 8]
	push	ebx				;push image pos on stack (get_pixel)
	mov		ebx, [ebp + 32]
	push	ebx				;push ypos on stack (get_pixel)
	mov		ebx, [ebp - 4]
	push 	ebx				;push xpos on stack (get_pixel)
	call	get_pixel 		;if is equal 0
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


;==================================================================================

get_hgh:
; description: return potential height of arm, starting with given coordinates pixel
; arguments: on stack
; 			[ebp+32] -> [ebp-4] -> y
;			[ebp+20] -> [ebp-8] -> image_pos
;			[ebp+24] -> [ebp-12] -> used_pos
;			[ebp+64] -> width const.
;			[ebp+60] -> height const.
;			[ebp+28] -> x
; return:
; 		EAX -> counted height
;		ECX -> 1 executed, 0 error

	push	ebp
	mov		ebp, esp

	mov		ecx, 0				;Set ERROR FLAG to 0
	mov		eax, [ebp + 32]
	push	eax					;push y on stack
	mov		eax, [ebp + 20]
	push	eax					;push image_pos on stack
	mov		eax, [ebp + 24]
	push 	eax					;push used_pos on stack
	push	edx
	push	ebx

check_h:
	mov		ebx, [ebp + 64]		;width
	lea		ebx, [ebx + 2*ebx]	;width x 3 bytes per pixel
	mov		eax, [ebp - 8]
	add		eax, ebx
	mov		[ebp - 8], eax		;increment image_pos

	mov		ebx, [ebp + 64]		;width
	mov		eax, [ebp - 12]		;position in used
	add		eax, ebx
	mov		[ebp - 12], eax		;increment position in used

	mov		eax, [ebp - 4]
	inc 	eax
	mov		[ebp - 4], eax		;increment y

	cmp		eax, [ebp + 60]		;check if pixel on border
	je		end_hgh				;end if so



	mov		eax, [ebp - 12]
	mov		edx, [eax]			;value of pixel in USED
	add		ecx, edx			;error flag will store accumulated sum of used pixels
	mov		[eax], DWORD 1		;set pixel as used

	mov		ebx, [ebp - 8]
	push 	ebx					;image_pos (get_pixel)
	mov		ebx, [ebp - 4]
	push	ebx					;y (get_pixel)
	mov		ebx, [ebp + 28]
	push	ebx					;x (get_pixel)
	call	get_pixel
	cmp		eax, 0
	pop		eax
	pop		eax
	pop		eax
	je		check_h

	cmp		edx, 1				;if last pixel was used, it's irrelevant
	jne		end_hgh
	dec 	ecx

end_hgh:
	mov		eax, [ebp - 4]		;y current
	mov		ebx, [ebp + 32]		;y original
	sub		eax, ebx			;y current - y orginal = delta y
	dec		eax					;correction (counted base pixel)

	cmp		ecx, 0
	mov		ecx, 0
	jne		exit_hgh			;if errors not 0, continue with 0
	inc		ecx					;if 0 errors, increment to 1

exit_hgh:
	pop		ebx
	pop		edx
	mov		esp, ebp
	pop		ebp
	ret


;===============================================================================

edge_v:
; description: check if vertical edge is non-black *like get_hgh, but expects no black and has stop condition*
; arguments: on stack
; 			[ebp+32] -> [ebp-4] -> y
;			[ebp+20] -> [ebp-8] -> image_pos
;			[ebp+24] -> [ebp-12] -> used_pos
;			[ebp+64] -> width const.
;			[ebp+60] -> height const.
;			[ebp+28] -> x
;			in registers:
;			EAX -> [ebp-16] -> Amount to check
; return:
; 		EAX -> counted height
;		ECX -> 1 executed, 0 error


	push	ebp
	mov		ebp, esp


	mov		ecx, eax			;set error flag to amount to check
	mov		eax, [ebp + 32]
	push	eax					;push y on stack
	mov		eax, [ebp + 20]
	push	eax					;push image_pos on stack
	mov		eax, [ebp + 24]
	push 	eax					;push used_pos on stack
	push	ecx					;push amount on stack
	mov		ecx, 0				;set Error flag to 0

	push	ebx
	push	edx

check_e:
	mov		ebx, [ebp + 64]		;width
	lea		ebx, [ebx + 2*ebx]	;width*3 bytes per pixel (may be lea)
	mov		eax, [ebp - 8]
	add		eax, ebx
	mov		[ebp - 8], eax		;increment image_pos

	mov		ebx, [ebp + 64]		;width
	mov		eax, [ebp - 12]		;position in used
	add		eax, ebx
	mov		[ebp - 12], eax		;increment position in used

	mov		eax, [ebp - 4]
	inc 	eax
	mov		[ebp - 4], eax		;increment y

	cmp		eax, [ebp + 60]		;check if pixel on border
	je		end_exit			;end if so

	mov		eax, [ebp - 12]		;position in used
	mov		[eax], DWORD 1		;set pixel as used

	mov		ebx, [ebp - 8]
	push 	ebx					;image_pos (get_pixel)
	mov		ebx, [ebp - 4]
	push	ebx					;y (get_pixel)
	mov		ebx, [ebp + 28]
	push	ebx					;x (get_pixel)
	call	get_pixel
	mov		ebx, [ebp - 16]
	dec		ebx
	mov		[ebp - 16], ebx		;amount to check left

	cmp		eax, 0
	pop		eax
	pop		eax
	pop		eax
	je		ec
	mov		ecx, 1

ec:
	cmp		ebx, 0				;amount to check left in EBX from above
	jne		check_e


end_exit:
	mov		eax, [ebp - 4]		;y current
	mov		ebx, [ebp + 32]		;y original
	sub		eax, ebx			;y current - y orginal = delta y
	dec		eax					;correction (counted base pixel)

	cmp		ecx, 0
	mov		ecx, 0
	jne		exit_hgh			;if errors not 0, continue with 0
	inc		ecx					;if 0 errors, increment to 1

exit_edge:
	pop		edx
	pop		ebx
	mov		esp, ebp
	pop		ebp
	ret
