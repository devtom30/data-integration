#!/usr/bin/perl -W

use strict;
use Test::Simple;
use Merger; 
use Data::Dumper;
use YAML::Tiny;
use Cwd;

my $strlist1 = [
	'val1.1;val1.2;val1.3;'
	, 'val2.1;val2.2;val2.3;'
	, 'val3.1;val3.2;val3.3;'
];

my $strlist1_with_head = ['colonne 1;colonne 2;colonne 3;', @$strlist1];

my $strlist2 = [
	'val1.4;val1.2;val1.5;'
	, 'val2.4;val2.2;val2.5;'
	, 'val3.4;val3.2;val3.5;'
];

my $strlist2_with_head = ['colonne 4;colonne 2;colonne 5;', @$strlist2];

my $list1 = [
	[ 'colonne 1' ,'colonne 2' ,'colonne 3']
	, [ 'val1.1' ,'val1.2' ,'val1.3']
	, [ 'val2.1' ,'val2.2' ,'val2.3']
	, [ 'val3.1' ,'val3.2' ,'val3.3']
];

my $list2 = [
	[ 'colonne 4' ,'colonne 2' ,'colonne 5']
	, [ 'val1.4' ,'val1.2' ,'val1.5']
	, [ 'val2.4' ,'val2.2' ,'val2.5']
	, [ 'val3.4' ,'val3.2' ,'val3.5']
];

my $hash_merged = [
	'val1.2' => ['val1.1', 'val1.3', 'val1.4', 'val1.5']
	, 'val2.2' => ['val2.1', 'val2.3', 'val2.4', 'val2.5']
	, 'val3.2' => ['val3.1', 'val3.3', 'val3.4', 'val3.5']
];

#my $hash_computed = Merger::merge_list_rows_by_column_name($list1, $list2, 'colonne 2');

#my $dd = Data::Dumper->new([$hash_computed]);
#print $dd->Debug();

my $list1_data = Merger::prepare_data($strlist1_with_head, 1, ';');
ok (scalar (keys %{$list1_data}) == (scalar (@{$strlist1_with_head})) - 1, 'data test 1');
ok (defined $list1_data->{'val1.2'}, 'data test');
ok (scalar(@{$list1_data->{'val1.2'}}) == 2, 'data test');
ok ($list1_data->{'val1.2'}->[0] eq 'val1.1', 'data test');
ok ($list1_data->{'val1.2'}->[1] eq 'val1.3', 'data test');

my $list1_entete = Merger::prepare_entete($list1->[0], 1, ';');
ok (scalar (@{$list1_entete}) == 2, 'test for prepare entete');
ok ($list1_entete->[0] eq 'colonne 1', 'test entete');
ok ($list1_entete->[1] eq 'colonne 3', 'test entete');

my $colindex = Merger::determine_column_index_in_list($list1->[0], 'colonne 2');
ok ((defined $colindex && $colindex == 1), 'colindex is '.$colindex);

my $hash1 = Merger::list_to_hash($strlist1, ';', 1);
ok (defined ($hash1->{'val1.2'}));
ok (defined ($hash1->{'val2.2'}));
ok (defined ($hash1->{'val3.2'}));

my $dd2 = Data::Dumper->new([$hash1]);
print $dd2->Dump();
ok ($hash1->{'val1.2'}->[0] eq 'val1.1');
ok ($hash1->{'val1.2'}->[1] eq 'val1.3');
ok ($hash1->{'val2.2'}->[0] eq 'val2.1');
ok ($hash1->{'val2.2'}->[1] eq 'val2.3'); 
ok ($hash1->{'val3.2'}->[0] eq 'val3.1');
ok ($hash1->{'val3.2'}->[1] eq 'val3.3');

my $colindex1 = Merger::determine_column_index_in_list($list1->[0], 'colonne 2');
ok (defined $colindex1, 'colindex must be defined');
ok ($colindex1 == 1, 'and colindex must be 1');

my $hash = Merger::prepare_data_str($strlist1, 1);
$dd2 = Data::Dumper->new([$hash]);
print $dd2->Dump();
ok (defined $hash->{'val1.2'});
ok ($hash->{'val1.2'} eq 'val1.1;val1.3;');
ok (defined $hash->{'val2.2'});
ok ($hash->{'val2.2'} eq 'val2.1;val2.3;');
ok (defined $hash->{'val3.2'});
ok ($hash->{'val3.2'} eq 'val3.1;val3.3;');
ok (scalar(keys %$hash) == 3, 'nb keys good'); 

my $h2 = Merger::prepare_data_str($strlist2, 1);
my $h_merged = Merger::merge_data_str($hash, $h2, 2, 2);
ok (scalar(keys %$hash) == (scalar(keys %$h_merged)), 'nb keys good'); 
ok ($h_merged->{'val1.2'} eq 'val1.1;val1.3;val1.4;val1.5;');
ok ($h_merged->{'val2.2'} eq 'val2.1;val2.3;val2.4;val2.5;');
ok ($h_merged->{'val3.2'} eq 'val3.1;val3.3;val3.4;val3.5;'); 

# la partie utile pour merger les fichiers commence ici
# avant ce ne sont que des tests unitaires
# pas eu le temps de le mettre en ordre
# time is money...
my $conf_file = './conf_extract.yml';
# lecture du fichier de conf
my $yaml_config = YAML::Tiny->read($conf_file);
# lancement de la fusion (merge) numéro 1
Merger::merge_files_direct($yaml_config->[0]->{merges}->[0]);
# lancement de la fusion (merge) numéro 2
print 'second merge'."\n";
Merger::merge_files_direct($yaml_config->[0]->{merges}->[1]);
# lancement de la fusion (merge) numéro 3
print 'troisieme merge'."\n";
Merger::merge_files_direct($yaml_config->[0]->{merges}->[2]);

print '################';

# lancement des post traitements si trouvé en configuration
# plus utilisé actuellement
my $rows = Merger::do_post_traitement($yaml_config->[0], $yaml_config->[0]->{merges}->[2]->{resultfile}->{filename});
# filename
my $current_dir = getcwd();
$current_dir =~ s/^.*\/([^\/]+)$/$1/;
my $fileresult = $yaml_config->[0]->{merges}->[2]->{resultfile}->{filename};
$fileresult =~ s/\.csv$/_$current_dir\.csv/;
Merger::write_file_from_list_of_list($rows, $fileresult);

# le script s'arrête ici, le reste ne sert pas en l'état...
# time is money...
exit;

my $str = 'sdgesq;sdfgsdg;sdfgsdg;;;sdfgsd;dsfg;\n;\n;\n';
my @t = split(';', $str);
ok (scalar(@t) == 10, scalar(@t));
print $str."\n";

my @l2 = Merger::read_file_in_list($yaml_config->[0]->{merges}->[0]->{files}->[1]->{filename});
print $l2[0]."\n";
my @entete2   = split( ';', $l2[0] );
my $colindex2 = Merger::determine_column_index_in_list( \@entete2, 'Article');
print 'colindex : '.$colindex2."\n";
my $data2   = Merger::prepare_data_str( \@l2, $colindex2 );
ok (defined ($data2->{965375}), 'la clé 965375 existe');
ok (defined ($data2->{'965375'}), 'la clé \'965375\' existe');
$dd2 = Data::Dumper->new([$data2]);
#print $dd2->Dump;

my @l1 = Merger::read_file_in_list($yaml_config->[0]->{merges}->[0]->{files}->[0]->{filename});
print $l1[0]."\n";
my @entete1   = split( ';', $l1[0] );
$colindex1 = Merger::determine_column_index_in_list( \@entete1, 'Article');
print 'colindex : '.$colindex1."\n";
my $data1  = Merger::prepare_data_str( \@l1, $colindex1 );
ok (defined ($data1->{965375}), 'la clé 965375 existe');
ok (defined ($data1->{'965375'}), 'la clé \'965375\' existe');
my $hash_merged2 = Merger::merge_data_str($data1, $data2, $colindex1, $colindex2);

my $verif = {};
for (keys %$hash_merged2) {
	my $nbpv = scalar(split(';', $hash_merged2->{$_}));
	if (not( defined($verif->{$nbpv}))) {
		$verif->{$nbpv} = [];
	}
	push @{$verif->{$nbpv}}, $_;
}
print join(' - ', keys %$verif);
print "\n";

# # print 'at this point, if all tests are OK, these functions are all GOOD : determine_column_index_in_list and list_to_hash !!!'."\n";

# # my $hash = Merger::merge_list_rows_by_column_name($strlist1_with_head, $strlist2_with_head, 'colonne 2', 'colonne 2');

# ok (defined $hash->{'val1.2'});
# ok (join(';', @{$hash->{'val1.2'}}) eq 'val1.1;val1.3;val1.4;val1.5', 'must be '.join(';', @{$hash->{'val1.2'}}));
# ok (defined $hash->{'val2.2'});
# ok (join(';', @{$hash->{'val2.2'}}) eq 'val2.1;val2.3;val2.4;val2.5', 'must be '.join(';', @{$hash->{'val2.2'}}));
# ok (defined $hash->{'val3.2'});
# ok (join(';', @{$hash->{'val3.2'}}) eq 'val3.1;val3.3;val3.4;val3.5', 'must be '.join(';', @{$hash->{'val3.2'}}));
# 
# my $entete = merge_entetes($list1->[0], $list2->[0], 'colonne 2', 'colonne 2');
# ok (scalar(@$entete) == 4);
# ok ($entete->[0] eq 'colonne 1');
