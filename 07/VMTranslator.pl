#!/usr/bin/env perl

use strict;
use warnings;

use Parser;
use CodeWriter;

my $parser = Parser->new( $ARGV[0] );
my $writer = CodeWriter->new( $ARGV[0] );

while($parser->hasMoreCommands()) {
	$parser->advance();
	# $parser->printCmd(); # debug
	$writer->writeComment($parser->getCmd());
	if($parser->commandType() eq 'C_ARITHMETIC') {
		$writer->writeArithmetic($parser->arg1());
	} elsif ($parser->commandType() =~ /(C_PUSH|C_POP)/) {
		$writer->writePushPop(
			$parser->commandType(),
			$parser->arg1(),
			$parser->arg2()
		);
	} else {
		die "Unknown command type!\n";
	}
}

$parser->closeFile();
$writer->closeFile();