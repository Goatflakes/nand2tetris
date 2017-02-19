package CodeWriter;
use Strict;
use Warnings;

# Opens the output file and gets ready to write into it.
# TODO: Needs to have the .asm output file as an argument
# returns the new CodeWriter object
sub new {
	my $class = shift;
	my $self = {};
	
	# initialise member variables here
	
	bless ($self, $class);
	return $self;
}

# Writes to the output file the assembly code that implements the arithmetic
# command named as the first argument
sub writeArithmetic {
	
}

# Writes to the output file the assembly code that implements the command given
# in the first argument, where that is either C_PUSH or C_POP, to the segment
# given in the second argument at the index given by the third argument.
sub writePushPop {
	
}

# Closes the .asm output file
sub close {
	
}
# return non zero so use works
1;