#!/usr/bin/perl -W

use strict;
use Test::Simple;
use Merger; 
use Data::Dumper;
use YAML::Tiny;
use functions;

my $s1 = '  .2234.324543.34543';
my $s2 = '.22 34.324543.34543   ';
my $s3 = ' 1.456e45';
my $s4 = 'sfgsd fhdds 4.5657567';
my $s5 = '4564575 456sfgsd fhdds 4.5657567';
my $s6 = '  	.456.456 ';
my $s7 = '.4.';
my $s8 = '.';	
my $s9 = '...4.  ';
my $s10 = '4.4345.';
my $s11 = '   .34.45.56.6.6.';

ok (&functions::is_number($s1));
ok (not &functions::is_number($s2));
ok (not &functions::is_number($s3));
ok (not &functions::is_number($s4));
ok (not &functions::is_number($s5));
ok (&functions::is_number($s6));
ok (&functions::is_number($s7));
ok (&functions::is_number($s8));
ok (not &functions::is_number($s9));
ok (&functions::is_number($s10));
ok (&functions::is_number($s11));

my $s7p = &functions::remove_final_dot_in_number($s7);
ok ($s7p eq '.4', '$s7p is '.$s7p);
my $s11p = &functions::remove_final_dot_in_number($s11);
ok ($s11p eq '.34.45.56.6.6', '$s7p is '.$s11p);
my $s6p = &functions::remove_final_dot_in_number($s6);
ok ($s6p eq '.456.456', '$s7p is <'.$s6p.'>');

