#-------------------------------------------------------------
# author: Richard Staszkiewicz
# data: 21.04.2021
# description: Project MIPS. Find Marker 4 (mirrored L in 1:1 arm length) in BMP 320x240 px file
#-------------------------------------------------------------

# Procesor directives to make code more clear
# Only supported file formats are BMP 320x240 px
.eqv BMP_FILE_SIZE 230522
.eqv BYTES_PER_ROW 960
.eqv BYTES_PER_ROW_USED 320


	.data				# data section
.align 4
reserved:	.space 2				# reserved space (for safety)
image:	.space BMP_FILE_SIZE		# space to store the BMP file
used:	.space 76800			# space to store the map of checked pixels
fname:	.asciiz "test.bmp"			# name of the imported file
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
	subu 	$sp, $sp, 4			# push $ra to the stack
	sw 	$ra, 4($sp)
	subu 	$sp, $sp, 4			# push $s1
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
	addu 	$sp, $sp, 4
	lw 	$ra, 4($sp)		
	addu 	$sp, $sp, 4
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
	subu 	$sp, $sp, 4
	sw 	$s1, 4($sp)
	
	li	$t0, 0				# $t0 will store an iterator
	la	$t1, used				# $t1 will store current byte
	li	$t3, 0				# $t3 will store a constant 0

loop:	sb	$t3, ($t1)
	addiu	$t0, $t0, 1
	addiu	$t1, $t1, 1
	bne	$t0, 76800, loop
	
	lw 	$s1, 4($sp)
	addu 	$sp, $sp, 4
	lw 	$ra, 4($sp)		
	addu 	$sp, $sp, 4
	jr 	$ra


#===============find_marker=====================
find_marker:
# description: assumes (x, y) as left-down norner of the marker. Checks if it is correct, if so printing it's coordinates
# arguments:
#	$a0 - x coordinate
#	$a1 - y coordinate
# return value: none
	subu 	$sp, $sp, 4
	sw 	$ra, 4($sp)
	subu 	$sp, $sp, 4
	sw 	$s1, 4($sp)
	subu	$sp, $sp, 4
	sw	$a1, 4($sp)
	subu	$sp, $sp, 4
	sw	$a0, 4($sp)
	
	# pixel adress in used
	mul	$t0, $a1, BYTES_PER_ROW_USED
	addu	$t0, $a0, $t0
	la	$t1, used	
	addu	$t1, $t0, $t1			# $t1 stores current pixels address in used
	lb	$t0, ($t1)			# $t0 stores current pixels value in used
	beq	$t0, 1, end_pix			# if the pixel is already used, return
	move	$s0, $t1				# save pixel adress in used to $s0
	
	# pixel address in image calculation
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
	
	
	jal	get_pixel
	li	$t0, 16777215
	beq	$v0, $t0, end_pix			# if the pixel is white, continue
	move	$s2, $v0				# save pixel RGB in $s2
	
	move	$a2, $s1				# save pixel address in image in $a2
	move	$a3, $s2				# save pixel RGB in $a3
	
	jal	get_len
	beq	$v1, 1, end_pix
	move	$s3, $v0
#	
#	jal	get_hight
#	beq	$v1, 1, end_pix
#	move	$s2, $v0
	
#	jal	get_hight
#	beq	$v1, 1, end_pix
#	move	$s3, $v0
	


end_pix:	lw 	$a0, 4($sp)
	addu 	$sp, $sp, 4
	lw 	$a1, 4($sp)
	addu 	$sp, $sp, 4
	lw 	$s1, 4($sp)
	addu 	$sp, $sp, 4
	lw 	$ra, 4($sp)
	addu 	$sp, $sp, 4
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
	subu	$sp, $sp, 4
	sw	$s0, 4($sp)
	subu	$sp, $sp, 4
	sw	$s1, 4($sp)

#	la 	$t1, image + 10	# adress of file offset to pixel array
#	lw 	$t2, ($t1)	# file offset to pixel array in $t2
#	la 	$t1, image	# adress of bitmap
#	add	$t2, $t1, $t2	# adress of pixel array in $t2
	
	move	$t2, $a2		# pixel address in image
	
	#get color
	lbu 	$v0,($t2)			# load B
	lbu 	$t1,1($t2)		# load G
	sll 	$t1,$t1,8
	or 	$v0, $v0, $t1
	lbu 	$t1,2($t2)		# load R
          sll 	$t1,$t1,16
	or 	$v0, $v0, $t1
	
	lw	$s1, 4($sp)
	addu	$sp, $sp, 4
	lw	$s0, 4($sp)
	addu	$sp, $sp, 4	
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
#	$a3 - RGB signature to look for
# return value:
#	$v0 - counted length
#	$v1 - 0 if fulfiles conditions, 1 otherwise
	
	subu 	$sp, $sp, 4		# push $ra to the stack
	sw	$ra, 4($sp)
	subu 	$sp, $sp, 4		# push $s0 (used adress) to the stack
	sw 	$s0, 4($sp)
	subu 	$sp, $sp, 4		# push $s1 (image adress) to the stack
	sw 	$s1, 4($sp)
	subu 	$sp, $sp, 4		# push $s2 (RGB) to the stack
	sw 	$s2, 4($sp)
	subu	$sp, $sp, 4		# push $a0 (x coordinate) to the stack
	sw	$a0, 4($sp)
	subu	$sp, $sp, 4		# push $a2 (pixel adress in image) to the stack
	sw	$a0, 4($sp)
	
	li	$v1, 0			# at first, everything is OK
	move	$s0, $a3			# current RGB
	move	$s1, $a0			# real x coordinate
	
	
check:	addu	$a2, $a2, 3
	addiu	$a0, $a0, 1
	beq	$a0, BYTES_PER_ROW, end_len
	jal	get_pixel
	beq	$s0, $v0, check
	
	


end_len:	subu	$v0, $a0, $s1
	subiu	$v0, $v0, 1
	lw	$a2, 4($sp)
	addu	$sp, $sp, 4
	lw 	$a0, 4($sp)
	addu	$sp, $sp, 4
	lw 	$s2, 4($sp)
	addu	$sp, $sp, 4
	lw 	$s1, 4($sp)
	addu	$sp, $sp, 4
	lw 	$s0, 4($sp)
	addu	$sp, $sp, 4
	lw	$ra, 4($sp)
	addu	$sp, $sp, 4
	jr	$ra














