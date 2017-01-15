// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/04/Fill.asm

// Runs an infinite loop that listens to the keyboard input.
// When a key is pressed (any key), the program blackens the screen,
// i.e. writes "black" in every pixel;
// the screen should remain fully black as long as the key is pressed. 
// When no key is pressed, the program clears the screen, i.e. writes
// "white" in every pixel;
// the screen should remain fully clear as long as no key is pressed.

// Put your code here.
   @fill
   M=0        // fill is intially white

   @8192      // 32*256, size of SCREEN in words
   D=A
   @n
   M=D        // save it in n
   
(TEST)
   @KBD
   D=M        // Save value of KBD
   @NOTKBD
   D;JEQ      // if KBD == 0 goto NOTKBD
              // else a key has been pressed
   @fill
   D=M
   @FILL
   D;JEQ      // if fill == 0, FILL
   @TEST
   0;JMP      // nothing to do, TEST again

(NOTKBD)
   @fill
   D=M
   @FILL
   D;JNE      // if fill != 0, FILL
   @TEST
   0;JMP      // nothing to do, TEST again

(FILL)
   @fill
   D=M
   M=!D       // can only get here if fill needs updating
   @i
   M=0        // initialise i
   
(LOOP)
   @i
   D=M
   @n
   D=D-M
   @TEST
   D;JEQ      // go back to TEST if i == n

   @i
   D=M
   @SCREEN
   D=D+A      // calculate addr
   @addr
   M=D        // and store it

   @fill
   D=M        // load fill in D
   @addr
   A=M        // load A from addr
   M=D        // M now is *addr, fill it
   
   @i
   M=M+1      // increment i
   
   @LOOP
   0;JMP      // jump back to start of loop

			  // no need for an infinite loop here, we already have one :P
