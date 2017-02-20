package CodeWriter;
use strict;
use warnings;

# we are computing M op D (if the order matters)
# note that number of lines for logical comparisons is 6 and for all others is 1
my %ops = (
	add => "  D=D+M\n",
	sub => "  D=M-D\n",
	eq  => "  D=M-D\n  \@%d\n  D;JEQ\n  \@%d\n  D=0;JMP\n  D=-1\n",
	gt  => "  D=M-D\n  \@%d\n  D;JGT\n  \@%d\n  D=0;JMP\n  D=-1\n",
	lt  => "  D=M-D\n  \@%d\n  D;JLT\n  \@%d\n  D=0;JMP\n  D=-1\n",
	and => "  D=D&M\n",
	or  => "  D=D|M\n",
	neg => "  D=-D\n",
	not => "  D=!D\n"
);

# Opens the output file and gets ready to write into it.
# returns the new CodeWriter object
sub new {
	if(scalar @_ != 2) {
		die "usage: CodeWriter::new <filename>";
	}
	
	my $class = shift;
	my $filename = shift;
	
	open(my $asmfile, ">", $filename . '.asm') or die $!;
	
	# initialise member variables here
	my $self = (
		_file => $asmfile,
		# the logical comparisons need jumps to be 100% correct, so store the
		# the current line number & only increment it for a real instruction
		_line_no => 0,
		# this is needed for generating symbols for the static segment
		_basename=$filename
	);
	
	
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
	#print "got a writeArithmetic($args[0])\n"; # debug
	
	# Work out how many arguments to pop from the stack
	if($args[0] =~ /^(add|sub|and|or)$/ ) {
		# dual argument commands
		# fake 'pop' the arguments into D then M, but don't adjust SP (yet)
		print {$self->{_file}} "  \@SP\n  A=M-1\n  D=M\n  A=A-1\n";
		# perform the operation
		print {$self->{_file}} $ops{$1};
		# adjust the stack so it will come out right at the end
		print {$self->{_file}} "  \@SP\n  M=M-1\n";
		# put D on top of the stack
		print {$self->{_file}} "  A=M-1\n  M=D\n\n";

		# count up the resulting lines
		$self->{_line_no} += 9;		
	} elsif ($args[0] =~ /^(eq|gt|lt)$/) {
		# dual argument commands of the logical comparison type
		# these require some jump fuckery to work 100% correctly
		# fake 'pop' the arguments into D then M, but don't adjust SP (yet)
		print {$self->{_file}} "  \@SP\n  A=M-1\n  D=M\n  A=A-1\n";
		$self->{_line_no} += 4;
		# perform the operation
		printf {$self->{_file}} $ops{$1}, $self->{_line_no}+5,
		       $self->{_line_no}+6;
		# adjust the stack so it will come out right at the end
		print {$self->{_file}} "  \@SP\n  M=M-1\n";
		# put D on top of the stack
		print {$self->{_file}} "  A=M-1\n  M=D\n\n";

		# count up the resulting lines
		$self->{_line_no} += 10;		
		
	} elsif ($args[0] =~ /^(neg|not)$/) {
		# single argument commands
		# fake 'pop' into D, but don't adjust SP. We don't need
		# to, because we'll be pushing to it again no matter what
		print {$self->{_file}} "  \@SP\n  A=M-1\n  D=M\n";
		# do the operation
		print {$self->{_file}} $ops{$1};
		# store D into the stack
		print {$self->{_file}} "  M=D\n\n";
		$self->{_line_no} += 5;
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
	print "got a writePushPop($args[0], $args[1], $args[2])\n"; # debug
	
	if( args[1] =~ // ) {
		if( args[0] =~ /^(C_PUSH)$/ ) {
		} elsif( args[0] =~ /^(C_POP)$/ ) {
		} else {
			die
			"usage: CodeWriter::writePushPop({C_PUSH|C_POP}, segment, index)";
		}
	} elsif (args[1] =~ //) {
	} else {
		die "usage: CodeWriter::writePushPop({C_PUSH|C_POP}, segment, index)";
	}
}

sub writeComment {
	(my $self, my @args) = @_;
	if(scalar @args != 1) {
		die "usage: CodeWriter::writeComment(<string>)";
	}
	print {$self->{_file}} "// $args[0]\n"; # debug
}

# Closes the .asm output file
sub closeFile {
	(my $self, my @args) = @_;
	if(scalar @args > 0) {
		die "CodeWriter::closeFile() incorrectly passed an argument";
	}

	close($self->{_file});
}

# emit assembly commands to pop stack into D
sub _popd {
	print {$self->{file}} "  \@SP\n  M=M-1\n  A=M\n  D=M\n";
	$self->{_line_no} += 4;
}

# emit assembly commands to push D to stack
sub _pushd {
	print {$self->{file}} "  \@SP\n  A=M\n  M=D\n  \@SP\n  M=M+1\n";
	$self->{_line_no} += 5;
}

# return non zero so use works
1;