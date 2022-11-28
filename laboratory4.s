.data 	
	menu_text: .asciiz "Menu\n1: Create a New Node\n2: Search for a Node by ID\n3: Exit the Program\n"
	menu_prompt: .asciiz "Enter your menu choice: "
	menu_error: .asciiz "Invalid menu choice. Please try again.\n"
	exit_message: .asciiz "Exiting the program.\n"
	id_prompt: .asciiz "Enter your ID Number: "
	name_length_prompt: .asciiz "Enter the length of your name: "
	name_prompt: .asciiz "Enter your name: "
	id_search_prompt: .asciiz "Enter the ID Number you wish to search for: "
	name_found: .asciiz "The requested name is: "
	id_found: .asciiz "The requested ID Number is: "
	next_found: .asciiz "The address of the next node is: "
	id_not_found: .asciiz "The requested ID Number was not found in the Linked List.\n"
	list_empty: .asciiz "The Linked List is empty.\n"
	nl: .asciiz "\n"
	hexchars: .ascii "0123456789ABCDEF"
.text

# The printaddrashex function converts the provided integer argument into 
# a fixed-width 8 character hexadecimal string, prints the string, and returns the address of the created string.
#
# Parameters
# ----------
#  $a0 - the value to convert to hexadecimal
#
# Return
# ------
#  Returns the address of the 8byte memory space allocated to hold the hex string in $v0
#
# !! WARNING !!
# This function destructively modifies the following registers:
# - $t0
# - $a0
# - $v0
# - $t1
# - $t2
# - $t3
# - $t4
# - $t5
# - $t6
# - $t7
# - $t8


printaddrashex:
	move $t0, $a0
	
	#allocate memory for the hex string
	li $a0, 8
	li $v0, 9
	syscall

	move $t1, $v0

	#initialize the memory in the string to be all zeros
	li $t2, 48		
	li $t3, 8
	move $t4, $t1

pah_initloop:
	beq $t3, $zero, pah_writehex
	sb $t2, 0($t4)
	addi $t4, $t4, 1
	sub $t3, $t3, 1
	j pah_initloop

pah_writehex:
	li $t2, 16
	li $t3, 8
	move $t4, $t1
	
pah_writehexloop:
	beq $t3, $zero, pah_revstr
	#compute the remainder of the value
	rem $t5, $t0, $t2
	#load the appropriate byte from the hexchar string
	la $t6, hexchars
	add $t6, $t6, $t5
	lb $t7, 0($t6)
	#store the character in the allocated memory
	sb $t7, 0($t4)
	addi $t4, $t4, 1
	
	#reduce $t0
	div $t0, $t0, $t2	
	#decrement the loop counter
	sub $t3, $t3, 1
	j pah_writehexloop

pah_revstr:
	li $t2, 8
	li $t3, 4
	move $t4, $t1
pah_revstrloop:
	beq $t3, $zero, pah_cleanup
	#swap mirrored characters ((0,7), (1,6), (2,5), or (3,4))
	#compute the large index to swap
	addi $t5, $t3, 3
	#compute the small index	
	sub $t6, $t2, $t5
	sub $t6, $t6, 1
	#load the two bytes into registers
	add $t6, $t4, $t6
	add $t5, $t4, $t5
	#store the chars in a temp register
	lb $t7, 0($t5)
	lb $t8, 0($t6)
	#write the chars to opposite positions
	sb $t7, 0($t6)
 	sb $t8, 0($t5)
	#subtract 1 from $t3
	sub $t3, $t3, 1
	j pah_revstrloop
		
pah_cleanup:
	#print the string
	move $a0, $t1
	li $v0, 4
	syscall

	move $v0, $t1
	jr $ra


#####################
# Main starts here  #
#####################
main:

###################
# User input loop #
###################
input_loop:
	#print the menu
	la $a0, menu_text
	li $v0, 4
	syscall

	#print the prompt
	la $a0, menu_prompt
	li $v0, 4
	syscall

	#read the user input
	li $v0, 5
	syscall

	#check the user input and jummp to the appropriate function
	beq $v0, 1, create_node
	beq $v0, 2, search_node
	beq $v0, 3, exit

	#print the error message
	la $a0, menu_error
	li $v0, 4
	syscall

	j input_loop

create_node:
	jal create_node_func
	# v0 now contains the address of the created node
	# the node now needs to be added to the linked list

	# if the list is empty, set the list to point to the new node
	# otherwise, add the new node to the end of the list
	beq $s0, $zero, create_node_emptylist
	# the list is not empty
	# find the end of the list
	move $t4, $s0
create_node_findend:
	lw $t5, 8($t4)
	beq $t5, $zero, create_node_addnode
	move $t4, $t5
	j create_node_findend

	# add the new node to the end of the list
create_node_addnode:
	sw $v0, 8($t4)
	j create_node_end

	# the list is empty
	# set the list to point to the new node
create_node_emptylist:
	move $s0, $v0

create_node_end:
	j input_loop

search_node:
	# prompt the user for required number
	la $a0, id_search_prompt
	li $v0, 4
	syscall

	# read the user input
	li $v0, 5
	syscall

	# store the input in a0
	move $a0, $v0

	# store the linked list address in $a1
	move $a1, $s0
	jal search_node_func
	# v0 now contains the address of the found node
	j input_loop

exit:
	jal exit_func

#######################################################
# (1) menu action - create and add a node to the list #
#######################################################
create_node_func:
# creates a new node and adds it to the list
# the list is held in $s0

	# prompt the user for their ID number
	la $a0, id_prompt
	li $v0, 4
	syscall

	# read the ID number
	li $v0, 5
	syscall

	# store it in t0
	move $t0, $v0

	# prompt the user for the length of their name
	la $a0, name_length_prompt
	li $v0, 4
	syscall

	# read the length of the name
	li $v0, 5
	syscall

	# store it in s1
	addi $v0, $v0, 1
	move $t1, $v0

	# allocate an appropriate amount of memory dynamically
	# to store the name using the value os t1
	move $a0, $t1
	li $v0, 9
	syscall

	# store the address of the allocated memory in t2
	move $t2, $v0

	# prompt the user for their name
	la $a0, name_prompt
	li $v0, 4
	syscall

	# read the name into the allocated memory
	move $a0, $t2
	move $a1, $t1
	li $v0, 8
	syscall

	# nl 
	la $a0, nl
	li $v0, 4
	syscall

	# allocate memory for the node
	li $a0, 12
	li $v0, 9
	syscall

	# store the ID number in the node
	sw $t0, 0($v0)

	# store the address of the name in the node
	sw $t2, 4($v0)

	# store the address of the next node in the node
	sw $zero, 8($v0)

	jr $ra	

###################################################### 
# (2) menu action - search the nodes for an id value #
######################################################
search_node_func:
# takes 2 arguments
# $a0 - the id number to search for
# $a1 - the address of the first node in the list
# returns nothing, but prints the name whole contents of the node

	# check if the list is empty
	beq $a1, $zero, search_node_emptylist

	# the list is not empty
	# search the list for the id number
	move $t4, $a1
search_node_findid:
	lw $t5, 0($t4)
	beq $t5, $a0, search_node_foundid
	lw $t4, 8($t4)
	beq $t4, $zero, search_node_notfound
	j search_node_findid

	# the id number was found
search_node_foundid:
	# print the name
	la $a0, name_found
	li $v0, 4
	syscall

	# print the name
	lw $t6, 4($t4)
	move $a0, $t6
	li $v0, 4
	syscall

	# nl
	la $a0, nl
	li $v0, 4
	syscall

	# print the id number
	la $a0, id_found
	li $v0, 4
	syscall

	# print the id number
	lw $t7, 0($t4)
	move $a0, $t7
	li $v0, 1
	syscall

	# nl
	la $a0, nl
	li $v0, 4
	syscall



	# print the next node address
	la $a0, next_found
	li $v0, 4
	syscall

	# print the next node address
	lw $t8, 8($t4)
	move $a0, $t8
	li $v0, 1
	syscall

	# nl
	la $a0, nl
	li $v0, 4
	syscall


	j search_node_end

	# the id number was not found
search_node_notfound:
	# print the error message
	la $a0, id_not_found
	li $v0, 4
	syscall

search_node_end:
	jr $ra

	# the list is empty
search_node_emptylist:
	# print the error message
	la $a0, list_empty
	li $v0, 4
	syscall

	jr $ra


######################################
# (3) menu action - exit the program #
######################################
exit_func:

	#print the exit message
	la $a0, exit_message
	li $v0, 4
	syscall

	li $v0, 10
	syscall
