# Author : Obaid Ur-Rahmaan
# ID: 1807611
# Created: 23/11/2018
# Updated: 26/11/2018

        .data
        
prompt:     .asciiz "Provide an integer for the Fibonacci computation: "
result:     .asciiz "The Fibonacci numbers are: "
colon:      .asciiz ": "
newline:    .asciiz "\n"

        .text
        
main:

                            # Miscellaneous

    # ---------------------------------------------------------------------
    
    # Prompt user for input number (n)
    la $a0, prompt
    li $v0, 4
    syscall
    
    
    # Read the input number from user
    li $v0, 5
    syscall
    
    move $s0, $v0                           # $s0 <- n = input number
    
    # ---------------------------------------------------------------------
    
          # Create empty array using heap
    
    # ---------------------------------------------------
    
    li $t0, 4                               # temp variable = 4 (size of words in bytes)
    move $t1, $s0                           # copy n
    addi $t1, $t1, 1                        # n + 1
    mul $t1, $t1, $t0                       # size of the array created = (n + 1) * 4
    
    # allocate space in heap
    move $a0, $t1
    li $v0, 9
    syscall
    
    # int[n + 1] memo now created in heap
    
    move $s1, $v0                           # $s1 <- array address (int[n + 1] memo)

    # ---------------------------------------------------


    # Print out result string
    la $a0, result
    li $v0, 4
    syscall
    
    # Print newline
    la $a0, newline
    li $v0, 4
    syscall    


      # Loop - prints all fib. nums upto n

    # --------------------------------------
    
    li $t0, 0                               # i = 0
    
    
    # Max amount of times to loop (n + 1) (i.e. because of 0)
    move $t1, $s0                           # copy n
    addi $t1, $t1, 1                        # n = n + 1
    
    LOOP:
    
        # Check if i = n
        beq $t0, $t1, ENDLOOP
        
        # Print curr. counter value
        move $a0, $t0
        li $v0, 1
        syscall
        
        # Print out colon
        la $a0, colon
        li $v0, 4
        syscall
        
        # Set up arguement for FIB ($a0 <- n, $a1 <- heap)
        move $a0, $t0
        move $a1, $s1
        jal FIB
        
        # Print out fib for current i
        move $a0, $v0
        li $v0, 1
        syscall
        
        # Print newline
        la $a0, newline
        li $v0, 4
        syscall
        
        # increment i
        addi $t0, $t0, 1
        
        # Jump back to LOOP
        j LOOP
        
    
    ENDLOOP:
    
    # --------------------------------------
    
    # end cleanly
    li $v0, 10
    syscall



# FIB - Function to print out fibonacci number n using memoisation
# Args - $a0 = n, $a1 = heap address
FIB:
    
    
    #----------------------------------------------------------------

    # Check if n <= 0: Otherwise -> ELSE1
        # return 0
	
    bgt $a0, $zero, ELSE1
    li $v0, 0                           # Return value ($v0) <- 0
    
    jr $ra                              # Return 0
    
    ELSE1:
    
    # Check if n == 1: Otherwise -> ELSE2
        # return 1
        
    li $t2, 1
    bne $a0, $t2, ELSE2
    move $v0, $t2                       # Return value ($v0) <- 1
        
    jr $ra                              # Return 1
    
    ELSE2:
    
    li $t3, 4
    mul $t3, $a0, $t3                   # $t3 <- n * 4
    
    add $a1, $a1, $t3                   # Move pointer forward n * 4 bytes down the array
    
    # Check if memo[n] > 0: Otherwise -> RECURSE
        # return memo[n]

    lw $t5, 0($a1)                      # get memo[n]
    
    sub $a1, $a1, $t3                   # Move pointer back n * 4 bytes down the array (i.e. reset pointer)
    
    blez $t5, RECURSE
    
    move $v0, $t5                       # Return value ($v0) <- memo[n]

    jr $ra                              # Return memo[n]
    
    # ---------------------------------------------------------------
    

    
    
RECURSE:
    
    # Allocate space to stack (4 bytes for arguement, 4 bytes for ret. address)
    addi $sp, $sp, -12
    sw $a1, 8($sp)
    sw $ra, 4($sp)
    sw $a0, 0($sp)


    # Recursion
    #---------------------
    # Calculate fib(n - 1)
    addi $a0, $a0, -1 
	jal FIB
    #---------------------
    
    
    # preserve state
    lw $a0, 0($sp)                      # Get previous $a0 back
    lw $a1, 8($sp)
    
    # Allocate space to stack (4 bytes for fib(n - 1))
    addi $sp, $sp, -4
    sw $v0, 0($sp)                      # Store fib(n - 1) value
    
    
    # Recursion
    #---------------------
    # Calculate fib(n - 2)
    addi $a0, $a0, -2
	jal FIB
	#---------------------
	
    
    # memo[n] = fib(n - 1, memo) + fib(n - 2, memo)
    
    #--------------------------------------------------
    
    # preserve states
    lw $a1, 12($sp)
    lw $ra, 8($sp)
	lw $a0, 4($sp)
    lw $v1, 0($sp)
	addi $sp, $sp, 16
    
    
    li $t3, 4
    mul $t3, $a0, $t3                   # $t3 <- n * 4
    
    # # Copy array in heap (so we can move pointer and access the required value stored)
    # move $t4, $s1
    
    add $a1, $a1, $t3                   # Move pointer n * 4 bytes down the array
    
    add $v0, $v0, $v1                   # fib(n - 1, memo) + fib(n - 2, memo)
    
    sw $v0, 0($a1)                      # Store value at pointer location (i.e. memo[n])
    
    sub $a1, $a1, $t3                   # Move pointer back n * 4 bytes down the array (i.e. reset pointer)
	
    #--------------------------------------------------

    jr $ra                              # Return memo[n]