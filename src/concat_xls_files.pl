#!/usr/bin/perl -W

use strict;
# use Spreadsheet::ParseExcel::Stream::XLS;
use Spreadsheet::ParseExcel;
use Spreadsheet::WriteExcel;
use YAML::Tiny;
use Data::Dumper;
use DateTime;
use Log::Log4perl qw(:easy);
use utf8;

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
    my $dd2 = Data::Dumper->new( [ $hashFile ] );
    print $dd2->Dump;
    &concatFiles($hashFile, $filesDir);
}


sub concatFiles {
    my $hash = shift;
    my $filesDir = shift;

#    my $dd = Data::Dumper->new([$hash]);
#    print $dd->Dump; 

    my $output_file = $filesDir . '/' . $hash->{'output'};
# création du nouveau fichier
    my $wb  = Spreadsheet::WriteExcel->new ( $output_file );
    my $ws = $wb->add_worksheet();
    
    my $filesToConcat = $hash->{files_to_concat};

    my $offsetRow = 0;
    my $indexWriteRow = 0;
    for my $f ( @{$filesToConcat} ) {

	my $fName = $f->{name};
	my $fPath = $filesDir . '/' . $fName;
	my $start = $f->{start};
	my $end = $f->{end};

	print 'file ' . $fPath . "\n";
	print 'offset : ' . $offsetRow . "\n";

	sub cell_handler {
	    
	    my $workbook    = $_[0];
	    my $sheet_index = $_[1];
	    my $row         = $_[2];
	    my $col         = $_[3];
	    my $cell        = $_[4];
	    
	    # Skip some worksheets and rows (more efficiently).
	    if ( $row < $start 
		|| $row > $end) {
		print 'next ' . $row . ' - ' . $col . ' (start ' . $start . ' - end ' . $end . ')' . "\n";
	    } else {
		
		# Do something with the formatted cell value
		# print ' writing now ' . $cell->value(), "\n";
		
		$indexWriteRow = $row + $offsetRow;
		$ws->write($indexWriteRow, $col, $cell->value());
	    }
	}

	my $parser = Spreadsheet::ParseExcel->new(
	    CellHandler => \&cell_handler,
	    NotSetCell  => 1
	);
	
	$parser->parse($fPath);
	
	$offsetRow = $indexWriteRow;
    }
 
}
