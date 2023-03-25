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
GREY:  .word 0xebecf0
BLACK: .word 0x000000

##############################################################################
# Mutable Data
##############################################################################
# Block related memory
# Colors of blocks (array of size 48) 
COLORS:
    .word 0xff0000, 0xff0000, 0xff0000, 0xff0000, 0xff0000, 0xff0000, 0xff0000, 0xff0000
    .word 0x00ff00, 0x00ff00, 0x00ff00, 0x00ff00, 0x00ff00, 0x00ff00, 0x00ff00, 0x00ff00
    .word 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff
BLOCKS: .word 24 						# number of blocks left
BLOCK_ADDRESS_OFFSET: .word 384

# Player related memory 
LIVES: .word 3 							# number of lives left

# Ball related memory 
BALL_ADDRESS_OFFSET: .word 3388			# offset of ball
DR: .word -1								# y direction of ball
DC: .word -1     							# x direction of ball

# Paddle related memory 
PADDLE_ADDRESS_OFFSET: .word 3632       # offset of leftmost pixel of paddle 
PADDLE_LEFT_LIM_OFFSET: .word 3584      # minimum offset for leftmost pixel of paddle
PADDLE_RIGHT_LIM_OFFSET: .word 3708     # maximum offset for rightmost pixel of paddle

##############################################################################
# Code
##############################################################################
	.text
	.globl main

	# Run the Brick Breaker game.
main:
	jal DRAW_SCENE
	jal GAME_LOOP
	j EXIT              
	
DRAW_SCENE: 
	# usage: draw_scene()
	# colors, paddle_address_offset, ball_address_offset, block_address_offset are fetched from memory
	
	draw_blocks:
		# $t0 = block address 
		# $t1 = colors address 
		# $t2 = index of draw block loop 
		# $t3 = end index of loop (24 blocks)
		# $t4 = color of current block
		# $t9 = width of a block = 4 
		# $t8 = height of a block = 1
		
		addi $t9, $zero, 4                 # $t9 = width of block = 4
		addi $t8, $zero, 1                 # $t8 = height of block = 1
	
		# get data from memory 
		lw $t0, BLOCK_ADDRESS_OFFSET       # $t0 = BLOCK_ADDRESS_OFFSET
		lw $t1, ADDR_DSPL                  # $t1 = ADDR_DSPL
		add $t0, $t0, $t1                  # $t0 = address of first block (address = ADDR_DSPL + offset)
		la $t1, COLORS                     # $t1 = address of COLORS
	
		# set up loop variables 	
		addi $t2, $zero, 0                 # $t2 = loop index = 0 
		addi $t3, $zero, 24                # $t3 = loop end index = 24 
	
		draw_block_loop: 
			beq $t2, $t3, draw_ball        # if (loop index == 24), stop drawing blocks. Draw ball.
			lw $t4, 0($t1)                 # $t4 = COLORS[i] 
			
			# Push registers onto stack (we don't push $t4 = color since we can access that through $t1)
			addi $sp, $sp, -4   		   # increase stack size
			sw $ra, 0($sp)     			   # push `$ra` onto stack
			addi $sp, $sp, -4   		   # increase stack size
			sw $t0, 0($sp)     			   # push `block address` onto stack
			addi $sp, $sp, -4  			   # increase stack size
			sw $t1, 0($sp)                 # push `color address` onto stack
			addi $sp, $sp, -4  			   # increase stack size
			sw $t2, 0($sp)     			   # push `index` onto stack
			addi $sp, $sp, -4  			   # increase stack size
			sw $t3, 0($sp)     			   # push `end index` onto stack
			
			# Set up parameters for draw rectangle(address, height, width, color) 
			addi $sp, $sp, -4  			   # increase stack size
			sw $t4, 0($sp)     			   # push `color` onto stack
			addi $sp, $sp, -4  			   # increase stack size
			sw $t9, 0($sp)     			   # push `width` onto stack
			addi $sp, $sp, -4  			   # increase stack size
			sw $t8, 0($sp)     			   # push `height` onto stack
			addi $sp, $sp, -4   		   # increase stack size
			sw $t0, 0($sp)     			   # push `block address` onto stack
			
			jal DRAW_RECTANGLE    		   # invoke rectangle(address, height, width, color) 
			
			# Pop registers from the stack 
			lw $t3, 0($sp)     			   # pop `end index` from stack
			addi $sp, $sp, 4   			   # decrement stack size 
			lw $t2, 0($sp)     			   # pop `index` from stack
			addi $sp, $sp, 4   			   # decrement stack size 
			lw $t1, 0($sp)     			   # pop `color address` from stack
			addi $sp, $sp, 4   			   # decrement stack size 
			lw $t0, 0($sp)     			   # pop `block address` from stack
			addi $sp, $sp, 4   			   # decrement stack size 
			lw $ra, 0($sp)     			   # pop `$ra` from stack
			addi $sp, $sp, 4   			   # decrement stack size 
			
			# Update variables (each block is 4 pixels wide)
			addi $t0, $t0, 16              # Increment to address of next block (4 * 4 = 16) 
			addi $t1, $t1, 4               # Increment to address of next color 
			addi $t2, $t2, 1               # Increment loop index ($t2)
			
			j draw_block_loop              # jump to next iteration to loop
	draw_ball: 
		# $t0 = ball address offset AND ball address
		# $t1 = base address of bitmap AND color grey 
		lw $t0, BALL_ADDRESS_OFFSET        # $t0 = BALL_ADDRESS_OFFSET
		lw $t1, ADDR_DSPL                  # $t1 = ADDR_DSPL
		add $t0, $t0, $t1                  # $t0 = address of ball (offset + base address) 
		lw $t1, GREY                       # $t1 = GREY 
		sw $t1, 0($t0)                     # draw ball (easier to just draw pixel)
	 
	 draw_paddle: 
		# $t0 = paddle address offset AND paddle address 
		# $t1 = base address of bitmap AND color grey 
		# $t9 = width of paddle = 8 
		# $t8 = height of paddle = 1 
		lw $t0, PADDLE_ADDRESS_OFFSET      # $t0 = PADDLE_ADDRESS_OFFSET
		lw $t1, ADDR_DSPL                  # $t1 = ADDR_DSPL
		add $t0, $t0, $t1                  # $t0 = address of paddle (offset + base address) 
		lw $t1, GREY                       # $t1 = GREY 
		addi $t9, $zero, 8                 # $t9 = width of paddle = 8 
		addi $t8, $zero, 1                 # $t8 = height of paddle = 1 
		
		# just save $ra (no more need for other registers)
		addi $sp, $sp, -4   		   # increase stack size
		sw $ra, 0($sp)     			   # push `$ra` onto stack
		
		# Set up parameters for rectangle(address, height, width, color) 
		addi $sp, $sp, -4  # increase stack size
		sw $t1, 0($sp)     # push `color` onto stack
		addi $sp, $sp, -4  # increase stack size
		sw $t9, 0($sp)     # push `width` onto stack
		addi $sp, $sp, -4  # increase stack size
		sw $t8, 0($sp)     # push `height` onto stack
		addi $sp, $sp, -4  # increase stack size
		sw $t0, 0($sp)     # push `address` onto stack
		
	 	jal DRAW_RECTANGLE # invole rectangle(address, height, width, color) 
		
		# pop $ra 
		lw $ra, 0($sp)     			   # pop `$ra` from stack
		addi $sp, $sp, 4   			   # decrement stack size
		
	jr $ra 
	
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
		lw $t3, 0($sp)      # load `color`
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
		
MOVE_PADDLE_LEFT:
	# usage move_paddle_left()
	# $t0 = address of leftmost pixel 
	# $t1 = base address of bitmap 
	# $t2 = PADDLE_LEFT_LIM_OFFSET (in memory) AND PADDLE_LEFT_LIM (not in memory)
	# $t3 = pixel to left of paddle AND color of pixel to directly to left of paddle
	# $t4 = color BLACK
	# $t5 = address of rightmost pixel 
	# $t6 = color grey 
	# $t7 = address of PADDLE_ADDRESS_OFFSET
	
	# fetch data from memory 
	lw $t0, PADDLE_ADDRESS_OFFSET   # $t0 = PADDLE_ADDRESS_OFFSET
	lw $t1, ADDR_DSPL               # $t1 = address of ADDR_DSPL

	# find leftmost limit of paddle
	lw $t2, PADDLE_LEFT_LIM_OFFSET  # $t2 = PADDLE_LEFT_LIM_OFFSET
	add $t2, $t2, $t1               # $t2 = ADDR_DSPL + PADDLE_LEFT_LIM_OFFSET = PADDLE_LEFT_LIM
	
	# process leftmost pixel of paddle
	add $t0, $t0, $t1               # $t0 = address of leftmost pixel = ADDR_DSPL + PADDLE_ADDRESS_OFFSET
	beq $t0, $t2, NO_MOVE_LEFT      # if leftmost pixel of paddle is on leftmost edge, don't move
	
	# process pixel to left of paddle 
	add $t3, $t0, -4                # $t3 = 1 pixel to left of paddle
	lw $t3, 0($t3)                  # $t3 = color of the pixel to left of paddle
	addi $t4, $zero, 0x000000       # $t4 = BLACK 
	bne $t3, $t4, NO_MOVE_LEFT      # if pixel to left of paddle is not black, don't move
	
	# move the paddle to left 
	addi $t5, $t0, 28               # $t5 = leftmost pixel + 28 = rightmost pixel of paddle 
	sw $t4, 0($t5)                  # color rightmost pixel black
	lw $t6, GREY                    # $t6 = GREY
	addi $t0, $t0, -4               # $t0 = leftmost pixel - 4 = pixel to left of paddle
	sw $t6, 0($t0)                  # color pixel to left of paddle GREY ($t0 is new PADDLE_ADDRESS_OFFSET)
	
	# update PADDLE_ADDRESS_OFFSET
	la $t7, PADDLE_ADDRESS_OFFSET   # $t7 = address of PADDLE_ADDRESS_OFFSET
	sub $t0, $t0, $t1               # $t0 = $t0 - $t1 = new leftmost pixel - base address
	sw $t0, 0($t7)                  # Store new paddle offset into PADDLE_ADDRESS_OFFSET
	
	NO_MOVE_LEFT: 					# if the paddle shouldn't be moved
		jr $ra                      # return 
		
MOVE_PADDLE_RIGHT:
	# usage move_paddle_right()
	# $t0 = PADDLE_ADDRESS_OFFSET AND PADDLE_ADDRESS
	# $t1 = ADDR_DSPL 
	# $t2 = PADDLE_RIGHT_LIM_OFFSET (in memory) AND PADDLE_RIGHT_LIM (not in memory)
	# $t3 = address of rightmost pixel of paddle
	# $t4 = 1 pixel to right of paddle AND color of pixel to right of paddle
	# $t5 = BLACK
	# $t6 = GREY
	# $t7 = address of PADDLE_ADDRESS_OFFSET
	
	# fetch data from memory 
	lw $t0, PADDLE_ADDRESS_OFFSET   # $t0 = PADDLE_ADDRESS_OFFSET
	lw $t1, ADDR_DSPL               # $t1 = address of ADDR_DSPL
	add $t0, $t0, $t1               # $t0 = PADDLE_ADDRESS = ADDR_DSPL + PADDLE_ADDRESS_OFFSET
	
	# find rightmost limit of paddle
	lw $t2, PADDLE_RIGHT_LIM_OFFSET # $t2 = PADDLE_RIGHT_LIM_OFFSET
	add $t2, $t2, $t1               # $t2 = ADDR_DSPL + PADDLE_RIGHT_LIM_OFFSET = PADDLE_RIGHT_LIM
	
	# process rightmost pixel of paddle
	addi $t3, $t0, 28               # $t3 = leftmost pixel + 28 = rightmost pixel of paddle
	beq $t3, $t2, NO_MOVE_RIGHT     # if rightmost pixel of paddle is on rightmost edge, don't move
	
	# process pixel to right of paddle 
	addi $t4, $t3, 4                # $t4 = 1 pixel to right of paddle
	lw $t4, 0($t4)                  # $t4 = color of the pixel to right of paddle
	addi $t5, $zero, 0x000000       # $t5 = BLACK
	bne $t4, $t5, NO_MOVE_RIGHT     # if pixel to right of paddle is not black, don't move
	
	# move paddle to right 
	lw $t6, GREY 					# $t6 = GREY
	addi $t4, $t3, 4                # $t4 = 1 pixel to right of paddle
	sw $t6, 0($t4)					# color pixel to right of paddle GREY
	sw $t5, 0($t0)					# color leftmost pixel of paddle BLACK
	
	# update PADDLE_ADDRESS_OFFSET 
	la $t7, PADDLE_ADDRESS_OFFSET   # $t7 = address of PADDLE_ADDRESS_OFFSET
	addi $t0, $t0, 4                # $t0 = pixel to right of $t0 (original leftmost pixel of paddle)
	sub $t0, $t0, $t1               # $t0 = $t0 - $t1 = new leftmost pixel - base address 
	sw $t0, 0($t7)					# store new paddle offset into PADDLE_ADDRESS_OFFSET d
	
	NO_MOVE_RIGHT: 					# if the paddle shouldn't be moved 
		jr $ra 						# return 
		
MOVE_BALL: 
	# move_ball() 
	# $t0 = dr 
	# $t1 = dc 
	# $t2 = BALL_ADDRESS_OFFSET and BALL_ADDRESS
	# $t3 = ADDR_DSPL
	# $t4 = r-coordinate 
	# $t5 = c-coordinate 
	# $t6, $t7, $t8, $t9 are constantly changing (with $t9 changing whenever possible)
	lw $t0, DR 						# $t0 = DR
	lw $t1, DC 						# $t1 = DC 
	lw $t2, BALL_ADDRESS_OFFSET 	# $t2 = BALL_ADDRESS_OFFSET
	lw $t3, ADDR_DSPL				# $t3 = ADDR_DSPL
	
	addi $t9, $zero, 128			# $t9 = 128 
	div $t2, $t9					# BALL_ADDRESS_OFFSET / 128 
	mflo $t4						# $t4 = BALL_ADDRESS_OFFSET // 128 = r
	mfhi $t5						# $t5 = 4c (remainder bytes from division) 
	srl $t5, $t5, 2					# $t5 = $5 >> 2 = (4c)/4 = c
	
	add $t2, $t2, $t3				# $t2 = old ball address 
	
	# TODO: only check when no side and up vert pixel AND not at edge
	diagonal_collision:
	
	side_collision:
		left_edge:
			beq $t5, $zero, negate_dc		# if $t5 = c = 0, collision with left edge. Negate dc.
		right_edge:
			addi $t9, $zero, 31				# $t9 = 31 
			beq $t5, $t9, negate_dc 		# if $t5 = c = 31, collision with right edge. Negate dc.
		left_pixel:
			addi $t9, $t2, -4				# $t9 = address of pixel to left of ball 
			lw $t9, 0($t9)					# $t9 = color of address of pixel to left of ball 
			beq $t9, $zero, right_pixel 	# $zero = BLACK. If left pixel is black, no collision. Check right pixel.
			lw $t8, GREY					# $t8 = GREY 
			beq $t9, $t8, negate_dc			# if pixel to left of ball is GREY, this is collision with paddle. Don't need to remove block
			srl $t9, $t9, 8					# color of block = color of block >> 8 (0xFF0000 -> 0x00FF00 -> 0x0000FF)
			# re-paint block
			addi $t8, $t2, -4				# $t8 = address of 1 pixel to left of ball 
			sw $t9, 0($t8)					# color 1 pixel to left of ball with new color 
			sw $t9, -4($t8)					# color 2 pixel to left of ball with new color 
			sw $t9, -8($t8)					# color 3 pixel to left of ball with new color 
			sw $t9, -12($t8)					# color 4 pixel to left of ball with new color 
			# decrease blocks if needed
			bne $t9, $zero, negate_dc		# if color of new block is NOT BLACK, negate dc but don't decrement lives.
			la $t9, BLOCKS					# $t9 = address of BLOCKS
			lw $t8, BLOCKS					# $t8 = BLOCKS
			addi $t8, $t8, -1				# $t8 = BLOCKS - 1 
			sw $t8, 0($t9)					# store BLOCKS -1 in address of blocks
			j negate_dc 					# dc = -dc 
		right_pixel:
			addi $t9, $t2, 4					# $t9 = address of pixel to right of ball 
			lw $t9, 0($t9)						# $t9 = color of address of pixel to right of ball 
			beq $t9, $zero, no_side_collision 	# $zero = BLACK. If right pixel is black, no collision. 
			lw $t8, GREY						# $t8 = GREY 
			beq $t9, $t8, negate_dc				# if pixel to right of ball is GREY, this is collision with paddle. Don't need to remove block.
			srl $t9, $t9, 8						# color of block = color of block >> 8 (0xFF0000 -> 0x00FF00 -> 0x0000FF)
			# re-paint block. 
			addi $t8, $t2, 4				# $t8 = address of 1 pixel to right of ball 
			sw $t9, 0($t8)					# color 1 pixel to right of ball with new color 
			sw $t9, 4($t8)					# color 2 pixel to right of ball with new color 
			sw $t9, 8($t8)					# color 3 pixel to right of ball with new color 
			sw $t9, 12($t8)					# color 4 pixel to right of ball with new color 
			# decrease blocks if needed
			bne $t9, $zero, negate_dc		# if color of new block is NOT BLACK, negate dc but don't decrement lives.
			la $t9, BLOCKS					# $t9 = address of BLOCKS
			lw $t8, BLOCKS					# $t8 = BLOCKS
			addi $t8, $t8, -1				# $t8 = BLOCKS - 1 
			sw $t8, 0($t9)					# store BLOCKS -1 in address of blocks
			j negate_dc 					# dc = -dc
		no_side_collision: 						# NO COLLISION: only here if c != 0, c != 31, left and right pixel to ball are black
			j vertical_collision				# if there are no side collisions, check vertical collisions.
		negate_dc: 
			sub $t1, $zero, $t1		# $t1 = 0 - $t1 <=> $t1 = -$t1 <=> dc = -dc 
			la $t9, DC				# $t9 = address of DC 
			sw $t1, 0($t9)			# DC = -DC (update DC)
			
	vertical_collision:
		top_edge:
			beq $t4, $zero, negate_dr	# if $t4 = r = 0, collision with dop edge. dr = -dr.
		bottom_edge: 
			addi $t9, $zero, 31			# $t9 = 31 
			beq $t4, $t9, death			# if collision with bottom edge, death occurs
		top_pixel: 
			addi $t9, $t2, -128			# $t9 = BALL_ADDRESS - 128 = pixel above ball
			lw $t9, 0($t9)				# $t9 = color of pixel above ball 
			beq $t9, $zero, bottom_pixel# if color of pixel above ball is BLACK, then no top collision.
			srl $t9, $t9, 8				# $t9 = $t9 >> 8 (to get new color) 
			# calculate address of block of collision
			addi $t8, $zero 4			# $t8 = 4 
			div $t5, $t8				# $t8/4 = c/4 
			mflo $t8					# $t8 = c // 4
			sll $t8, $t8, 4				# $t8 = $t8 << 4 = 16 * (c // 4) 
			addi $t7, $t4, -1			# $t7 = r-1
			sll $t7, $t7, 7				# $t7 = $t7 << 7 = (r-1)*128
			add $t8, $t8, $t7			# $t8 = 16 * (c // 4) + (r-1)*128
			lw $t7, ADDR_DSPL			# $t7 = ADDR_DSPL
			add $t8, $t7, $t8			# $t8 = ADDR_DSPL + 16 * (c // 4) + (r-1)*128 = address of block of collision
			# re-paint block
			sw $t9, 0($t8)				# repaint pixel 1		 
			sw $t9, 4($t8) 				# repaint pixel 2
			sw $t9, 8($t8) 				# repaint pixel 3
			sw $t9, 12($t8)				# repaint pixel 4	
			# decrease blocks if needed
			bne $t9, $zero, negate_dr	# if color of new block is NOT BLACK, negate dr but don't decrement lives.
			la $t9, BLOCKS				# $t9 = address of BLOCKS
			lw $t8, BLOCKS				# $t8 = BLOCKS
			addi $t8, $t8, -1			# $t8 = BLOCKS - 1 
			sw $t8, 0($t9)				# store BLOCKS -1 in address of blocks
			j negate_dr 				# negate_dr 
		bottom_pixel:
			addi $t9, $t2, 128 						# $t9 = BALL_ADDRESS + 128 = pixel below ball 
			lw $t9, 0($t9)							# $t9 = color of pixel below ball 
			beq $t9, $zero, no_vertical_collision	# if bottom pixel is not BLACK, no collision 
			paddle_collision_btm: 
				lw $t8, GREY						# $t8 = GREY	
				bne $t8, $t9, block_collision_btm	# if $t9 (color of bottom pixel) isn't GREY, we have block collision
				lw $t8, BALL_ADDRESS_OFFSET			# $t8 = BALL_ADDRESS_OFFSET 
				addi $t8, $t8, 128					# $t8 = offset of 1 pixel below ball
				lw $t9, PADDLE_ADDRESS_OFFSET 		# $t9 = PADDLE_ADDRESS_OFFSET 
				sub $t9, $t8, $t9					# $t9 = $t8 - $t9 = offset 1 pixel below ball - paddle offset = 4*i
				addi $t8, $zero 4					# $t8 = 4 
				div $t9, $t8						# $t9 / $t8 = 4i/4 = i (where paddle[i] is collision)
				mflo $t9							# $t9 = i
				# if i = 0,1,6,7, make dc diagonal again (if it is 0) or else do nothing
				i_eq_0: 
					addi $t8, $zero, 0					# $t8 = 0 
					bne $t9, $t8, i_eq_1				# if not equal to 0, check next
					bne $t1, $zero, negate_dr			# if $t1 = dc != 0, don't change dc and only change dr
					addi $t1, $t1, -1					# otherwise, dc = -1
					la $t9, DC							# $t9 = address of DC 
					sw $t1, 0($t9)						# DC = -1 (update DC)
					j negate_dr 						# negate dr
				i_eq_1: 
					addi $t8, $zero, 1					# $t8 = 1
					bne $t9, $t8, i_eq_6				# if not equal to 1, check next
					bne $t1, $zero, negate_dr			# if $t1 = dc != 0, don't change dc and only change dr
					addi $t1, $t1, -1					# otherwise, dc = -1
					la $t9, DC							# $t9 = address of DC 
					sw $t1, 0($t9)						# DC = -1 (update DC)
					j negate_dr 						# negate dr 
				i_eq_6: 
					addi $t8, $zero, 6					# $t8 = 6
					bne $t9, $t8, i_eq_7				# if not equal to 6, check next
					bne $t1, $zero, negate_dr			# if $t1 = dc != 0, don't change dc and only change dr
					addi $t1, $t1, 1					# otherwise, dc = 1
					la $t9, DC							# $t9 = address of DC 
					sw $t1, 0($t9)						# DC = 1 (update DC)
					j negate_dr 						# negate dr 
				i_eq_7:
					addi $t8, $zero, 7					# $t8 = 7 
					bne $t9, $t8, i_eq_2345				# if not equal to 7, check next
					bne $t1, $zero, negate_dr			# if $t1 = dc != 0, don't change dc and only change dr
					addi $t1, $t1, 1					# otherwise, dc = 1
					la $t9, DC							# $t9 = address of DC 
					sw $t1, 0($t9)						# DC = 1 (update DC)
					j negate_dr 						# negate dr 
				i_eq_2345:
					addi $t1, $zero, 0					# $t1 = dc = 0
					la $t9, DC							# $t9 = address of DC 
					sw $t1, 0($t9)						# DC = 0 (update DC)
					j negate_dr 						# negate dr 
			block_collision_btm:
				addi $t9, $t2, 128 					# $t9 = BALL_ADDRESS + 128 = pixel below ball 
				lw $t9, 0($t9)						# $t9 = color of pixel below ball 
				srl $t9, $t9, 8						# $t9 = $t9 >> 8 = new color 
				# calculate address of block of collision 
				addi $t8, $zero, 4					# $t8 = 4 
				div $t5, $t8						# $t8/4 = c/4
				mflo $t8							# $t8 = c // 4
				sll $t8, $t8, 4						# $t8 = 16(c // 4)
				addi $t7, $t4, 1					# $t7 = r+1 
				sll $t7, $t7, 7						# $t7 = $t7 << 7 = 128(r+1)
				add $t8, $t8, $t7					# $t8 = 16(c // 4) + 128(r+1) 
				lw $t7, ADDR_DSPL					# $t7 = ADDR_DSPL
				add $t8, $t7, $t8			# $t8 = ADDR_DSPL + 16 * (c // 4) + (r+1)*128 = address of block of collision
				# re-paint block
				sw $t9, 0($t8)				# repaint pixel 1		 
				sw $t9, 4($t8) 				# repaint pixel 2
				sw $t9, 8($t8) 				# repaint pixel 3
				sw $t9, 12($t8)				# repaint pixel 4	
				# decrease blocks if needed
				bne $t9, $zero, negate_dr	# if color of new block is NOT BLACK, negate dr but don't decrement lives.
				la $t9, BLOCKS				# $t9 = address of BLOCKS
				lw $t8, BLOCKS				# $t8 = BLOCKS
				addi $t8, $t8, -1			# $t8 = BLOCKS - 1 
				sw $t8, 0($t9)				# store BLOCKS -1 in address of blocks
				j negate_dr 				# negate dr 											
		no_vertical_collision: 			# NO COLLISION: erase ball and redraw ball
			j erase				
		negate_dr: 
			sub $t0, $zero, $t0     # $t0 = 0 - $t0 <=> $t0 = -$t0 <=> dr = -dr 
			la $t9, DR				# $t9 = address of DR
			sw $t0, 0($t9)			# DR = -DR (update DR)
			
	erase:
		addi $t9, $zero, 0x000000	# $t9 = black 
		sw $t9, 0($t2)				# draw black over old ball
	
	draw_updated:
		sll $t0, $t0, 7				# $t0 = $t0 << 7 = 128 * $t0 = 128 dr 
		sll $t1, $t1, 2				# $t1 = $t1 << 2 = 4 * $t1 = 4 dc 
		add $t2, $t2, $t0			# move ball vertically (old ball address + 128dr)
		add $t2, $t2, $t1			# move ball horizontally (vertically moved ball + 4dc)
		lw $t9, GREY				# $t9 = GREY 
		sw $t9, 0($t2)				# draw GREY over new ball
		lw $t9, BALL_ADDRESS_OFFSET # $t9 = BALL_ADDRESS_OFFSET
		la $t8, BALL_ADDRESS_OFFSET # $t8 = address of BALL_ADDRESS_OFFSET
		add $t9, $t9, $t0			# move offset vertically 
		add $t9, $t9, $t1			# move offset vertically
		sw $t9, 0($t8)				# BALL_ADDRESS_OFFSET = $t9 = new ball address 
	
	j return 						# shouldn't jump to death if unecessary
		
	death:
		la $t9, LIVES				# $t9 = address of LIVES 
		lw $t8, LIVES				# $t8 = lives 
		addi $t8, $t8, -1			# $t8 = lives - 1 
		sw $t8, 0($t9)				# store lives-1 into address of LIVES
		beq $t8, $zero, EXIT		# if $t8 = lives = 0, exit game. TODO: maybe restart game
		
		# draw black over ball and paddle 
		lw $t9, BALL_ADDRESS_OFFSET 	# $t9 = address of BALL_ADDRESS_OFFSET 
		lw $t8, ADDR_DSPL				# $t8 = ADDR_DSPL
		add $t9, $t8, $t9				# $t9 = $t9 + $t8 = address of ball 
		sw $zero, 0($t9)				# draw black over ball 
		lw $t9, PADDLE_ADDRESS_OFFSET 	# $t9 = address of PADDLE_ADDRESS_OFFSET 
		add $t9, $t8, $t9				# $t9 = $t9 + $t8 = address of paddle 
		sw $zero, 0($t9)				# draw black over paddle[0] 
		sw $zero, 4($t9)				# draw black over paddle[1] 
		sw $zero, 8($t9)				# draw black over paddle[2] 
		sw $zero, 12($t9)				# draw black over paddle[3] 
		sw $zero, 16($t9)				# draw black over paddle[4] 
		sw $zero, 20($t9)				# draw black over paddle[5] 
		sw $zero, 24($t9)				# draw black over paddle[6] 
		sw $zero, 28($t9)				# draw black over paddle[7] 
		
		# reset other things 
		la $t9, BALL_ADDRESS_OFFSET 	# $t9 = address of BALL_ADDRESS_OFFSET 
		addi $t8, $zero, 3388			# $t8 = 3388 
		sw $t8, 0($t9)					# BALL_ADDRESS_OFFSET  = 3388 
		la $t9, DR						# $t9 = address of DR 
		addi $t8, $zero, -1				# $t8 = -1 
		sw $t8, 0($t9)					# DR = -1
		la $t9, DC						# $t9 = address of DR 
		addi $t8, $zero, -1				# $t8 = -1 
		sw $t8, 0($t9)					# DC = -1
		la $t9, PADDLE_ADDRESS_OFFSET 	# $t9 = address of PADDLE_ADDRESS_OFFSET 
		addi $t8, $zero, 3632			# $t8 = 3632
		sw $t8, 0($t9)					# PADDLE_ADDRESS_OFFSET = 3632
		
		# redraw black over ball and paddle 
		lw $t9, BALL_ADDRESS_OFFSET 	# $t9 = address of BALL_ADDRESS_OFFSET 
		lw $t8, ADDR_DSPL				# $t8 = ADDR_DSPL
		lw $t7, GREY					# $t7 = GREY
		add $t9, $t8, $t9				# $t9 = $t9 + $t8 = address of ball 
		sw $t7, 0($t9)					# draw GREY over ball 
		lw $t9, PADDLE_ADDRESS_OFFSET 	# $t9 = address of PADDLE_ADDRESS_OFFSET 
		add $t9, $t8, $t9				# $t9 = $t9 + $t8 = address of paddle 
		sw $t7, 0($t9)					# draw GREY over paddle[0] 
		sw $t7, 4($t9)					# draw GREY over paddle[1] 
		sw $t7, 8($t9)					# draw GREY over paddle[2] 
		sw $t7, 12($t9)					# draw GREY over paddle[3] 
		sw $t7, 16($t9)					# draw GREY over paddle[4] 
		sw $t7, 20($t9)					# draw GREY over paddle[5] 
		sw $t7, 24($t9)					# draw GREY over paddle[6] 
		sw $t7, 28($t9)					# draw GREY over paddle[7] 
	
	return:
		jr $ra

GAME_LOOP:
    # 1. Check if key has been pressed and move paddle.
    li 		$v0, 32                 
	li 		$a0, 1
	syscall
	
    lw $t0, ADDR_KBRD               # $t0 = base address for keyboard
    lw $t8, 0($t0)                  # Load first word from keyboard
    bne $t8, 1, no_key_pressed      # If first word is not 1, not key is pressed
   	jal HANDLE_KEYBOARD
   	
   	no_key_pressed:
   	
   	# 2. Move ball. Detect collisions. Remove blocks.
    jal MOVE_BALL					# move ball
   
    
	# 3. Sleep for 250ms.
	li $v0, 32        			    # operation 32 = sleep
	li $a0, 100       				# 100 miliseconds 
	syscall           				# Execute the "sleep(250)" system call
	
    # 4. Repeat steps 1 to 4.
	b GAME_LOOP
	
HANDLE_KEYBOARD: 
	# usage: handle_keyboard() 
	# q = quit, a = move paddle left, d = move paddle right
	addi $sp, $sp, -4               		# increase size of stack 
	sw $ra, 0($sp)                  		# push `$ra` onto stack
	
	lw $a0, 4($t0)                  		# Load second word from keyboard
	
	key_eq_q:
    beq $a0, 0x71, EXIT             		# if 'q' pressed, EXIT game
    
    key_eq_a:
    bne $a0, 0x61, key_eq_d         		# if 'a' is not pressed, check 'a'
    jal MOVE_PADDLE_LEFT            		# otherwise, move paddle left
    j handle_keyboard_return        		# and return once done
    
    key_eq_d: 		
    bne $a0, 0x64, handle_keyboard_return	# if 'd' is not pressed, return 
    jal MOVE_PADDLE_RIGHT 				    # otherwise, move paddle right 
    j handle_keyboard_return 				# and return once done
    
   	handle_keyboard_return:
    lw $ra, 0($sp)                  # pop `$ra` from stack
    addi $sp, $sp, 4                # decrease size of stack 
    
    li $v0, 1                       # ask system to print $a0
    syscall

    jr $ra
	
EXIT: 
	li $v0, 10              # terminate the program gracefully
    syscall

	
