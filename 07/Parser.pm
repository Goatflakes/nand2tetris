package Parser;
use Strict;
use Warnings;

# TODO: this needs to have an argument that tells it what input file to use
# Opens the input file and gets ready to parse it.
sub new {
	my $class = shift;
	my $self = {};
	
	# initialise member variables here
	
	bless ($self, $class);
	return $self;
}

# Are there more commands in the input?
# No arguments.
sub hasMoreCommands {
	
}

# Read the next command from the input and makes it the current command.
# Should only be called if hasMoreCommands() is true.
# Initially there is no current command.
# No arguments.
sub advance {
	
}

# Returns a constant representing the type of the current command.
# C_ARITHMETIC is returned for all the arithmetic/logical commands.
# Valid return types are C_ARITHMETIC, C_PUSH, C_POP, C_LABEL, C_GOTO, C_IF,
# C_FUNCTION, C_RETURN, and C_CALL.
# No arguments.
sub commandType {
	
}

# Returns the first argument of the current command. In the case of
# C_ARITHMETIC, the command itself (add, sub, etc.) is returned.
# Should not be called if the current command is C_RETURN.
# No arguments.
sub arg1 {
	
}

# Returns the second argument of the current command. Should be called only if
# the current command is C_PUSH, C_POP, C_FUNCTION, or C_CALL.
# No arguments.
sub arg2 {
	
}

# return non zero so use works
1;