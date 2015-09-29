#!/usr/bin/perl -W

use YAML::Tiny;
use Data::Dumper;
use strict;
use DateTime;
use utf8;
use functions;

my $usage = './<SCRIPT> <CSV_FILE> <COLS>';
if ( !defined( $ARGV[0]) 
     || !defined( $ARGV[1]) ) {
	print $usage. "\n";
	exit;
}

my $file = $ARGV[0];
my $cols_param = $ARGV[1];
my @cols_tab = ();
if ($cols_param =~ /^(\d+)-(\d*)$/) {
    if (defined $2 
	&& $2 ne '') {
	@cols_tab = ($1 .. $2);
    } else {
	@cols_tab = ($1, 'until the end');
    }
} else {
    print 'give COLS param as <START_COL>-<END_COL>'."\n";
    exit;
}

if (scalar(@cols_tab) == 0) {
    print 'no cols index in param'."\n";
    exit;
}

open(F, $file) or die "can't open file ".$file." : $!";
open(O, ">".$file.'_extracted.csv') or die "can't open file for write : $!";
while (my $l = <F>) {
    chomp $l;
    my @l_cols = split /;/, $l;
    my $new_l = '';
    my $current_i = 0;
    for my $i (@cols_tab) {
	if ($i eq 'until the end') {
	    $current_i++;
	    if (defined ($l_cols[$current_i])) {
		$new_l .= join ';', @l_cols[$current_i .. $#l_cols];
	    } else {
		last;
	    }
	} else {
	    if (defined ($l_cols[$i])) {
		$current_i = $i;
		$new_l .= $l_cols[$current_i];
		$new_l .= ';';
	    } else {
		last;
	    }
	}
    }
    print O $new_l;
    print O "\n";
}


