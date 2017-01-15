// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/04/Mult.asm

// Multiplies R0 and R1 and stores the result in R2.
// (R0, R1, R2 refer to RAM[0], RAM[1], and RAM[2], respectively.)

// Put your code here.

// Attempt to implement Booth's multiplication algorithm:
// Compute P = X*Y in the followign way:

// For each bit y_(i) of Y, ranging from 0 (LSB) to N (one
// past the MSB), where N is the width of X and Y,
// compare y(i) with y(i-1), using an implicit y_(-1)
// and y(N)of 0.
// Now:
// if (y_(i) == y_(i-1)
//    do nothing
// else if (y_(i) == 0 && y_(i-1) == 1)
//    P = P + 2^i * X
// else if (y_(i) == 1 && y_(i-1) == 0)
//    P = P - 2^i * X 
//
// Note that this will produce a reult of width 2N, but we
// may saftely ignore the higest N bits if we are content
// to compute P = (X*Y) mod 2^N, as usual with overflow. 
//
// This all probably won't be as near efficient as the naive
// algorithm, as we have a naive architecture that doesn't
// well support the Booth's multiplication algorith in the
// following ways:
//
//  * No facility is provided for shifting. We can do a
//    Shift Left Arithmetic (SLA) of a single place by
//    simply adding the number to itself. Effectively
//    multiplying it by 2 and having the desired effect.
//
//    Unfortunately there isn't a corresponding easy way
//    to do a Shift Right Arithmetic (SRA) by addition.
//    So instead we mask off the first by ANDing it with 1,
//    them against zero by using a jump. Then we SLA the
//    mask and mask and test again, gradually getting out
//    all the bits starting at the least significant bit
//    (LSB) and proceeding to the most significant bit
//    MSB.
//
//    This combined with SLAing of X to compute the 2^i * X
//    terms works, but it is all quite a lot of operations
//    to save some adds
//
//  * This is particularly pointless in Hack as all
//    operations in Hack take exactly one clock cycle to
//    complete 
//
// However the implementation of Booth's multiplication
// algorith is still a valuable lesson as shifting,
// particularly one place shifting, is a much simpler to
// implement operation than addition and therefore can be
// made faster and with less hardware than addition.
   @R2
   M=0

   @R0
   D=M
   @x
   M=D

   @R1
   D=M
   @y
   M=D
   
   @mask
   M=1
   
   @yi
   M=0
   
(LOOP)
   @yi
   D=M
   @yiminus1
   M=D		 // y_(i-1) = y_(i)
   
   @mask
   D=M
   @y
   D=M&D	// mask off the next bit
   @UNSETYI
   D;JEQ    // bit = 0?
   @yi
   M=1
   D=M
   @TEST
   0;JMP
(UNSETYI)
   @yi
   M=0
   D=M
(TEST)
   @yiminus1
   D=M-D
   @ENDLOOP
   D;JEQ      // y_(i) == y_(i-1), next
   @yiminus1
   D=M
   @SUB
   D;JEQ      // y_(i),y_(i-1) == 10, so subtract
   @x
   D=M
   @R2
   M=M+D
   @ENDLOOP
   0;JMP
(SUB)
   @x
   D=M
   @R2
   M=M-D
(ENDLOOP)
   @x
   D=M
   M=M+D      // x <<= 1 for next round

   @mask
   D=M
   M=M+D      // mask <<= 1 for next round
   D=M
   @LOOP
   D;JNE      // if mask == 0, done looping, but we still
              // might need to add x one last time if yi=1
			  // (is this really neeed? Surely x will have over
			  // flowed as well and we will just be adding 0?
(END)
   @END
   0;JMP
   