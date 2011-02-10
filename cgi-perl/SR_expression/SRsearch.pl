#!/usr/bin/perl -w
use strict;
use CGI qw/:standard *table :html3/;
use DBI;
use Time::Format qw(%time);
use ElegansSubs;

=head1 SRsearch.pl

Script for searching and displaying GFP gene expression information. 

	$Author: tharris $
	$Date: 2010-01-25 15:35:54 $
	$Id: SRsearch.pl,v 1.1.1.1 2010-01-25 15:35:54 tharris Exp $

Basical behavior: allow users to search and display. Searchable entities: cosmid_id, 
cgc_id and strain_id
 
=cut

print header;

print
      start_html(-title=>"GFP::Chemosensory Genes in C. elegans",
                 -author=>'chenn@cshl.edu',
                 -meta=>{'copyright'=>'Copyright 2005'},
                 -BGCOLOR=>'White'
                ),

      h1({-style=>'Color: blue;font-size: 200%;font-family: sans-serif', -align=>'center'}, "Chemosensory Gene Expression Data Resource"), q(<a href="http://dev.wormbase.org/SR_expression">Home</a>), hr,
      h2({-style=>'Color: blue;font-size: 150%;font-family: sans-serif'}, "<b>Search and Display</b>");

print start_form(-name 		=> 'form1');

my $dbh = connect_to_database();

#print out the search form
search_form();

#collect all strains that need to be displayed
my $result_ids_ref = collect_strain_IDs($dbh);
my @result_ids = @{$result_ids_ref};

#sarch and display detail observation
if (@result_ids){
  print_detail_display($result_ids_ref, $dbh);
}

print_bottom();
print end_form;
$dbh->disconnect();

#####################
#SUBROUTEINES
#####################

sub print_bottom{
  print br, br, hr;
  print q(Send comment to <a href="mailto:chenn@cshl.edu">chenn@cshl.edu</a>);
}

sub search_form{

  my @search_items = ('Cosmid names', 'CGC names', 'Strain names');
  my @data_types   = ('Gross Observations', 'Detail Observations');

  print p('Use wild cards: "%" for everything, "_" for one character.');

  print " <b>Search </b> ",popup_menu(-name => 'search_item',
                              -values=>\@search_items,
                              -default=>$search_items[0] || 'NA'), 
  #" <b>for</b> ", popup_menu(-name => 'data_type',
  #                    -values=>\@data_types,
  #                    -default=>$data_types[0] || 'NA'), 
  " <b>that match </b> ", textfield(-name => 'match', -size => '20', -force => 0);
}

sub collect_strain_IDs{
  my $dbh = shift;
  my $item_param = param('search_item');
  my $match_param = param('match');
  my @strain_ids;
  my %type_hash = ('Gross Observations' => 'gross_observation',
                   'Detail Observations' => 'detail_observation');
  my %item_hash = ('Cosmid names' => 'cosmid_name',
                   'CGC names'    => 'cgc_name',
                   'Strain names' => 'strain_name');

  my $sql_cmd = "SELECT strain_id from strain where $item_hash{$item_param} like \"$match_param\"";
  my $sth = $dbh->prepare($sql_cmd);

  if ($item_param){
    $sth->execute or die $dbh->errstr;

    #strain_name should not be duplicated
    while (my ($strain_id) = $sth->fetchrow_array){
      push @strain_ids, $strain_id;
    }
    return \@strain_ids;
  }else{
    return \@strain_ids;
  }
}

sub connect_to_database{
  my  %attr = (
        AutoCommit       => 0,
        FetchHashKeyName => 'NAME_lc',
        LongReadLen      => 3000,
        LongTruncOk      => 1,
        RaiseError       => 1,
    );

  #for testing: the database is temporarily named "SR_expression_test" -->will be renamed "SR_database" later
  my $dbh = DBI->connect('dbi:mysql:host=localhost;port=3306;database=SR_database','nchen','',\%attr) || die $DBI::errstr;
  return $dbh;
}

#not used: do not read from file, read from database
sub process_triage_file{
  my %returns;
  my $triage_file = shift;
  open (FH, "<$triage_file") || die $!;

  while (<FH>){
    chomp;
    next if (/Gene/ && /Strain/);
    my ($gene, $cgc, $strain, $transgene, $head, $body, $tail, $comments) = split /\t/;
    $returns{$strain} = [$gene, $cgc, $transgene, $head, $body, $tail, $comments];
  }
  close FH;
  return \%returns;
}

sub get_strain_id{
  my $strain = shift;
  my $dbh = shift;
  my @strain_id;

  my $sth = $dbh->prepare("SELECT * FROM strain where strain_name = \"$strain\"");
  $sth->execute or die $dbh->errstr;

  #strain_name should not be duplicated
  while (my ($strain_id, $strain_name, $cosmid_name, $cgc_name, $transgene_name) = $sth->fetchrow_array){
    push @strain_id, ($strain_id, $strain_name, $cosmid_name, $cgc_name, $transgene_name);
  }
  return \@strain_id;
}

sub strain_id_2_strain_data{
  my $strain_id = shift;
  my $dbh = shift;
  my @strain_data;

  my $sth = $dbh->prepare("SELECT * FROM strain where strain_id = \"$strain_id\"");
  $sth->execute or die $dbh->errstr;

  while (my ($strain_id, $strain_name, $cosmid_name, $cgc_name, $transgene_name) = $sth->fetchrow_array){
    @strain_data = ($strain_id, $strain_name, $cosmid_name, $cgc_name, $transgene_name);
  }
  return \@strain_data;
}

sub get_lab_id{
  my $lab = shift;
  my $dbh = shift;
  my $lab_id;

  my $sth = $dbh->prepare("SELECT laboratory_id FROM laboratory where laboratory_name = \"$lab\"");
  $sth->execute or die $dbh->errstr;

  #strain_name should not be duplicated
  while (my ($lab_id) = $sth->fetchrow_array){
    return $lab_id;
  }
}

sub get_lab_name{
  my $lab_id = shift;
  my $dbh = shift;
  my $lab_name;

  my $sth = $dbh->prepare("SELECT laboratory_name FROM laboratory where laboratory_name = \"$lab_id\"");
  $sth->execute or die $dbh->errstr;

  #strain_name should not be duplicated
  while (my ($lab_name) = $sth->fetchrow_array){
    return $lab_name;
  }
}

sub get_lab_from_id {
  my $laboratory_id = shift;
  my $dbh = shift;
  my $laboratory;
  my $sth = $dbh->prepare("SELECT laboratory_name FROM laboratory where laboratory_id = \"$laboratory_id\"");
  $sth->execute or die $dbh->errstr;

  while (my ($lab) = $sth->fetchrow_array){
    $laboratory = $lab;
  }
  return $laboratory;
}

sub get_gross_from_db{
  my $strain = shift;
  my $dbh = shift;
  my @triage_data;

  my $sth = $dbh->prepare("SELECT * FROM gross_observation where strain_id = \"$strain\"");
  $sth->execute or die $dbh->errstr;

  while (my (undef, undef, $head, $body, $tail, $gut, $muscle, $triage_comment, $triage_by, $triage_time) = $sth->fetchrow_array){

    #do not display (obtain) if all fields are empty
    my $lab = get_lab_from_id($triage_by, $dbh);
    push @triage_data, [$lab, $triage_time, $head, $body, $tail, $gut, $muscle, $triage_comment] unless ($triage_by eq '-' &&
          $triage_time eq '-' && 
          $head =~ /look|-/ &&
          $body =~ /look|-/ &&
          $tail =~ /look|-/ &&
          $gut =~ /look|-/ &&
          $muscle =~ /look|-/ &&
          $triage_comment 
      );
  }
  return \@triage_data;
}

sub get_detail_from_db{
  my $strain = shift;
  my $dbh = shift;
  my @detailed_data;

  my $sth = $dbh->prepare("SELECT * FROM detail_observation where strain_id = \"$strain\"");
  $sth->execute or die $dbh->errstr;
  
  while (my (undef, undef, $adf, $afd, $adl, $ase, $asg, $ash, $asi, $asj, $ask, $awa, $awb, $awc, $pha, $phb, $il1d, $il1, $il2d, $il2v, $il2, $detail_comment, $detail_by, $detail_time, $ip_address) = $sth->fetchrow_array){
    my $lab = get_lab_from_id($detail_by, $dbh);
    push @detailed_data, [$lab, $detail_time, $adf, $afd, $adl, $ase, $asg, $ash, $asi, $asj, $ask, $awa, $awb, $awc, $pha, $phb, $il1d, $il1, $il2d, $il2v, $il2, $detail_comment];

  }
  return \@detailed_data;
}

sub print_detail_display {
  my $result_ids_ref   = shift;	#ids that users want
  my $dbh              = shift;

  my @detailed_rows = (th(['Strain', 'Cosmid', 'CGC', 'Transgene', 'Observer', 'Date', 'Amphid neurons', 'Phasmid neurons', 'Labial neurons', 'Comments']));

  for my $strain_id_now (@{$result_ids_ref}){
  
    #strain_id --> gross_observation, detail_observation
    my @strain_id;		#molecular ids (gene name, cgc, etc) for the strain
    my @detailed_id; 		#if exist, display in "Detailed examination table
    my ($strain_id_ref, $triage_data_ref, $detailed_id_ref);

    $strain_id_ref 	= strain_id_2_strain_data($strain_id_now, $dbh);
    $detailed_id_ref 	= get_detail_from_db($strain_id_now, $dbh);

    @strain_id		= ($strain_id_ref)? @{$strain_id_ref} : ();
    shift @strain_id;	#strain_id is not displayed in the table
    @detailed_id 	= ($detailed_id_ref)? @{$detailed_id_ref} : ();

    #list all chemosensory neurons for selection
    my $neuron_id  = sort_neuron_id(\@detailed_id, \@strain_id);
    my @neuron_ids = @{$neuron_id};
  
    for (@neuron_ids){
      push @detailed_rows, td($_);
    }
  }

  print h3({-style=>'Color: blue;font-size: 15pt;font-family: sans-serif', -align=>'left'},"Detailed examination"), 
  table({-border=>undef, width=>"80%"}, Tr({-align=>'CENTER', -valign=>'TOP'}, \@detailed_rows));
}

#for sorting into one of the three groups (amphid, phasmid, or labial) for display
sub sort_neuron_id{
  my $ref = shift;
  my $ids_ref = shift;
  my @detailed_id = @{$ref};
  my @ids = @{$ids_ref};
  my @returns;

  for my $de (@detailed_id){
    my ($amphid, $phasmid, $labial) = ('', '', '');
    my ($lab, $time, $adf, $afd, $adl, $ase, $asg, $ash, $asi, $asj, $ask, $awa, $awb, $awc, $pha, $phb, $il1d, $il1, $il2d, $il2v, $il2, $comment) = @{$de};


    if ($adf == 1){
      $amphid .= "[ADF] "; 
    }
    if($afd == 1){
      $amphid .= "[AFD] ";
    }
    if($adl == 1){
      $amphid .= "[ADL] ";
    }
    if($ase == 1){
      $amphid .= "[ASE] ";
    }
    if($asg == 1){
      $amphid .= "[ASG] ";
    }
    if($ash == 1){
      $amphid .= "[ASH] ";
    }
    if($asi == 1){
      $amphid .= "[ASI] ";
    }
    if($asj == 1){
      $amphid .= "[ASJ] ";
    }
    if($ask == 1){
      $amphid .= "[ASK] ";
    }
    if($awa == 1){
      $amphid .= "[AWA] ";
    }
    if($awb == 1){
      $amphid .= "[AWB] ";
    }
    if($awc == 1){
      $amphid .= "[AWC] ";
    }
    if($pha == 1){
      $phasmid .= "[PHA] ";
    }
    if($phb == 1){
      $phasmid .= "[PHB] ";
    }
    if($il1d == 1){
      $labial .= "[IL1D] ";
    }
    if($il1 == 1){
      $labial .= "[IL1] ";
    }
    if($il2d == 1){
      $labial .= "[IL2D] ";
    }
    if($il2v == 1){
      $labial .= "[IL2V] ";
    }
    if($il2 == 1){
      $labial .= "[IL2] ";
    }
 
    $lab     ||= '-';
    $time    ||= '-';
    $amphid  ||= '-';
    $phasmid ||= '-';
    $labial  ||= '-';
    $comment ||= '-';
    push @returns, [$ids[0], $ids[1], $ids[2], $ids[3], $lab, $time, $amphid, $phasmid, $labial, $comment] 
        unless ($lab eq '-' &&
                $time eq '-' &&
                $amphid eq '-' &&
                $phasmid eq '-' &&
                $labial eq '-' && 
                'comment' eq 'Test');  
  }
  return \@returns;
}

#not used anymore
sub next_id{
  my ($table_name, $field_name, $dbh) = @_;
  my $id = $dbh->selectrow_array("select max($field_name) from $table_name");
  return $id + 1;
}

#get non-redundent strain names
sub get_all_strains{
  my $dbh = shift;
  my %strains;	#to avoid redundency in the database

  #get from "strain" table

  my $sth = $dbh->prepare("SELECT strain_name FROM strain");
  $sth->execute or die $dbh->errstr;

  while (my ($strain) = $sth->fetchrow_array){
    next if ($strain eq '-');
    $strains{$strain} = 1;
  }
  return \%strains;
}
