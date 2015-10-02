#!/usr/bin/perl -W

use strict;
# use Spreadsheet::ParseExcel::Stream::XLS;
use Spreadsheet::ParseExcel;
use Spreadsheet::WriteExcel;
# use Excel::Writer::XLSX;
use YAML::Tiny;
use Data::Dumper;
$Data::Dumper::Deparse = 1;
use DateTime;
use Log::Log4perl qw(:easy);
use utf8;

our $offset = 0;

my $usage  = './concat_xls_files.pl <YAML_CONF> <FILES_DIR>';
if ( !( defined ( $ARGV[0] ))
    || !( defined ( $ARGV[1] ))) {
    print $usage . "\n";
    exit;
}

my $conf_file = $ARGV[0];
my $filesDir = $ARGV[1];

my $yaml = YAML::Tiny->read($conf_file)
  or die "can't read conf file $conf_file : $! " . ( YAML::Tiny->errstr );

my $config = $yaml->[0];
my $dd = Data::Dumper->new([$config]);
# print $dd->Dump;

my $allFiles = $config->{files};
for my $hashFile (@{$allFiles}) {
    my $output_file = $filesDir . '/' . $hashFile->{'output'};
    
# ouverture du fichier excel pour écriture
    my $wb = Spreadsheet::WriteExcel->new( $output_file );
#	my $wb  = Spreadsheet::WriteExcel->new ( $output_file );
    
#    my @written_sheets = $wb->sheets();
#    print 'sheets : '.scalar ( @written_sheets ) . "\n";
#my $dd5 = Data::Dumper->new([@written_sheets]);
#print $dd5->Dump . "\n";
# next;
    
#    my $ws = $wb->sheets(0);
#    if ( ! defined ( $ws ) ) {
#	print '$ws not defined' . "\n";
#	$ws = $wb->add_worksheet();
#    }
    my $ws = $wb->add_worksheet();

    my $dd2 = Data::Dumper->new( [ $hashFile ] );
    print $dd2->Dump;
    &concatFiles($hashFile, $filesDir, $ws, $output_file);
}


sub concatFiles {
    my $hash = shift;
    my $filesDir = shift;
    my $ws = shift;
    my $output_file = shift;

#    my $dd = Data::Dumper->new([$hash]);
#    print $dd->Dump; 
    
    my $filesToConcat = $hash->{files_to_concat};

    my $offsetRow = 0;
    my $indexWriteRow = 0;
    for my $f ( @{$filesToConcat} ) {

	my $fName = $f->{name};
	my $fPath = $filesDir . '/' . $fName;
	my $start = $f->{start};
	my $end = $f->{end};

	my $max = 0;
	my $min = 0;
	if (-f $output_file) {
	    my $parser_for_written_workbook = Spreadsheet::ParseExcel->new();
	    my $written_wk = $parser_for_written_workbook->parse($output_file);
	    if ( ! defined ( $written_wk ) ) {
		print $parser_for_written_workbook->error();
		print "\n";
	    } else {
		my $written_ws = $written_wk->worksheet(0);
		($min, $max) = $written_ws->row_range();
	    }
	}

	$max = $offset;
#	my ($min, $max) = $ws->row_range();
	print 'min : ' . $min . ' - max : ' . $max . "\n";
	
	print '\makeCellHandler ( ' . $start . ', ' . $end . ', ' . $ws . ', ' . $max . ' );' . "\n";
	my $cellHandler = \makeCellHandler ( $start, $end, $ws, $max );
	my $dd3 = Data::Dumper->new ( [ $cellHandler ] ); 
#	print '$cellHandler : ' . $$cellHandler . "\n";
#	print $dd3->Dump;
#	print "\n";

	print 'file ' . $fPath . "\n";
	print 'offset : ' . $offsetRow . "\n";

	my $parser = Spreadsheet::ParseExcel->new(
	    CellHandler => $$cellHandler,
	    # CellHandler => \&testHandler,
	    NotSetCell  => 1
	);
	
	$parser->parse($fPath);
	
	# close the excel file written
#	$wb->close();
	
    }
 
}

sub makeCellHandler {
    my $start = shift;
    my $end = shift;
    # the worksheet object to write into
    my $ws = shift;
    # the offset 
    my $offsetRow = shift;

    my $func = sub {
	# my $dd4 = Data::Dumper->new( [ $_ ] );
	# print $dd4->Dump;
	
	my $workbook    = $_[0];
	my $sheet_index = $_[1];
	my $row         = $_[2];
	my $col         = $_[3];
	my $cell        = $_[4];
	
#	print 'cool rasta : ' . $row . ' - ' . $col . "\n";
#	print 'start : ' . $start . ' offsetRow : ' . $offsetRow . "\n";
#	print 'cellValue : ' . $cell->value() . "\n";

	# Skip some worksheets and rows (more efficiently).
	if ( $row < ( $start ) ) {
#	    $offset--;
	} elsif ($row > ( $end ) ) {
#	    print 'next ' . $row . ' - ' . $col . ' (start ' . $start . ' - end ' . $end . ')' . "\n";
	    
	} else {
	    
	    # Do something with the formatted cell value
	    # print ' writing now ' . $cell->value(), "\n";
	    
	    my $indexWriteRow = $row + $offsetRow - $start;
#	    print 'ws : ' . $ws . "\n";
	    $ws->write($indexWriteRow, $col, $cell->value());
	    $offset = $indexWriteRow + 1;
	}
    };

#    print 'ready to return ' . $func . "\n";

    return  $func;
}

sub testHandler {
    my $workbook    = $_[0];
    my $sheet_index = $_[1];
    my $row         = $_[2];
    my $col         = $_[3];
    my $cell        = $_[4];
    
    print 'cool rasta : ' . $row . ' - ' . $col . "\n";
}
