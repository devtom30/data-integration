#!/usr/bin/perl -W

use Spreadsheet::ParseExcel::Stream::XLS;
use YAML::Tiny;
use Data::Dumper;
use strict;
use DateTime;
use Log::Log4perl qw(:easy);
use utf8;
use functions;

my $usage = './<SCRIPT> <YAML_CONF_FILE>';
if ( !defined( $ARGV[0] ) ) {
	print $usage. "\n";
	exit;
}

# LOG file
my $logger = &init_log();
$logger->error('logger init');

my $conf_file = $ARGV[0];

my $yaml = YAML::Tiny->read($conf_file)
  or die "can't read conf file $conf_file : $! " . ( YAML::Tiny->errstr );
my $dd2 = Data::Dumper->new( [$yaml] );
$logger->debug( $dd2->Dump() );

my $config = $yaml->[0];

# extract
# production des fichiers
for my $config_file ( @{ $config->{files} } ) {
	&extract_file($config_file);
}



sub extract_file {
	my $config = shift;
	my $dd = Data::Dumper->new( [$config] );
	$logger->debug( $dd->Dump() );

	my $f                = $config->{datafile};
	my $cols             = $config->{cols};
	my $data_from_line   = $config->{data}->{start};
	my $data_end_line    = $config->{data}->{end};
	my $file_result_name = $config->{file_result_name};

	my $mode_human_row_check = 0;
	if ( defined $config->{human_check} ) {
		my $mode_human_row_check = 1;
		print 'human mode check ON' . "\n";
	}

	#open XLS file
	my $options = {
		'Type' => 'XLS'
	};
	my $xls = Spreadsheet::ParseExcel::Stream::XLS->new($f);    #, \%options);

	my $index       = 1;
	my $result_rows = [];

	# file for rejected lines
	open(RL, ">".$file_result_name.'_rejected_lines.txt');

	# get the first sheet
	my $sheet = $xls->sheet();

    if (not defined $sheet) {
        print 'did NOT find no sheet in file '.$f.". Does this file exist ? It seems not...\n";
        exit;
    }
    
	while ( my $row = $sheet->unformatted ) {
        my $formatted_row = $sheet->row(1);
		if ( $index > $data_end_line ) {
			close O;
			last;

			#		exit;
		}
		elsif ( $index >= $data_from_line ) {
			#		print $index. "\n";
#			print "\n";
#			print $index.') ROW : ';
#			print (join (' <<<SEP>>> ', @$row));
#			print "\n";

			# put row data in a tab
			my @tab        = @$row;
            my @formatted_tab = @$formatted_row;
            print 'DAMNED : formatted : '.(join('-',@formatted_tab))."\n";
            print 'DAMNED : unformatted : '.(join('-',@tab))."\n\n";
            
			my $result_row = [];

			my $l_result   = '';
			my $log_line   = '';
			my $write_line = 1;
			my $linekey    = 'generated_key_' . $index;
			my $val = '';

			for my $col (@$cols) {
#				$l_result .= '"';
                print 'DAMNED : '.($formatted_tab[ $col->{num} - 1 ]).' - '.($tab[ $col->{num} - 1 ])."\n";
                print 'DAMNED : '.(defined $formatted_tab[ $col->{num} - 1 ]).' - '.(defined $tab[ $col->{num} - 1 ])."\n";
				my $col_val = $tab[ $col->{num} - 1 ];
                if (
                    (defined $col->{formatted} && $col->{formatted} == 1)
                    || not ( defined $col_val)
                    || $col_val eq ''
                    || (
                        length($formatted_tab[ $col->{num} - 1 ]) >  length($tab[ $col->{num} - 1 ])
                        && !(defined $col->{formatted} && $col->{formatted} == 0)
                    )
                ) {
                   $col_val = $formatted_tab[ $col->{num} - 1 ];
                }
                print 'DAMNED : '.$col_val."\n";
                print 'DAMNED : '.(! $col_val =~ /^\s*$/)."\n";
#                my $col_val = $row;
				if ( defined $col_val 
					&& $col_val ne ''
#					&& ! $col_val =~ /^\s*$/
                    ) {
					$col_val =~ s/\n//g;
#					$col_val =~ s/\x{2dc}//g;
#					$col_val =~ s/\x{2122}//g;
					$col_val =~ s/\r//g;
#					$col_val = &functions::remove_final_dot_in_number($col_val);
#					$col_val =~ s/0\.(0+\.\d+)$/$1/;
#                    $col_val =~ s/(\d+\.\d+)\.\D*$/$1/;
					$val = $col_val;
					if ( defined $col->{pattern} ) {
						print 'pattern : ' . $val . ' => ';
						eval( '$val =~' . $col->{pattern} );
						print $val. "\n";
					}
                    if ( defined $col->{nettoyer_ean} && $col->{nettoyer_ean} == 1 ) {
                        my $val2 = &nettoyer_ean ( $val );
                        $val = $val2;
                        print 'retour nettoyer : '.$val."\n";
                    }
					if ( defined $col->{condition} ) {
						my $expr = $col->{condition};
						$expr =~ s/\$this/$val/g;
						$write_line = eval($expr);
						$log_line .=
						    'condition : ' . $expr
						  . ' evaluate to '
						  . ( $write_line ? 'true' : 'false' ) . "\n";
						if (not ($write_line)) {
							print $log_line;
						}
					}
                    if ( defined $col->{sprintf} ) {
                        
                        #my $str_to_eval = '$val = sprintf("%' . $col->{sprintf} . '", '.$val.')';
                        #my $ddcol = Data::Dumper->new([$col]);
                        #print 'col'."\n";
                        #print $ddcol->Dump;
                        #print 'eval : '.$str_to_eval."\n";
                        #eval( $str_to_eval );
                        
                        
                        print 'before sprintf : '.$val."\n";
                        my $val2 = sprintf("%013d", $val);
                        $val = $val2;
                        print 'after sprintf => '.$val."\n";
                    }
					if ( defined $col->{sortkey} && $col->{sortkey} eq 'true' )
					{
						$linekey = $val;
					}
					$l_result .= $val;				
				} else {
                    print 'DAMNED : mise à zéro'."\n";
					$val = '\N';
				}
#				$l_result .= '"';
				$l_result .= ';';
                print 'DAMNED final : '.$val."\n";
				push @$result_row, $val;
			}
			if ($write_line) {
					
                my $dd2 = Data::Dumper->new([$result_row]);
#	print $dd2->Dump;
				
				push @$result_rows, $result_row;

#				print $l_result;
				#			print "\n";
				if ($mode_human_row_check) {
					$mode_human_row_check = &type_enter_for_next();
				}
				else {
				}
			}
			else {

				# LOG
				$logger->error( "line with error : \n"
					  . ( join( ' - ', @tab ) ) . "\n"
					  . $log_line );
				print RL $l_result."\n";
			}
		}
		$index++;
        #$formatted_row = $sheet->row(1);
	}

	print "\n";

	# tri des lignes
	# determination de la colonne de tri
	my $sortkey = undef;
	my $i       = 0;
	for my $c (@$cols) {
		if ( defined $c->{sortkey} && $c->{sortkey} eq 'true' ) {
			$sortkey = $i;
			last;
		}
		$i++;
	}

	# si cle de tri trouvee, on trie le tableau
	my @rows_sorted = ();
	if ( defined $sortkey ) {
		$logger->debug( 'sort tab, sortkey is : ' . $sortkey );
		@rows_sorted =
		  sort { $a->[$sortkey] cmp $b->[$sortkey] } @$result_rows;
	}
	else {
		@rows_sorted = @$result_rows;
	}

#	# $dd = Data::Dumper->new( [$rows_sorted] );
#	my $l = "\n";
#	my $max = 10;
#	if ($index < $max) {
#		$max = $index;
#	}
#	$i = 0;
#	while ( $i < $max ) {
#		$l .= join( ',', @{ $rows_sorted[$i] } );
#		$l .= "\n";
#		$i++;
#	}
##	$logger->error($l);

	print "\n";

	# write CSV
	&write_csv( $cols, $file_result_name, \@rows_sorted );
}

sub write_csv() {
	my $cols             = shift;
	my $file_result_name = shift;
	my $rows             = shift;

	open( O, ">" . $file_result_name )
	  or die "can't open file for write <$file_result_name> : $!";

	# columns names
	for my $col (@$cols) {
#		print O '"' . $col->{name} . '";';
		print O $col->{name} . ';';
	}
	print O "\n";

	for my $row (@$rows) {
#		for my $val (@$row) {
#			print O '"' . $val . '";';
#			print O $val . ';';
#		}
		print O (join (';', @$row));
		print O "\n";
	}
}

sub type_enter_for_next() {
	print
'Type just enter for next row OR type \'a\' and enter to abort human check';
	print " \n ";
	my $var = <STDIN>;
	if ( defined $var && $var eq 'a' ) {
		print $var. " \n ";
		<STDIN>;
		return 1;
	}
	return 0;
}

sub init_log() {
	Log::Log4perl->init("log/log.conf");
	my $logger = Log::Log4perl->get_logger();
	return $logger;
}

sub nettoyer_ean {
    my $val = shift;
    
    $val =~ s/^([0-9]+)(.*)$/$1/;
    print 'dans nettoyer : '.$val."\n";
    
    return $val;
}

