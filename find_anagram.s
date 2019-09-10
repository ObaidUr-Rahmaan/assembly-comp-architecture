	.data
	.align 2

outputstring: .asciiz "Number of Anagrams found: "

k:      .word   4        # include a null character to terminate string
s:      .asciiz "cba"
n:      .word   6
L:      .asciiz "bca"
        .asciiz "abc"
        .asciiz "bbb"
        .asciiz "ddd"
        .asciiz "dde"
        .asciiz "dec"
	
    .text
### ### ### ### ### ###
### MainCode Module ###
### ### ### ### ### ###
main:
    li $t9,4                            # $t9 = size of input string (since each word/string is 4 bytes)
    lw $s0,k                            # $s0: length of the input string
    la $s1,s                            # $s1: input string
    lw $s2,n                            # $s2: size of string array
    
# allocate heap space for string array:    
    li $v0,9                            # syscall code 9: allocate heap space
    mul $a0,$s2,$t9                     # calculate the amount of heap space
    syscall                             # allocate the space
    move $s3,$v0                        # $s3: base address of a string array
    
# record addresses of declared strings into a string array:  
    move $t0,$s2                        # $t0: counter i = n
    move $t1,$s3                        # $t1: address pointer j
    la $t2,L                            # $t2: address of declared array L
    
READ_DATA:
    blez $t0,FIND                       # if i > 0, read string from L
    sw $t2,($t1)                        # put the address of a string into string array.
    
    addi $t0,$t0,-1                     # decremeent i by 1
    addi $t1,$t1,4                      # move 4 bytes down
    add $t2,$t2,$s0                     # new address -> $t2
    j READ_DATA                         # loop back
 
FIND:
    
    #setting arguments for merge sort
    la $a0, L		                    # $a0 = start address of L
    li $a1 0                            # offset from heap
    
#Loops through each element in L
LISTLOOP:

    jal SORTLISTSTRINGLOOP
    
    #store into heap
    addi $t0, $s3, 0                    # base address -> $t0
    add $t0, $t0, $a1                   # offset + base address
    sw $a0, ($t0)                       # store word in heap at new address
    
    la $t0, L                           # load start address
    lw $t1, n                           # load number of elements
    lw $t2, k                           # load word size
    
    addi $a1, $a1, 4
    add $a0, $a0, $t2                   # increment current index to next word
    
    mul $t1, $t1, $t2                   # total word size -> $t1
    add $t0, $t0, $t1                   # end address -> $t0  
    sub $t0, $t0, $a0                   # calculate difference between addresses
    
    bgtz $t0, LISTLOOP                  # If more words, branch. Else SORT s
	
	#L Sorted, SORT s
	la $a0, s                           # load string arguement
	jal SORTLISTSTRINGLOOP              # SORT string s
	
	# Finished
    b GETANAGRAMS                       # Jump to GETANAGRAMS


#SORTLISTSTRINGLOOP: Loops through the List, passing each element(String) into Mergesort and storing in Heap
#$a0: Start address of the string
#$a1: Heap offset 
SORTLISTSTRINGLOOP:
    # maintain arguments for recursive call:
    addi $sp, $sp, -12                  # move pointer down 12 bytes
    sw $ra, 0($sp)                      # store return address onto stack
    sw $a0, 4($sp)                      # store start address onto stack
    sw $a1, 8($sp)                      # store offset onto stack
    
    lw $a1, k                           # $a1 = word length
    addi $a1, $a1, -1                   # $a1 = calc end of word - 1
    add $a1, $a0, $a1                   # $a1 = end addresss of string to sort
    
    # Mergesort is now called (Works on $a0 = start add. & $a1 = end add.)
    jal MERGESORT
    
    # preserve state
    lw $ra, 0($sp)                      # return address loaded
    lw $a0, 4($sp)                      # start address loaded 
    lw $a1, 8($sp)                      # offset loaded
    jr $ra                              # loop finished, continue to next word

#MERGESORT: Sorts a string bases on Merge-Sort algorithm O(nlogn) avg. + worst case
#$a0: start address of the word
#$a1: end address of the word
MERGESORT:
     # maintain arguments for recursive call:
     addi $sp, $sp, -16       		    # move pointer down 16 bytes
     sw $ra, 0($sp)         		    # store return address onto stack
     sw $a0, 4($sp)         		    # store start address onto stack
     sw $a1, 8($sp)         		    # store end address on stack
     
     sub $t0, $a1, $a0        		    # calculate difference between addresses
     li $t1, 1				            # base case variable: 1 char
     
     ble $t0, $t1, END    	            # Branch if string length is 1 (i.e. 1 char) -> END
     
     # Otheriwse, split
     
     srl $t0, $t0, 1		            # shift logical shift -> $t0 = $t0 / 2^1
	 add $a1, $a0, $t0		            # calculate midpoint address -> $a1
	 sw $a1, 12($sp)		            # store mid-point into stack
	 
	 jal MERGESORT		                # recursive call on first half

	 lw	$a0, 12($sp)		            # load mis-point address from stack
	 lw	$a1, 8($sp)		                # load end address from stack
	
	 jal MERGESORT		                # recursive call on second half
	
	 lw	$a0, 4($sp)		                # load start address from stack
	 lw	$a1, 12($sp)		            # load middle address from stack
	 lw	$a2, 8($sp)	            	    # load end address from stack
	
	 # Merge is now called (Works on $a0 = start add. & $a1 = mid add.)
	 jal MERGE
	 

END:
     lw	$ra, 0($sp)			            # load return address from stack
     addi $sp, $sp, 16			        # push stack pointer up 16 bytes (i.e. reset)
     jr $ra			            	    # jump to address in return register (i.e. return)
     

# MERGE: Merge-sort helper function (Merges 2 char strings together in alphabetical order)
# $a0 First address of first char
# $a1 First address of second car
# $a2 Last address of second char
MERGE:
    # maintain state
	addi $sp, $sp, -16		            # move pointer down 16 bytes
	sw	$ra, 0($sp)		                # store return address on stack 
	sw	$a0, 4($sp)		                # store the start address on the stack
	sw	$a1, 8($sp)		                # store the midpoint address on the stack
	sw	$a2, 12($sp)		            # store the end address on the stack
	
	move $s1, $a0		                # create a copy of first half
	move $s2, $a1		                # create a copy of second half
	
MERGELOOP: 
	lb $t0, 0($s1)		                # load first char from first half
	lb $t1, 0($s2)		                # load first char from second half
	
	bgt	$t1, $t0, NOMOVE	            # Branch if IN correct order -> NOMOVE (i.e. no need to shift)

    # Loading the 2 arguements for STEP
	move $a0, $s2		                
	move $a1, $s1		                 
	
	# STEP is now called
	jal	STEP			                
	
	# Post- 'stepping' (i.e. correcting order)
	
	addi $s2, $s2, 1		            # increment second half pointer

NOMOVE:
	addi $s1, $s1, 1		            # increment first half pointer
	
	lw	$a2, 12($sp)		            # re-load the end address of the string
	bge	$s1, $a2, MERGELOOPEND	        # End if both halves are empty
	bge	$s2, $a2, MERGELOOPEND	        # End if both halves are empty
	b	MERGELOOP
	
MERGELOOPEND:
    # preserve state
	lw $ra, 0($sp)		                # load return address from stack 
	addi $sp, $sp, 16			        # push stack pointer up 16 bytes (i.e. reset)
    jr $ra			            	    # jump to address in return register (i.e. return) 

# STEP: Merge-sort helper function to shift characters that are not in order
# $a0 address of char to shift
# $a1 destination pointer of char 
STEP:
	ble	$a0, $a1, STEPEND	            # Branch if we are at the destination -> STEPEND
	
	# Otherwise, continue
	
	addi $t6, $a0, -1		            # move to previous bit
	lb	$t7, 0($a0)		                # load current character of first half into temp variable
	lb	$t8, 0($t6)		                # load current character of second half into temp variable
	sb	$t7, 0($t6)		                # store the first into the second
	sb	$t8, 0($a0)		                # store the second into the first
	move $a0, $t6		                # $a0 <- $t6 (pointer change) 
	b 	STEP			                # Loop back

STEPEND:
	jr $ra			            	    # jump to address in return register (i.e. return) 




# FINALE: Sorting complete. Now to compare

# GETANSGRAMS: Loops through L to find anagrams, 
#----------------------------------------
GETANAGRAMS:
    li $s0, 0                           # Counter = 0
    
    la $a0, L                           # load start address of L
    lw $t1, n                           # load size of L (number of strings)
    lw $t2, k                           # load size of each string in L
    
    mul $t1, $t1, $t2                   # total size of L (string * num. elements)
    add $a1, $a0, $t1                   # calc end address (start + size of L)

LOOPFORLIST:
    # CHECKISANAGRAM is now called (checks if the current string is an anagram)
    jal CHECKISANAGRAM                  
    lw $t2, k                           # load the length of the string
    add $a0, $a0, $t2                   # go to the next string
    sub $t2, $a1, $a0                   # find difference to check if we are at the end
    bgtz $t2, LOOPFORLIST               # Branch if diff. > 0 -> LOOPFORLIST
    
    b OUTPUT                            # End. Print out Counter
    
# CHECKISANAGRAM: GetAnagram helper function (compares strings)
#$a0: base address of word
#$a1: end address of word 
CHECKISANAGRAM:
    # maintain state 
    addi $sp, $sp, -12                  # move stack pointer down 12 bytes
    sw $ra, 0($sp)                      # store return address on stack
    sw $a0, 4($sp)                      # store base address on stack
    sw $a1, 8($sp)                      # store store end address on stack

    li $a2, 0                           # Reset Counter
    la $a1, s                           # calculate the end address of the string
    jal TOTAL                           # calculate the total of the string
    
    beqz $a2, FOUND                     # 

    b SHIFTFORWARD                      # 
    #anagram found, increment counter
FOUND:   
    addi $s0, $s0, 1                    # 
    add $a1, $a1, $t9                   # 
SHIFTFORWARD:
    lw $ra, 0($sp)                      # 
    lw $a0, 4($sp)                      # 
    lw $a1, 8($sp)                      # 
    jr $ra
    
# check next word
    
#calculates the difference of characters in word $a0 from s e.g.
#$a0: destination address of word 
#$a1: current address
#return: $a2: sum of anagrams found
TOTAL:  
    lb $t2, 0($a0)                      # byte value -> $a0
    beqz $t2, ENDFOUND                  # Branch to check if we are at a null pointer -> ENDFOUND
    lb $t1, 0($a1)                      # load corresponding byte in word s (word size in k must = word size of s)
    
    #-------------
    
    beq $t1, $t2, CALCULATE             # Branch if byte value is greate than $t2's char -> CALCULATE
    b ENDNOTFOUND                       # jump to ENDNOTFOUND
    
    #-------------

# CACULATE: Helper function
CALCULATE:
    addi $a0, $a0, 1                    # move to next character
    addi $a1, $a1, 1                    # move to next character in word s
    b TOTAL                             # Loop on next word
    
# ENDNOTFOUND: Helper function
ENDNOTFOUND:
    addi $a2, $a2, 1
    jr $ra			            	    # jump to address in return register (i.e. return)

# ENDFOUND: Helper function
ENDFOUND:
    jr $ra			            	    # jump to address in return register (i.e. return)

#--------------------------------------
# OUTPUT: Prints out the expected result of this entire program
OUTPUT:

    # Print out "Number of Anagrams found: "
    li $v0, 4                           
    la $a0, outputstring
    syscall                         
        
    # Print out Counter (i.e. number of anagrams of found
    
    move $a0, $s0                      # counter -> $a0
    li $v0 1                           # load result -> $v0
    syscall                            # execute

    # End cleanly
    li $v0 10                          
    syscall                            
