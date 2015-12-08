package Merger;

use strict;
use List::MoreUtils qw(firstidx);
use functions;
use Data::Dumper;

sub prepare_data {
	my $strlist  = shift;
	my $colindex = shift;
	my $sep      = shift;

	my $hash        = {};
	my @strlistdata = @{$strlist}[ 1 .. $#{$strlist} ];
	for my $row (@strlistdata) {
		my @row      = split( $sep, $row );
		my $keyindex = $colindex;

		# cle
		my $key = $row[$keyindex];

		# on l'enleve de la liste
		my @row_truncated =
		  @row[ 0 .. ( $keyindex - 1 ), ( $keyindex + 1 ) .. $#row ];
		$hash->{$key} = \@row_truncated;
	}

	return $hash;
}

sub prepare_entete {
	my $row_entete = shift;
	my $colindex   = shift;

	my $entete = [];
	my @tab    = @$row_entete;
	@{$entete} = @tab[ 0 .. ( $colindex - 1 ), ( $colindex + 1 ) .. $#tab ];

	return $entete;
}

sub merge_files {
	my $config = shift;

	my $mergeconf = $config;
	my @t         = reverse @{ $mergeconf->{files} };
	my $fileconf1 = pop(@t);
	my @list1     = read_file_in_list( $fileconf1->{filename} );
	my @entete1   = split( ';', $list1[0] );
	my $colindex1 =
	  determine_column_index_in_list( \@entete1, $fileconf1->{column_name} );
	my $list1_data   = prepare_data( \@list1,   $colindex1, ';' );
	my $list1_entete = prepare_entete( \@list1, $colindex1, ';' );

	while ( my $fileconf2 = pop @{ $mergeconf->{files} } ) {
		my @list2     = read_file_in_list( $fileconf2->{filename} );
		my @entete2   = split( ';', $list2[0] );
		my $colindex2 =
		  determine_column_index_in_list( \@entete2,
			$fileconf2->{column_name} );

		my $list2_data   = prepare_data( \@list2,   $colindex1, ';' );
		my $list2_entete = prepare_entete( \@list2, $colindex1, ';' );

		my $entete = [ @{$list1_entete}, @{$list2_entete} ];
		my $data = merge_data( $list1_data, $list2_data );

		$list1_data   = $data;
		$list1_entete = $entete;
	}
}

# permet de fusionner deux fichiers selon la valeur d'une colonne
# par exemple : EAN
# la fonction reçoit la structure de configuration en paramètre
sub merge_files_direct {
	# paramètre 1 : la structure avec la configuration
	my $config = shift;

	my @t         = reverse @{ $config->{files} };
	my $fileconf1 = pop @t;
	my @list1     = read_file_in_list( $fileconf1->{filename} );
	my @entete1   = split( ';', $list1[0] );
	my $colindex1 =
	  determine_column_index_in_list( \@entete1, $fileconf1->{colname} );

	# on prélève les valeurs sauf la colonne de pivot (qui sert à déterminer quelle ligne correspond à telle ligne)
	@list1 = @list1[ 1 .. $#list1 ];
	# on prépare les données
	my $data1   = prepare_data_str( \@list1, $colindex1 );
	# on prépare les entêtes
	my $entete1 = prepare_entete( \@entete1, $colindex1 );

	while ( my $fileconf2 = pop @t ) {
		my @list2     = read_file_in_list( $fileconf2->{filename} );
		my @entete2   = split( ';', $list2[0] );
		my $colindex2 =
		  determine_column_index_in_list( \@entete2, $fileconf2->{colname} );
		@list2 = @list2[ 1 .. $#list2 ];
		my $data2   = prepare_data_str( \@list2, $colindex2 );
		my $entete2 = prepare_entete( \@entete2, $colindex2 );

		my $entete_merged = merge_entete( $entete1, $entete2 );
		my $data_merged   =

		  #		  merge_data_str( $data1, $data2, $#{$entete1}, $#{$entete2} );
		  merge_data_str(
			$data1, $data2,
			scalar( @{$entete1} ),
			scalar( @{$entete2} )
		  );

		$data1   = $data_merged;
		$entete1 = $entete_merged;
	}

	# création du tableau final qui est le résultat de la fusion
	my $final_tab = create_final_tab( $fileconf1->{colname}, $entete1, $data1 );

	# écrit le fichier final, résultat de la fusion des deux fichiers
	write_file_from_data_list( $final_tab, $config->{resultfile}->{filename} );
}

sub do_post_traitement {
	my $config = shift;
	my $file   = shift;

	if ( defined( $config->{posttraitement} )
		&& ( defined( $config->{'posttraitement'}->{'placements'} ) ) ) {
print 'conf OK';

		open( F, $file ) or die "can't open file : $!";
		my $entete = <F>;
		$entete =~ s/\r\n//;
		chomp $entete;
		my @entete = split( /;/, $entete );
		my $temp_rows = [];
		my $new_entete = [];
		my $rows = [];
		while ( my $line = <F> ) {
			$line =~ s/\r\n//;
			chomp $line;
			my @row = split( /;/, $line );
			my $new_row = \@row;
			$new_entete = \@entete;
			# pour chaque placement
			for my $placement ( @{ $config->{posttraitement}->{placements} } ) {
				my $indexOld = firstidx { $_ eq $placement->{name} } @$new_entete;
				my $indexNew = $placement->{index} - 1;
				$new_entete = &functions::move_value_at_index( $indexOld, $indexNew, $new_entete );
				$new_row = &functions::move_value_at_index( $indexOld, $indexNew, $new_row );
			}
			push @$temp_rows, $new_row;
		}
		push @$rows, $new_entete, @$temp_rows;
		return $rows;
	}
	return undef;
}

sub create_final_tab {
	my $colname = shift;
	my $entete1 = shift;
	my $data1   = shift;

	my $list = [];
	$list->[0] = $colname . ';' . ( join( ';', @$entete1 ) );
	my @sorted_keys = sort { $a cmp $b } keys %$data1;
	for my $k (@sorted_keys) {
		my $newk = $k;
		if ( $k =~ /^COLONNEVIDE_/ ) {
			$newk = ' ';
		}
		push @$list, $newk . ';' . $data1->{$k};
	}
	return $list;
}

sub write_file_from_data_list {
	my $list     = shift;
	my $filename = shift;

	open( O, ">" . $filename )
	  or die "can't open file for write <" . $filename . "> : $!";
	for my $l (@$list) {
		print O $l . "\n";
	}
	close O;
}

sub write_file_from_list_of_list {
	my $list     = shift;
	my $filename = shift;

	open( O, ">". $filename);
	for my $l (@$list) {
		
		print O (join(';', @$l)).';';
		print O "\n";
	}
	close O;
}

sub prepare_data_str {
	my $data  = shift;
	my $index = shift;

	my $hash = {};
	my $i    = 1;
	for my $row (@$data) {
		my @row = split( ';', $row );
		my @row_truncated =
		  @row[ 0 .. ( $index - 1 ), ( $index + 1 ) .. $#row ];
		my $key = $row[$index];
		if ( not( defined $key ) || $key eq '' ) {
			$key = 'COLONNEVIDE_' . ($i);
			print 'COLONNEVIDE_  ' . $key . ' : '
			  . ( join( ';', @row_truncated ) . ';' ) . "\n";
		}
		$hash->{$key} = ( join( ';', @row_truncated ) . ';' );
		$i++;
	}

	return $hash;
}

sub merge_data_str {
	my $h1      = shift;
	my $h2      = shift;
	my $nb_col1 = shift;
	my $nb_col2 = shift;

	open( LOG, ">>" . 'merger.log' );
	print LOG ( "\n" . 'MERGE de la mort : ' . "\n" );
	my $hash = {};
	for my $k ( keys %{$h1} ) {
		my $str_sep     = '';
		my $line_merged = '';
		if ( $h1->{$k} =~ /;\s*$/ ) {

		}
		else {
			$str_sep = ';';
		}
		$line_merged = $h1->{$k} . $str_sep;
		print 'COMPARAISON $h1 $h2 : ' . "\n";
		print 'h1 : ' . $h1->{$k} . "\n";

#		my $k_without_zeros_beginning = &functions::removeZerosBeginning($k);
#		if ( (not (defined($h2->{$k}))) && (not ( defined($h2->{$k_without_zeros_beginning})))) {
		if ( ( not( defined( $h2->{$k} ) ) ) ) {

	#			print 'h2 : '.$k.' and '.$k_without_zeros_beginning.' not defined'."\n";
			print 'h2 : ' . $k . ' not defined' . "\n";
		}
		else {
			print 'h2 : ' . $h2->{$k} . "\n";

			#			print 'h2 : '.$h2->{$k_without_zeros_beginning}."\n";
		}
		if ( defined $h2->{$k} ) {
			$line_merged .= $h2->{$k};
			print LOG 'ok key ' . $k . '(' . $nb_col1 . ' - ' . $nb_col2
			  . ') : h1 -> '
			  . $h1->{$k} . "\n";

#		} elsif ( defined $h2->{$k_without_zeros_beginning}) {
#			$line_merged .= $h2->{$k_without_zeros_beginning};
#			print LOG 'ok key '.$k_without_zeros_beginning.'('.$nb_col1.' - '.$nb_col2.') : h1 -> '.$h1->{$k}."\n";
		}
		else {
			print LOG 'ko key ' . $k . '(' . $nb_col1 . ' - ' . $nb_col2
			  . ') : '
			  . $h1->{$k} . "\n";
			print LOG 'ajout des colonnes vides : ' . $nb_col2
			  . ' colonnes' . "\n";
			my $i  = 0;
			my $l2 = '';
			while ( $i < $nb_col2 ) {
				$l2 .= '\N;';
				$i++;
			}
			$line_merged .= $l2;
		}
		$hash->{$k} = $line_merged;
	}
	return $hash;
}

sub merge_data {
	my $hash1 = shift;
	my $hash2 = shift;

	my $hash             = $hash1;
	my @verif_keys_hash2 = keys %$hash2;
	for my $k ( keys %{$hash1} ) {
		if ( not( defined $hash->{$k} ) ) {
			$hash->{$k} = $hash2->{$k};
		}
		else {
			push @{ $hash->{$k} }, @{ $hash2->{$k} };
		}
	}
}

sub merge_entete {
	my $tab1 = shift;
	my $tab2 = shift;

	my $entete_merged = [];
	@$entete_merged = ( @$tab1, @$tab2 );
	return $entete_merged;
}

sub merge_entetes {
	my $tab1 = shift;
	my $tab2 = shift;
	my $cn1  = shift;
	my $cn2  = shift;

	my $entete = [];
	for my $cn ($tab1) {
		unless ( not( defined($cn) ) || $cn eq '' || $cn eq $cn1 ) {
			push @$entete, $cn;
		}
	}
	for my $cn ($tab2) {
		unless ( not( defined($cn) ) || $cn eq '' || $cn eq $cn2 ) {
			push @$entete, $cn;
		}
	}

	return $entete;
}

sub merge_list_rows_by_column_name {
	my $list1     = shift;
	my $list2     = shift;
	my $colindex1 = shift;
	my $colindex2 = shift;

	# determination du numero de la colonne
	my @colnums = ();

	my $hash1 = list_to_hash( $list1, ';', $colindex1 );
	my $hash2 = list_to_hash( $list2, ';', $colindex2 );

	my $hash_merged   = $hash1;
	my $hash_to_merge = $hash2;
	for my $k ( keys %$hash1 ) {
		if ( defined $hash2->{$k} ) {
			push @{ $hash_merged->{$k} }, @{ $hash2->{$k} };
			delete $hash2->{$k};
		}
		else {

			# nothing to merge
			delete $hash1->{$k};
		}
	}

	return $hash_merged;
}

sub read_file_in_list {
	my $filename = shift;

	open( F1, $filename ) or die "can't open file " . ($filename) . " : $!";
	my @file1_lines = ();
	while ( my $l = <F1> ) {
		chomp $l;
		push @file1_lines, $l;
	}
	return @file1_lines;
}

sub determine_column_index_in_list {
	my $list    = shift;
	my $colname = shift;

	my $colindex = undef;
	my $i        = 0;
	for my $c ( @{$list} ) {
		$c =~ s/^"|"$//g;
		if ( $c eq $colname ) {
			$colindex = $i;
			last;
		}
		$i++;
	}

	return $colindex;
}

sub list_to_hash {
	my $list     = shift;
	my $sep      = shift;
	my $colindex = shift;

	my $hash = {};
	for my $row (@$list) {
		if ( not( defined $row ) || $row eq '' ) {
			next;
		}
		$row =~ s/\Q$sep\E$//;
		my @row      = split( $sep, $row );
		my $keyindex = $colindex;

		# cle
		my $key = $row[$keyindex];

		# on l'enleve de la liste
		my @row_truncated =
		  @row[ 0 .. ( $keyindex - 1 ), ( $keyindex + 1 ) .. $#row ];
		$hash->{$key} = \@row_truncated;
	}
	return $hash;
}

1;
