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
	$parser->printCmd();
}

$parser->closeFile();
$writer->closeFile();