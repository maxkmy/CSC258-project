################ CSC258H1F Fall 2022 Assembly Final Project ##################
# This file contains our implementation of Breakout.
#
# Student 1: Max Ming Yi Koh, 1007972785
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    256
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
	.word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000
# Colors 
RED:   .word 0xff0000
GREEN: .word 0x00ff00 
BLUE:  .word 0x0000ff
GREY:  .word 0x808080 
BLACK: .word 0x000000

##############################################################################
# Mutable Data
##############################################################################

##############################################################################
# Code
##############################################################################
	.text
	.globl main

	# Run the Brick Breaker game.
main:
	# $t0 = RED 
	# $t1 = length 
	# $t2 = ADDR_DSPL
	la $t0, RED         # load address of RED into $t0 
	lw $t0, 0($t0)      # load RED into $t0
	addi $t1, $zero, 2 # load width = height = 10
	la $t2, ADDR_DSPL   # load address of ADDR_DSPL into $t2 
	lw $t2, 0($t2)      # load ADDR_DSPL into $t2 
	# load parameters and invoke DRAW_LINE
	addi $sp, $sp, -4   # increase stack size
	sw $t0, 0($sp)      # push `color` onto stack
	addi $sp, $sp, -4   # increase stack size
	sw $t1, 0($sp)      # push `width` onto stack
	addi $sp, $sp, -4   # increase stack size
	sw $t1, 0($sp)      # push `height` onto stack
	addi $sp, $sp, -4   # increase stack size
	sw $t2, 0($sp)      # push `ADDR_DSPL` onto stack
	jal DRAW_RECTANGLE  # invoke DRAW_LINE
	j EXIT              # Exit after drawing line
	
DRAW_LINE: 
	# usage: draw_line(address, length, color) 
	# $t0 = address
	# $t1 = length 
	# $t2 = color 
	# $t3 = loop index
	
	draw_line_load_params:
		lw $t0, 0($sp)      # load `address` 
		addi $sp, $sp, 4    # pop stack
		lw $t1, 0($sp)      # load `length` 
		addi $sp, $sp, 4    # pop stack
		lw $t2, 0($sp)      # load `color` 
		addi $sp, $sp, 4    # pop stack
	
		addi $t3, $zero, 0  # load loop index = 0
	
	draw_pixel_loop: 	
		beq $t3, $t1, draw_pixel_loop_end # if (length == index), stop drawing
		sw $t2, 0($t0)              	  # draw current pixel 
		addi $t0, $t0, 4            	  # increment address to next pixel 
		addi $t3, $t3, 1            	  # increment index 
		j draw_pixel_loop           	  # back to top of loop
	
	draw_pixel_loop_end:
		jr $ra                      # return to caller 

DRAW_RECTANGLE: 
	# usage: draw_rectangle(address, height, width, color) 
	# $t0 = address 
	# $t1 = height 
	# $t2 = width 
	# $t3 = color 
	# $t4 = loop index 
	
	draw_rectangle_load_params: 
		lw $t0, 0($sp)      # load `address` 
		addi $sp, $sp, 4    # decrement stack size
		lw $t1, 0($sp)      # load `height` 
		addi $sp, $sp, 4    # decrement stack size
		lw $t2, 0($sp)      # load `width` 
		addi $sp, $sp, 4    # decrement stack size
		lw $t3, 0($sp)      # load `address`
		addi $sp, $sp, 4    # decrement stack size
		
		addi $t4, $zero, 0  # load loop index = 0
		
	draw_line_loop: 
		beq $t4, $t1, draw_line_loop_end # if (height == index), terminate loop
		
		# Push registers onto stack.
		addi $sp, $sp, -4   # increase stack size 
		sw $ra, 0($sp)      # push `$ra` onto stack 
		addi $sp, $sp, -4   # increase stack size 
		sw $t0, 0($sp)      # push `address` onto stack
		addi $sp, $sp, -4   # increase stack size 
		sw $t1, 0($sp)      # push `height` onto stack
		addi $sp, $sp, -4   # increase stack size 
		sw $t2, 0($sp)      # push `width` onto stack
		addi $sp, $sp, -4   # increase stack size 
		sw $t3, 0($sp)      # push `color` onto stack
		addi $sp, $sp, -4   # increase stack size 
		sw $t4, 0($sp)      # push `loop index` onto stack
		
		# load parameters for subroutine draw_line(address, length, color) 
		addi $sp, $sp, -4   # increase stack size 
		sw $t3, 0($sp)      # push `color` for subroutine onto stack
		addi $sp, $sp, -4   # increase stack size 
		sw $t2, 0($sp)      # push `length` for subroutine onto stack (length = width of rectangle)
		addi $sp, $sp, -4   # increase stack size 
		sw $t0, 0($sp)      # push `address` for subroutine onto stack
		
		# invoke DRAW_LINE(address, length, color) 
		jal DRAW_LINE
		
		# Pop registers from stack.
		lw $t4, 0($sp)      # pop `loop index` from stack 
		addi $sp, $sp, 4    # decrement stack size 
		lw $t3, 0($sp)      # pop `color` from stack 
		addi $sp, $sp, 4    # decrement stack size 
		lw $t2, 0($sp)      # pop `width` from stack 
		addi $sp, $sp, 4    # decrement stack size 
		lw $t1, 0($sp)      # pop `height` from stack 
		addi $sp, $sp, 4    # decrement stack size 
		lw $t0, 0($sp)      # pop `address` from stack 
		addi $sp, $sp, 4    # decrement stack size 
		lw $ra, 0($sp)      # pop `$ra` from stack 
		addi $sp, $sp, 4    # decrement stack size 
		
		# Update address and loop index 
		addi $t0, $t0, 128  # move address to next row 
		addi $t4, $t4, 1    # Increment loop index 
		
		j draw_line_loop    # begin next loop iteration
		
	draw_line_loop_end: 
		jr $ra 				# return to caller 
		
		

game_loop:
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (paddle, ball)
	# 3. Draw the screen
	# 4. Sleep
    #5. Go back to 1
	b game_loop

EXIT: 
	li $v0, 10              # terminate the program gracefully
    syscall

	