#-------------------------------------------------------------
# author: Richard Staszkiewicz
# data: 21.04.2021
# description: Project MIPS. Find Marker 4 (mirrored L in 1:1 arm length) in BMP 320x240 px file
#-------------------------------------------------------------

# Procesor directives to make code more clear
# Only supported file formats are BMP 320x240 px
.eqv BMP_FILE_SIZE 230522
.eqv BYTES_PER_ROW 960
.eqv BYTES_PER_COLUMN 240
.eqv BYTES_PER_ROW_USED 320


	.data				# data section
.align 4
reserved:	.space 2				# reserved space (for safety)
image:	.space BMP_FILE_SIZE		# space to store the BMP file
used:	.space 76800			# space to store the map of checked pixels
fname:	.asciiz "big_test.bmp"			# name of the imported file
err_msg:	.asciiz "Error occured during run"	# Message printed if error


	.text				# text section
main:	
	# preparation - fetching data, clearing space
	jal 	read_bmp			# load data from BMP file
	jal 	clear_used		# clear the map of used (1-> used; 0-> unused)

	# execute main program loop, starting with point (0, 0)
	li 	$a1, -1			# y coordinate (initialized with 1 less)
loop_y:	addiu	$a1, $a1, 1
 	beq	$a1, 240, exit
 	li 	$a0, -1			# x coordinate (initialized with 1 less)
loop_x:	addiu	$a0, $a0, 1
	jal 	find_marker		# Check if marker on pixel (x, y) = ($a0, $a1) under adress $a2.
	bne	$a0, 319, loop_x
	beq	$a0, 319, loop_y

	# terminate program
exit:	li	$v0, 10
	syscall

# ===========================read_bmp=================================


read_bmp:
#description: reads the contents of a bmp file into memory
#arguments: none
#return value: none
	subu 	$sp, $sp, 8			# push $ra to the stack
	sw 	$ra, 8($sp)
	sw 	$s1, 4($sp)
#open file
	li 	$v0, 13				# instruction: open file
        	la 	$a0, fname			# file name 
        	li 	$a1, 0				# flags: 0-read file
        	li 	$a2, 0				# mode: ignored
        	syscall
	move 	$s1, $v0      			# save the file descriptor
	
# check for errors - if file opened, print alert and close
	bgez 	$s1, fread
	jal 	error
	
#read file
fread:	li 	$v0, 14
	move 	$a0, $s1
	la 	$a1, image
	li 	$a2, BMP_FILE_SIZE
	syscall
	move 	$s1, $v0

# check for errors - if file reading unsuccessfull, print alert and close
	bgez 	$s1, fclose
	jal 	error

#close file
fclose:	li 	$v0, 16
	move 	$a0, $s1
        	syscall
	
	lw 	$s1, 4($sp)			#restore (pop) $s1
	lw 	$ra, 8($sp)		
	addu 	$sp, $sp, 8
	jr 	$ra


error:
#description: prints error and terminates program
#arguments: none
#return value: none
	li 	$v0, 4
	la 	$a0, err_msg
	syscall

	li 	$v0, 10
	syscall


#=========================clear_used=======================
clear_used:
#description: resets the space alocated to store used pixels information
#arguments: none
#return value: none
	subu 	$sp, $sp, 4
	sw 	$ra, 4($sp)
	
	li	$t0, 0				# $t0 will store an iterator
	la	$t1, used				# $t1 will store current byte
	li	$t3, 0				# $t3 will store a constant 0

loop:	sb	$t3, ($t1)
	addiu	$t0, $t0, 1
	addiu	$t1, $t1, 1
	bne	$t0, 76800, loop
	
	lw 	$ra, 4($sp)		
	addu 	$sp, $sp, 4
	jr 	$ra


#===============find_marker=====================
find_marker:
# description: assumes (x, y) as left-down norner of the marker. Checks if it is correct, if so printing it's coordinates
# arguments:
#	$a0 - x coordinate
#	$a1 - y coordinate
# saved registers:
#	$s0 - Used adress of current pixel
#	$s1 - image adress of current pixel
#	$s2 - Potential length of current marker (delta x)
#	$s3 - Potential width of current marker (delta y)
#	$s4 - Potential height of current marker (delta y)
#	$s5 - Print pixel flag - if set, print at the end the adjusted coordinates
# return value: none
	subu 	$sp, $sp, 12
	sw 	$ra, 12($sp)
	sw	$a1, 8($sp)
	sw	$a0, 4($sp)
	
	# pixel adress in used (stored to $s0)
	mul	$t0, $a1, BYTES_PER_ROW_USED
	addu	$t0, $a0, $t0
	la	$t1, used	
	addu	$t1, $t0, $t1			# $t1 stores current pixels address in used
	lbu	$t0, ($t1)			# $t0 stores current pixels value in used
	beq	$t0, 1, end_pix			# if the pixel is already used, return
	li	$t0, 1				# make $t0 store constant 1 to fill the used
	sb	$t0, ($t1)			# mark current pixel as used
	move	$s0, $t1				# save pixel adress in used to $s0
	

	# pixel address in image calculation (stored to $s1)
	la 	$t1, image + 10			# adress of file offset to pixel array
	lw 	$t2, ($t1)			# file offset to pixel array in $t2
	la 	$t1, image			# adress of bitmap
	add 	$t2, $t1, $t2			# adress of pixel array in $t2
	mul 	$t1, $a1, BYTES_PER_ROW
	move 	$t3, $a0	
	sll 	$a0, $a0, 1
	addu 	$t3, $t3, $a0
	addu	$t1, $t1, $t3
	addu 	$t2, $t2, $t1
	move	$s1, $t2				# save pixel adress in image to $s1
	move	$a2, $s1				# load pixels address in image to $a2
	lw 	$a0, 4($sp)			# return to original $a0 value (y coordinate)
	
	
	# markers RGB
	jal	get_pixel
	bne	$v0, 0, end_pix			# if the pixel is not black, continue
	move	$a2, $s1				# save pixel address in image in $a2
	
	li	$s5, 1				# set print pixel flag on 1 [true] (expected correct marker) (stored to $s5)
	
	move	$a3, $s0				# use as 4th argument the position in used
	
	# markers potential length (stored in $s2)
	jal	get_len
	# beq	$v1, 0, end_pix			# if errors occured, end
	# beq	$v0, 0, end_pix			# if it is a single of it's kind coloured pixel, end
	and	$s5, $v1, $s5			# if errors occured, set print flag to 0
	move	$s2, $v0				# save potential length in $s2 register
	
	
	# markers potential width (stored in $s3)
	jal	get_hgh				# get the potential width of the marker
	and	$s5, $v1, $s5				# if errors occured, set print flag to 0
	move	$s3, $v0				# save potential width in $s3
	
	
	# markers potential height (stored in $s4)
	addu	$a0, $s2, $a0			# translate x to x + len -> marker's corner pixel
	mulu	$t0, $s2, 3			# multiply len by number of bytes per pixel and save to $t0
	addu	$a2, $t0, $a2			# add to current pixels position in image $t0, to make it point towards corner pixel
	addu	$a3, $s2, $a3			# add to current pixels position in use len, to make it point towards corner pixel
	
	jal	get_hgh				# get the potential height of the marker
	and	$s5, $v1, $s5				# if errors occured, set print flag to 0
	move	$s4, $v0				# save the potential height of the marker to $s4
	
	
	# Test1: Check equal arm length
	seq	$t0, $s2, $s4
	and	$s5, $s5, $t0
	
	
	# preparation for Test2 & Test3 (a0, a2, a3 already points towards corner pixel)
	li	$t0, 0				# iterator checking width (not used in get_hgh)
	beq	$s3, $t0, test4			# if the width has no other rows than the descriptor, continue to next test
	
	# Test2: Check equal width  /  Test3: Check standing arm interior
ch_std:	subu	$a0, $a0, 1			# decrement x
	subu	$a2, $a2, 3			# point in image towards new pixel
	subu	$a3, $a3, 1			# point in used towards new pixel
	jal	get_hgh
	seq	$t1, $v0, $s4			# Flag on $t1 is set if the counted height is equal to anticipated one (do height)
	and	$s5, $s5, $t1			# if the flag is not set or already the conditions weren't fulfiled, the print flag is equal 0
	addu	$t0, $t0, 1			# increment the iterator
	bne	$t0, $s3, ch_std			# if the whole width is checked, end the loop


	# preparations for Test4 ($a0, $a2, $a3 already set to the last pixel in width range)
test4:	move	$t0, $s2				# move potential length to iterator
	subu	$t0, $t0, $s3			# substract width from length (is already checked by Test3)
	subiu	$t0, $t0, 1
	li	$t1, 0
	blt	$t0, $t1, test5			# if the remaining amount of pixels is less then 0, continue to another test
	beq	$t0, $t1, t4_end			# fi the remaining amount of pixels is equal 0, (descriptory axis) move to the end of this test
	
	# Test4: Check lying arm interior
ch_lyi:	subu	$a0, $a0, 1			# decrement x
	subu	$a2, $a2, 3			# point in image towards new pixel
	subu	$a3, $a3, 1			# point in used towards new pixel
	jal	get_hgh
	seq	$t1, $v0, $s3			# Flag on $t1 is set if the height is equal to anticipated one (so width)
	and	$s5, $s5, $t1			# if the flag is not set or already the conditions weren't fulfiled, the print flag is equal 0
	subu	$t0, $t0, 1			# decrement the iterator
	bne	$t0, 0, ch_lyi			# if the whole arm is checked, end the loop
	
	# Return to the original coordinates (move one pixel left)
t4_end:	subiu	$a0, $a0, 1				
	subiu	$a2, $a2, 3
	subiu	$a3, $a3, 1

	# push x and y to the stack
test5:	subu	$sp, $sp, 8		# push $a0 (x coordinate) to the stack
	sw	$a0, 8($sp)
	sw	$a1, 4($sp)
	
	# Test5,  Test6, Test7 -> check the vertical edges
	# Test 5 left edge
	beqz	$a0, test6			# if the marker is on the left edge, skip the test
	blez	$s3, test6			# if the marker has no width
	subiu	$a0, $a0, 1
	subiu	$a2, $a2, 3
	subiu	$a3, $a3, 1
	move	$s7, $s3
	jal	edge_v
	and	$s5, $s5, $v1
	addiu	$a0, $a0, 1
	addiu	$a2, $a2, 3
	addiu	$a3, $a3, 1


	# Test 6: right edge
test6:	addu	$a0, $s2, $a0
	addiu	$a0, $a0, 1
	mulu	$t0, $s2, 3			# multiply len by number of bytes per pixel and save to $t0
	addu	$a2, $t0, $a2			# add to current pixels position in image $t0, to make it point towards corner pixel
	addiu	$a2, $a2, 3
	addu	$a3, $s2, $a3			# add to current pixels position in use len, to make it point towards corner pixel
	addiu	$a3, $a3, 1
	beq	$a0, BYTES_PER_ROW_USED, test7	# if the marker is on the right edge, skip the test
	move	$s7, $s4				# we want only the pixels in our height
	#blez	$s7, test7			# if the marker has no height WHY SWITCHING IT CHOOSES BETWEEN (13, 81) & (8, 239)???????
	jal	edge_v
	and	$s5, $s5, $v1
	
	
	
	# Test7: internal edge (currently we are one pixel behind the corner one)
test7:	subu	$a0, $a0, $s3			# Transpose X
	subiu	$a0, $a0, 2
	subu	$a3, $a3, $s3
	subiu	$a3, $a3, 2
	mulu	$t0, $s3, 3
	subu	$a2, $a2, $t0
	subiu	$a2, $a2, 6
	
	addu	$a1, $a1, $s3
	addiu	$a1, $a1, 1
	mulu	$t0, $s3, BYTES_PER_ROW_USED
	addu	$a3, $a3, $t0
	addiu	$a3, $a3, BYTES_PER_ROW_USED
	mulu	$t0, $t0, 3
	addu	$a2, $a2, $t0
	addiu	$a2, $a2, BYTES_PER_ROW
	
	subu	$s7, $s4, $s3				# we want only the pixels in our height
	subiu	$s7, $s7, 1
	blez	$s7, rest
	jal	edge_v
	and	$s5, $s5, $v1
	
	
	# restore x and y
rest:	lw	$a1, 4($sp)
	lw 	$a0, 8($sp)
	addu	$sp, $sp, 8
	
	
	# Print if flag on $s6 is set (neq 0)
	beq	$s5, 0, end_pix			# if the shape is incorrect, end
	li 	$v0, 1				# syscall print int
	addu	$a0, $a0, $s2			# adjust x to point towards marker's corner pixel
	syscall					# print x
	li	$v0, 11				# syscall print char
	li	$a0, ','
	syscall					# print comma
	li	$v0, 11				# syscall print char
	li	$a0, ' '
	syscall					# print space
	move 	$a0, $a1
	li	$v0, 1				# syscall print int
	syscall					# print y
	li	$v0, 11				# syscall print char
	li	$a0, '\n'
	syscall					# print endline
	


end_pix:	lw 	$a0, 4($sp)
	lw 	$a1, 8($sp)
	lw 	$ra, 12($sp)
	addu 	$sp, $sp, 12
	jr 	$ra


















#=============================getters================================

get_pixel:
#description: 
#	returns color of specified pixel
#arguments:
#	$a0 - x coordinate
#	$a1 - y coordinate - (0,0) - bottom left corner
#	$a2 - pixels adress in image
#return value:
#	$v0 - 0RGB - pixel color

	subu 	$sp, $sp, 4	#push $ra to the stack
	sw 	$ra, 4($sp)
	
	move	$t2, $a2		# pixel address in image
	
	#get color
	lbu 	$v0, ($t2)			# load B
	lbu 	$t1, 1($t2)		# load G
	sll 	$t1, $t1, 8
	or 	$v0, $v0, $t1
	lbu 	$t1, 2($t2)		# load R
          sll 	$t1, $t1, 16
	or 	$v0, $v0, $t1
	
	lw 	$ra, 4($sp)		# restore (pop) $ra
	addu 	$sp, $sp, 4
	jr 	$ra


get_len:
# description: 
#	returns potential length of single-coloured arm, starting with given coordinates pixel
# arguments:
#	$a0 - x coordinate
#	$a1 - y coordinate
#	$a2 - Pixel address in image
#	$a3 - Address in used
# return value:
#	$v0 - counted length
#	$v1 - 1 executed, 0 error
	
	subu 	$sp, $sp, 32		# push $ra to the stack
	sw	$ra, 32($sp)
	sw 	$s0, 28($sp)
	sw 	$s1, 24($sp)
	sw 	$s2, 20($sp)
	sw	$s3, 16($sp)
	sw	$s4, 12($sp)
	sw	$a0, 8($sp)
	sw	$a2, 4($sp)
	
	li	$v1, 0			# at first, everything is OK
	move	$s2, $a3			# push to $s2 current address in used
	li 	$s0, 0x000000		# black RGB
	move	$s1, $a0			# real x coordinate
	li	$s4, 1			# constant 1, to be pushed into used
	
	
check_l:	addu	$a2, $a2, 3
	addiu	$a0, $a0, 1
	addiu	$s2, $s2, 1
	beq	$a0, BYTES_PER_ROW_USED, end_len
	lbu	$s3, ($s2)
	addu	$v1, $s3, $v1		# sum of used on the axis
	sb	$s4, ($s2)
	jal	get_pixel
	beq	$s0, $v0, check_l
	
	
	#li	$s4, 0			# last pixel is not in the marker, so unused. Correction
	#sb	$s4, ($s2)
	seq	$t0, $s3, 1		# if the last pixel was used, it's irrelevant
	subu	$v1, $v1, $t0		# v1 - number of used in relevant (acceptable only 0)

end_len:	subu	$v0, $a0, $s1
	subiu	$v0, $v0, 1
	seq	$v1, $v1, 0		# if no errors occured, set $v1 to 1 (else, it will be set to 0)
	lw	$a2, 4($sp)
	lw 	$a0, 8($sp)
	lw 	$s4, 12($sp)
	lw	$s3, 16($sp)
	lw 	$s2, 20($sp)
	lw 	$s1, 24($sp)
	lw 	$s0, 28($sp)
	lw	$ra, 32($sp)
	addu	$sp, $sp, 32
	jr	$ra






get_hgh:	
# description: 
#	returns potential length of single-coloured arm, starting with given coordinates pixel
# arguments:
#	$a0 - x coordinate
#	$a1 - y coordinate
#	$a2 - Pixel address in image
#	$a3 - Adress in used
# return value:
#	$v0 - counted height
#	$v1 - 1 executed, 0 error

	subu 	$sp, $sp, 28		# push $ra to the stack
	sw	$ra, 28($sp)
	sw 	$s0, 24($sp)
	sw 	$s1, 20($sp)
	sw 	$s2, 16($sp)
	sw	$s4, 12($sp)
	sw	$a1, 8($sp)
	sw	$a2, 4($sp)


	li	$v1, 0			# at first, everything is OK
	move	$s2, $a3			# push to $s2 current address in used
	li	$s0, 0x000000		# black RGB
	move	$s1, $a1			# real y coordinate
	li	$s4, 1			# constant 1, to be pushed into used
	
	
check_h:	addu	$a2, $a2, BYTES_PER_ROW
	addiu	$a1, $a1, 1
	addiu	$s2, $s2, BYTES_PER_ROW_USED
	beq	$a1, BYTES_PER_COLUMN, end_hgh
	lbu	$t6, ($s2)
	seq	$v1, $t6, 1
	sb	$s4, ($s2)
	jal	get_pixel
	beq	$s0, $v0, check_h
	#li	$s4, 0			# last pixel is not in the marker, so unused. Correction
	#sb	$s4, ($s2)




end_hgh:	subu	$v0, $a1, $s1		# delta is returned to $v0 register
	subiu	$v0, $v0, 1		# we've also counted base pixel. Correction
	seq	$v1, $v1, 0		# if no errors occured, set $v1 to 1
	lw	$a2, 4($sp)
	lw 	$a1, 8($sp)
	lw 	$s4, 12($sp)
	lw 	$s2, 16($sp)
	lw 	$s1, 20($sp)
	lw 	$s0, 24($sp)
	lw	$ra, 28($sp)
	addu	$sp, $sp, 28
	jr	$ra


edge_v:
# description: 
#	check if vertical edge is non-black *like get_hgh, but expects no black and has stop condition*
# arguments:
#	$a0 - x coordinate
#	$a1 - y coordinate
#	$a2 - Pixel address in image
#	$a3 - Adress in used
#	$s7 - Amount to check (unorthodox way of passing argument, but had no spare $a register)
# return value:
#	$v0 - counted height
#	$v1 - 1 executed, 0 error

	subu 	$sp, $sp, 32		# push $ra to the stack
	sw	$ra, 32($sp)
	sw 	$s0, 28($sp)
	sw 	$s1, 24($sp)
	sw 	$s2, 20($sp)
	sw	$s4, 16($sp)
	sw	$s7, 12($sp)
	sw	$a1, 8($sp)
	sw	$a2, 4($sp)


	li	$v1, 0			# at first, everything is OK
	move	$s2, $a3			# push to $s2 current address in used
	li	$s0, 0x000000		# black RGB
	move	$s1, $a1			# real y coordinate
	li	$s4, 1			# constant 1, to be pushed into used

	
	
check_e:	addu	$a2, $a2, BYTES_PER_ROW
	addiu	$a1, $a1, 1
	addiu	$s2, $s2, BYTES_PER_ROW_USED
	beq	$a1, BYTES_PER_COLUMN, end_e
	sb	$s4, ($s2)
	jal	get_pixel
	subiu	$s7, $s7, 1
	seq	$t0, $s0, $v0		# if there is a black pixel on the edge, set $v1 to TRUE
	or	$v1, $v1, $t0
	bne	$s7, 0, check_e
	#li	$s4, 0			# last pixel is not in the marker, so unused. Correction
	#sb	$s4, ($s2)




end_e:	subu	$v0, $a1, $s1		# delta is returned to $v0 register
	subiu	$v0, $v0, 1		# we've also counted base pixel. Correction
	seq	$v1, $v1, 0		# if no errors occured, set $v1 to 1
	lw	$a2, 4($sp)
	lw 	$a1, 8($sp)
	lw	$s7, 12($sp)
	lw 	$s4, 16($sp)
	lw 	$s2, 20($sp)
	lw 	$s1, 24($sp)
	lw 	$s0, 28($sp)
	lw	$ra, 32($sp)
	addu	$sp, $sp, 32
	jr	$ra
