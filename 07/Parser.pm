package Parser;
use strict;
use warnings;
#use Data::Dumper; #debug
use File::Temp 'tempfile';


# Opens the input file and gets ready to parse it.
sub new {
	if(scalar @_ != 2) {
		die "usage: Parser->new <filename>";
	}

	my $class = shift;
	my $filename_vm = shift;
	
	# try to open the input .vm file
	open(my $vmfile, "<", $filename_vm) or die $!;
	# close it cause we don't really need it, we just needed to check
	close ( $vmfile ) or die $!;

	# Create a temporary file for storing the comment stripped file
	(my $input, my $filename_stripped) = tempfile() or die $!;

	# Pass the original .vm file to the C Preprocessor to strip comments.
	# because C style comments are a pain in the arse
	# -P removes line numbers in cpp output
	# 'and die' is used cause system returns 0 on success	
	system ( "cpp $filename_vm -P -o $filename_stripped" ) and die $!;

	# Open the stripped vm language file to translate
	open ( $input, "<", $filename_stripped ) or die $!;

	my $self = {_file => $input, _filename => $filename_stripped};
	
	# initialise member variables here
	
	bless ($self, $class);
	return $self;
}

# Are there more commands in the input?
# Sets up the current command and returns true if that makes sense
# No arguments.
# TODO: we need to strip comments
sub hasMoreCommands {
	my ($self, @args) = @_;
	if(scalar @args > 0) {
		die "Parser::hasMoreCommands() incorrectly passed an argument";
	}
	if (eof($self->{_file})) {
		# no more input
		return(0);
	} else {
		return(1);
	}
}

# Read the next command from the input and makes it the current command.
# Should only be called if hasMoreCommands() is true.
# Initially there is no current command.
# No arguments.
sub advance {
	my ($self, @args) = @_;

	if(scalar @args > 0) {
		die "Parser::advance() incorrectly passed an argument";
	}
	
	# trying to use the <> operator here gives a syntax error
	my $line = readline($self->{_file});
	$self->{_nextCommand} = $line;
}

# Returns a constant representing the type of the current command.
# C_ARITHMETIC is returned for all the arithmetic/logical commands.
# Valid return types are C_ARITHMETIC, C_PUSH, C_POP, C_LABEL, C_GOTO, C_IF,
# C_FUNCTION, C_RETURN, and C_CALL.
# No arguments.
sub commandType {

	my ($self, @args) = @_;

	if(scalar @args > 0) {
		die "Parser::commandType() incorrectly passed an argument";
	}
	
}

# Returns the first argument of the current command. In the case of
# C_ARITHMETIC, the command itself (add, sub, etc.) is returned.
# Should not be called if the current command is C_RETURN.
# No arguments.
sub arg1 {
	my ($self, @args) = @_;
	if(scalar @args > 0) {
		die "Parser::arg1() incorrectly passed an argument";
	}
	
}

# Returns the second argument of the current command. Should be called only if
# the current command is C_PUSH, C_POP, C_FUNCTION, or C_CALL.
# No arguments.
sub arg2 {
	my ($self, @args) = @_;
	if(scalar @args > 0) {
		die "Parser::arg2() incorrectly passed an argument";
	}
	
}

# closes the .vm file
sub closeFile {
	my ($self, @args) = @_;
	if(scalar @args > 0) {
		die "Parser::closeFile() incorrectly passed an argument";
	}

	close($self->{_file});
	unlink($self->{_filename});
}

# Prints the current line the parser is on for debugging purposes

sub printCmd {
	my ($self, @args) = @_;
	if(scalar @args > 0) {
		die "Parser::printCmd() incorrectly passed an argument";
	}
	
	print "$self->{_nextCommand}";
}
# return non zero so use works
1;