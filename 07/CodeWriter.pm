package CodeWriter;
use strict;
use warnings;

# now, is this filehandle a class or object variable?

# Opens the output file and gets ready to write into it.
# TODO: Needs to have the .asm output file as an argument
# returns the new CodeWriter object
sub new {
	if(scalar @_ != 2) {
		die "usage: CodeWriter::new <filename>";
	}
	
	my $class = shift;
	my $filename = shift;
	
	open(my $asmfile, ">", $filename) or die $!;
	
	my $self = {_file => $asmfile,};
	
	# initialise member variables here
	
	bless ($self, $class);
	return $self;
}

# Writes to the output file the assembly code that implements the arithmetic
# command named as the first argument
sub writeArithmetic {
	(my $self, my @args) = @_;
	if(scalar @args != 1) {
		die "usage: CodeWriter::writeArithmetic(<command>)";
	}
}

# Writes to the output file the assembly code that implements the command given
# in the first argument, where that is either C_PUSH or C_POP, to the segment
# given in the second argument at the index given by the third argument.
sub writePushPop {
	(my $self, my @args) = @_;
	if(scalar @args != 3) {
		die "usage: CodeWriter::writePushPop({C_PUSH|C_POP}, segment, index)";
	}	
}

# Closes the .asm output file
sub closeFile {
	(my $self, my @args) = @_;
	if(scalar @args > 0) {
		die "CodeWriter::closeFile() incorrectly passed an argument";
	}

	close($self->{_file});
}

# return non zero so use works
1;