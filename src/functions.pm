package functions;

use Data::Dumper;

sub remove_final_dot_in_number {
	my $str = shift;
	
	if (&is_number($str)) {
		$str =~ s/^\s*((?:- ?)?\d*(?:\.\d+)*\D?)\s*$/$1/;
		$str =~ s/\.?\D$//;
	}
	
	return $str;
}

sub is_number {
	my $str = shift;
	
	return ($str =~ /^\s*((?:- ?)?\d*(?:\.\d+)*\D?)\s*$/);
}

sub move_value_at_index {
	my $indexOld = shift;
	my $indexNew = shift;
	my $data = shift;
	
	#my @data = @$data;
	my @new_data = ();
	if (defined $data->[$indexOld]) {
		$value = $data->[$indexOld];
		my @temp_data = ();
		push @temp_data, @$data[0..($indexOld-1)], @$data[($indexOld+1)..$#{$data}];
		push @new_data, @temp_data[0..($indexNew-1)], $value, @temp_data[($indexNew)..$#temp_data];
	}
	
	return \@new_data;
}

sub move_value_at_index_in_csv_row_list {
	my $indexOld = shift;
	my $indexNew = shift;
	my $rows = shift;
	
	$rows_new = [];
	for $row (@$rows) {
		@row = &row_to_list($row);
		my $row_new = &move_value_at_index($indexOld, $indexNew, \@row);
		push(@$rows_new, (join (';', @$row_new)).';');
	}
	
	return $rows_new;
}
 
sub row_to_list {
	my $row = shift;
	
	return split /;/, $row;
}

sub removeZerosBeginning {
	my $str = shift;
	
	$str =~ s/^0*//;
	
	return $str;
}
 
1;