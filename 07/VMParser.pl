#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use Parser;
use CodeWriter;
use Data::Dumper;

my ( $file_base, $dir, $suffix ) = fileparse($ARGV[0], ('.vm'));

my $parser = Parser->new( $ARGV[0] );
my $writer = CodeWriter->new( $file_base . ".asm" );

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