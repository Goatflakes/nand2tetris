package CodeWriter;
use strict;
use warnings;
use File::Basename;

# we are computing M op D (if the order matters)
# NB: that number of lines for logical comparisons is 6 and for all others is 1
# if that changes, then the count will need to be adjusted in
# CodeWriter::writeArithmetic
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
	my ( $basename, $dir ) = fileparse($filename);

	# initialise member variables here
	my $self = {
		_file => $asmfile,
		# the logical comparisons need jumps to be 100% correct, so store the
		# the current line number & only increment it for a real instruction
		_line_no => 0,
		# this is needed for generating symbols for the static segment
		_basename=>$basename,
	};
	
	
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

# used for translating push/pop local, argument, this, and that
my %segments = (
	local    => 'LCL',
	argument => 'ARG',
	this     => 'THIS',
	that     => 'THAT',
);

# Writes to the output file the assembly code that implements the command given
# in the first argument, where that is either C_PUSH or C_POP, to the segment
# given in the second argument at the index given by the third argument.
sub writePushPop {
	(my $self, my @args) = @_;
	if(scalar @args != 3) {
		die "usage: CodeWriter::writePushPop({C_PUSH|C_POP}, segment, index)";
	}
	#print "got a writePushPop($args[0], $args[1], $args[2])\n"; # debug
	
	my $segment;
	
	if( $args[1] =~ /^(constant)$/ ) {
		#print "found push or pop constant\n"; # debug
		if( $args[0] =~ /^(C_PUSH)$/ ) {
			# print "found push constant\n"; # debug
			print {$self->{_file}} "  \@" . $args[2] . "\n  D=A\n";
			$self->{_line_no} += 2;
			$self->_pushd();
			print {$self->{_file}} "\n";
		} elsif( $args[0] =~ /^(C_POP)$/ ) {
			die "can't pop into the constant segment!";
		} else {
			die
			"usage: CodeWriter::writePushPop({C_PUSH|C_POP}, segment, index)";
		}
	} elsif ($args[1] =~ /^(local|argument|this|that)$/) {
		# print "found push or pop " . $1 . "\n"; # debug		
		if( $args[0] =~ /^(C_PUSH)$/ ) {
			#print "found push " . $args[1] . "\n"; # debug
			print {$self->{_file}} "  \@" . $segments{$args[1]}
								 . "\n  D=M\n  \@"
								 . $args[2] . "\n"
			                     . "  A=D+A\n  D=M\n";
			$self->{_line_no} += 5;
			$self->_pushd();
		} elsif( $args[0] =~ /^(C_POP)$/ ) {
			#print "found pop " . $args[1] . "\n"; # debug
			
			# Calculate the address *(segment register)+i
			$self->_instr('@' . $segments{$args[1]});
			$self->_instr('D=M');
			$self->_instr('@' . $args[2]);
			$self->_instr('D=D+A');
			
			# Store it in R15, which isn't used for anything else (hopefully..)			
			$self->_instr('@R15');
			$self->_instr('M=D');

			# pop stack into D
			$self->_popd();
			
			# store D into the location pointed to by the precomputed address
			$self->_instr('@R15');
			$self->_instr('A=M');
			$self->_instr('M=D');
			
			# zero R15 (optional, may improve security)
			#$self->_instr('@R15');			
			#$self->_instr('M=0');
		} else {
			die
			"usage: CodeWriter::writePushPop({C_PUSH|C_POP}, segment, index)";
		}
		print {$self->{_file}} "\n";
	} elsif( $args[1] =~ /^(static)$/ ) {
		#print "found push or pop static\n"; # debug
		my $varname = $self->{_basename} . '.' . $args[2];
		if( $args[0] =~ /^(C_PUSH)$/ ) {
			#print "found push static\n"; # debug
			$self->_instr("\@$varname");
			$self->_instr("D=M");
			$self->_pushd();
		} elsif( $args[0] =~ /^(C_POP)$/ ) {
			#print "found pop static\n"; # debug
			$self->_popd();
			$self->_instr("\@$varname");
			$self->_instr("M=D");
		} else {
			die
			"usage: CodeWriter::writePushPop({C_PUSH|C_POP}, segment, index)";
		}
		print {$self->{_file}} "\n";
	} elsif( $args[1] =~ /^(pointer)$/ ) {
		#print "found push or pop pointer\n"; # debug
		my $position;
		if ($args[2] == 0) {
			$position = "THIS";
		} elsif ($args[2] == 1) {
			$position = "THAT";
		} else {
			die "access of pointer segment out of range!";
		}
		if( $args[0] =~ /^(C_PUSH)$/ ) {
			#print "found push pointer\n"; # debug
			$self->_instr("\@$position");
			$self->_instr("D=M");
			$self->_pushd();
		} elsif( $args[0] =~ /^(C_POP)$/ ) {
			#print "found pop pointer\n"; # debug
			$self->_popd();
			$self->_instr("\@$position");
			$self->_instr("M=D");
		} else {
			die
			"usage: CodeWriter::writePushPop({C_PUSH|C_POP}, segment, index)";
		}
		print {$self->{_file}} "\n";
	} elsif( $args[1] =~ /^(temp)$/ ) {
		# print "found push or pop temp\n"; # debug
		($args[2] >= 0 and $args[2] < 8)
			or die "access of temp segment out of range!";
		my $position = $args[2] + 5;

		if( $args[0] =~ /^(C_PUSH)$/ ) {
			#print "found push temp\n"; # debug
			$self->_instr("\@$position");
			$self->_instr("D=M");
			$self->_pushd();
		} elsif( $args[0] =~ /^(C_POP)$/ ) {
			#print "found pop temp\n"; # debug
			$self->_popd();
			$self->_instr("\@$position");
			$self->_instr("M=D");
		} else {
			die
			"usage: CodeWriter::writePushPop({C_PUSH|C_POP}, segment, index)";
		}
		print {$self->{_file}} "\n";
	} else {
		die "usage: CodeWriter::writePushPop({C_PUSH|C_POP}, segment, index)";
	}
}

sub writeComment {
	(my $self, my @args) = @_;
	if(scalar @args != 1) {
		die "usage: CodeWriter::writeComment(<string>)";
	}
	print {$self->{_file}} "// $args[0]\n";
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
	(my $self, my @args) = @_;
	if(scalar @args > 0) {
		die "CodeWriter::_popd() incorrectly passed an argument";
	}
	
	print {$self->{_file}} "  \@SP\n  AM=M-1\n  D=M\n";
	$self->{_line_no} += 3;
}

# emit assembly commands to push D to stack
sub _pushd {
	(my $self, my @args) = @_;
	if(scalar @args > 0) {
		die "CodeWriter::_pushd() incorrectly passed an argument";
	}
	
	print {$self->{_file}} "  \@SP\n  A=M\n  M=D\n  \@SP\n  M=M+1\n";
	$self->{_line_no} += 5;
}

sub _instr {
	(my $self, my @args) = @_;
	if(scalar @args != 1) {
		die "CodeWriter::_instr() takes only one argument";
	}

	print {$self->{_file}} "  $args[0]\n";
	$self->{_line_no} += 1;
}

# return non zero so use works
1;