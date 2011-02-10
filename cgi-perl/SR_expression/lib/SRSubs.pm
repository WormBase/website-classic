Package SRSubs;
use strict 'vars';
use vars qw/@ISA @EXPORT/;

require Exporter;
@ISA = Exporter;

@EXPORT = qw();

use CGI qw/:standard *table :html3/;
use DBI;
use Time::Format qw(%time);
use ElegansSubs;

sub connect_to_database{
  my  %attr = (
        AutoCommit       => 0,
        FetchHashKeyName => 'NAME_lc',
        LongReadLen      => 3000,
        LongTruncOk      => 1,
        RaiseError       => 1,
    );

  #for testing: the database is temporarily named "SR_expression_test" -->will be renamed "SRdb" later
  my $dbh = DBI->connect('dbi:mysql:host=brie3.cshl.edu;port=3306;database=SRdb','nchen','nchen',\%attr) || die $DBI::errstr;
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
    push @strain_data, ($strain_id, $strain_name, $cosmid_name, $cgc_name, $transgene_name);
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

sub print_gene_input_table {
  my $strains_ref      = shift;
  my $dbh              = shift;

  #all strain names
  my %strains_hash     = %{$strains_ref};
  my @strains          = sort (keys %strains_hash);	

  #current strain name value
  #note that each strain can be examined multiple times by multiple labs --> display all observation
  
  my $strain_value     = param('strain_name') || $strains[0];	#display the default (1st strain)
  #strain_value --> strain_id
  my $strain_id_pre       = get_strain_id($strain_value, $dbh);
  my ($strain_id_now)  = @{$strain_id_pre};

  #strain_id --> gross_observation, detail_observation

  my @strain_id;		#molecular ids (gene name, cgc, etc) for the strain
  my @triage_data; 		#if exist, used to fill the "Gross observation" table
  my @detailed_id; 		#if exist, display in "Detailed examination table
  my ($strain_id_ref, $triage_data_ref, $detailed_id_ref);

  if ($strain_value && $strains_hash{$strain_value}){

    #get into the database SR_expression and retrieve all observations 
    #(gross and detail) on this strain

    $strain_id_ref 	= get_strain_id($strain_value, $dbh);
    $triage_data_ref 	= get_gross_from_db($strain_id_now, $dbh);
    $detailed_id_ref 	= get_detail_from_db($strain_id_now, $dbh);
  }

  @strain_id		= ($strain_id_ref)? @{$strain_id_ref} : ();
  shift @strain_id;	#strain_id is not displayed in the table
  @triage_data		= ($triage_data_ref)? @{$triage_data_ref} : ();
  @detailed_id 		= ($detailed_id_ref)? @{$detailed_id_ref} : ();

  print
  " <b>Select a strain from database</b>: ",popup_menu(-name => 'strain_name',
                              -values=>\@strains,
                              -default=>$strains[0] || 'NA',
                              -onLoad   => 'submit()',
                              -onChange => 'submit()'), br, br;

  #Names and IDs
  print
  h3({-style=>'Color: blue;font-size: 15pt;font-family: sans-serif', -align=>'left'}, "Strain Identification"),
  table({-border=>undef},
       Tr({-align=> 'CENTER',-valign=>'TOP'}, 
       [
         th(['Strain', 'Cosmid name', 'CGC name', 'Transgene']),
         td(\@strain_id),
       ]
  ));

  #Gross observations
  my @rows  = (th(['Observer', 'Date', 'Head neurons', 'Body neurons', 'Tail neurons', 'Gut', 'Muscle', 'Comments']));
  for (@triage_data){
    push @rows, td($_);
  }
  push @rows, (td({-align => 'LEFT', -colspan => 2, nowrap=> 0},
                       #first submit button
                       submit(-name=>'Update Gross'),
                       popup_menu(
                          -name 	=>'lab_taken_gross',
                          -values	=>['Select a lab', 'Baillie', 'Bargmann', 'Barr','Hobert', 'L\'Etoile', 'Moerman', 'Robertson', 'Sengupta', 'Stein', 'Taylor', 'Thomas'],
                          -default	=>'Select a lab',
                          -force 	=> 1),

                       ) . td({-align => 'LEFT'},[
                       popup_menu(-name => 'r1', 
                                  -values => ['Didn\'t look', 'yes', 'no'], 
                                  -force => 1), 
                       popup_menu(-name => 'r2', 
                                  -values => ['Didn\'t look','yes', 'no'], 
                                  -force => 1), 
                       popup_menu(-name => 'r3', 
                                  -values => ['Didn\'t look','yes', 'no'], 
                                  -force => 1),
                       popup_menu(-name => 'r4', 
                                  -values => ['Didn\'t look','yes', 'no'], 
                                  -force => 1),
                       popup_menu(-name => 'r5', 
                                  -values => ['Didn\'t look','yes', 'no'], 
                                  -force => 1),
                       textfield(-name=>'more_comments',-size => 40, 
                                 -force => 1) ]));

  print
  h3({-style=>'Color: blue;font-size: 15pt;font-family: sans-serif', -align=>'left'},"Gross expression"),
  b("Notes: "), "yes: ", i("GFP positive"), "; -: ", i("GFP negative"),
  table({-border=>undef, -width=>"80%"}, Tr({-align=>'CENTER', -valign=>'TOP'}, \@rows));

  #list all chemosensory neurons for selection
  my $neuron_id  = sort_neuron_id(\@detailed_id);
  my @neuron_ids = @{$neuron_id};

  my @detailed_rows = (th(['Observer', 'Date', 'Amphid neurons', 'Phasmid neurons', 'Labial neurons', 'Comments']));
  
  for (@neuron_ids){
    push @detailed_rows, td($_);
  }

  push @detailed_rows, td({-align=>'LEFT', -colspan => 2, nowrap=>0}, 
                          #second submit button
                          submit(-name=>'Update Details'),
                          popup_menu(-name=>'lab_taken_detail',
                          -values=>['Select a lab', 'Baillie', 'Bargmann', 'Barr','Hobert', 'L\'Etoile', 'Moerman', 'Robertson', 'Sengupta', 'Stein', 'Taylor', 'Thomas'],
                          -default=>'Select a lab',
                          -force => 1)) . td({-width=>"25%"},
  	checkbox_group(-name	=>'amphid_group',
                 -cols => 3,
                 -values=>['ADF','AFD','ADL','ASE','ASG','ASH','ASI','ASJ','ASK','AWA','AWB','AWC'],
                 -force => 1,
                 )) . td(
  	checkbox_group(-name	=>'phasmid_group',
                 -cols => 2,
                 -values=>['PHA','PHB'],
                 -force => 1
                 )) . td(
  	checkbox_group(-name	=>'labial_group',
                 -cols => 2,
                 -values=>['IL1D','IL1','IL2D','IL2V','IL2'],
                 -force => 1
                 ) . td(
        textarea(-name=>'more_details',-columns => 40, -rows => 4, -force => 1)
                 ));

  print h3({-style=>'Color: blue;font-size: 15pt;font-family: sans-serif', -align=>'left'},"Detailed examination"), 
  table({-border=>undef, width=>"80%"}, Tr({-align=>'CENTER', -valign=>'TOP'}, \@detailed_rows));
}

#for sorting into one of the three groups (amphid, phasmid, or labial) for display
sub sort_neuron_id{
  my $ref = shift;
  my @detailed_id = @{$ref};
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
    if($awc == 1){
      $amphid .= "[AWA] ";
    }
    if($awb == 1){
      $amphid .= "[AWB] ";
    }
    if($awa == 1){
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
    push @returns, [$lab, $time, $amphid, $phasmid, $labial, $comment] 
        unless ($lab eq '-' &&
                $time eq '-' &&
                $amphid eq '-' &&
                $phasmid eq '-' &&
                $labial eq '-');  
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

sub send_notification {
  my $strain_id   = shift;
  my $lab         = shift;
  my $lab_ip      = shift;
  my $time_stamp  = shift;
  my $type        = shift;
  my $dbh    	  = shift;

  my $lab_name = get_lab_name($lab, $dbh);

  my $strain_data_ref = strain_id_2_strain_data($strain_id, $dbh);
  my (undef, $strain_name, $cosmid_name, $cgc_name, $transgene_name) = @{$strain_data_ref};

  #Lincoln suggested that we display updated data for the strain
  #together with all details for the strain

  #data from database: gross
  my $gross_ref = get_gross_from_db($strain_id, $dbh);
  my $print_gross = '';
  my @gross = sort {$b->[1] cmp $a->[1]}@{$gross_ref};

  for (my $g = 0; $g < scalar @gross; $g++){
    $print_gross .=<<END;

    Observation by $gross[$g]->[0] on $gross[$g]->[1]
	Head:	$gross[$g]->[2]
	Body:	$gross[$g]->[3]
	Tail:	$gross[$g]->[4]
	Gut:	$gross[$g]->[5]
	Muscle:	$gross[$g]->[6]
     	Comment:$gross[$g]->[7]
END
  
  }
  $print_gross ||= 'Not available';

  #data from database: detail
  my $detail_ref = get_detail_from_db($strain_id, $dbh);
  my $print_detail= '';
  my @details = sort{$b->[1] cmp $a->[1]}@{$detail_ref};
  for (my $d = 0; $d < (scalar @details); $d++){

    my($detail_by, $detail_time, $adf, $afd, $adl, $ase, $asg, $ash, $asi, $asj, $ask, $awa, $awb, $awc, $pha, $phb, $il1d, $il1, $il2d, $il2v, $il2, $detail_comment) = @{$details[$d]};

    $print_detail .=<<END;

    Observation by $detail_by on $detail_time
    	ADF:	$adf
    	AFD:	$afd
    	ADL:	$adl
    	ASE:	$ase
    	ASG:	$asg
    	ASH:	$ash
    	ASI:	$asi
    	ASJ:	$asj
   	ASK:	$ask
	AWA:	$awa
	AWB:	$awb
	AWC:	$awc
	PHA:	$pha
	PHB:	$phb
	IL1D:	$il1d
	IL2D:	$il2d
	IL2V:	$il2v
	IL2:	$il2
	Comment:$detail_comment 
END

  }
  $print_detail ||= 'Not available';   

  open (MAIL,"| /usr/lib/sendmail -oi -t") || return;
  print MAIL <<END;
From: "SR Resource"<chenn\@cshl.edu>
To: leroux\@sfu.ca, sengupta\@brandeis.edu, bjohnsen\@sfu.ca, crebecca\@interchange.ubc.ca, jht\@u.washington.edu, taylorjs\@uvic.ca, dbaillie\@gene.mbb.sfu.ca, hughrobe\@life.uiuc.edu, or38\@columbia.edu, cori\@mail.rockefeller.edu, ecrocke\@gs.washington.edu, ndletoile\@ucdavis.edu, mmbarr\@pharmacy.wisc.edu, lstein\@cshl.edu, chenn\@cshl.edu
#To: chenn\@cshl.edu, jack.n.chen\@gmail.com
Subject: SR Data Resource Updated 

This is an automatic announcement that the C. elegans 
Chemosensory Gene Expression Data Resource has been updated. 

http://dev.wormbase.org/SR_expression/

	Strain:   $strain_name
	Gene:     $cosmid_name
        CGC:      $cgc_name
	Change:	  $type observation
	Lab:      $lab_name
	Computer: $lab_ip
	Time:     $time_stamp (Eastern Time)

SR Resource

Observation Records About Strain $strain_name in the Database:

Gross expression
================
$print_gross


Detail observation
==================
$print_detail


END
;

  close MAIL;
}

1;
