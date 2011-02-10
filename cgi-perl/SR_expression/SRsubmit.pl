#!/usr/bin/perl -w
use strict;
use CGI qw/:standard *table :html3/;
use DBI;
use Time::Format qw(%time);
use ElegansSubs;

=head1 SR_expression.pl

Script for submitting and viewing GFP gene expression information. 

	$Author: tharris $
	$Date: 2010-01-25 15:35:54 $
	$Id: SRsubmit.pl,v 1.1.1.1 2010-01-25 15:35:54 tharris Exp $

Basical behavior: After a strain is selected, related data will be displayed at 
website and user can make updates and upload back to database. The webpage is refreshed
with updated data in database whenever there is a data submission.

Issues: Do we keep old records in the database? Yes, keep all of them!

Form is successfully submitted only when user select a "lab". Use javascript to validate.

=cut

my $LOCAL_STYLE=<<END;
<!-

H1{

  font-size: 50pt;
  font-style: italic;
  font-family: sans-serif;
  color: red;

}
->

END

#Here is the javascript code.

my $JSCRIPT=<<EOF;

//validate that the user has selected a lab if other fields are filled. Return
//false to prevent the form from being submitted

function validateForm(){

  var lab1 = document.form1.lab_taken_gross.value;
  var lab2 = document.form1.lab_taken_detail.value;
  var lab3 = document.form1.lab_image.value;
  var file = document.form1.uploaded_file.value;

  if ((lab1 == 'Select a lab') 
     && (lab2 == 'Select a lab')
     && (lab3 == 'Select a lab')
     ){
    alert("Please select your lab from the list to submit data"); 
    return false;
  }

  return true;
}

//Should we enforce the user to write some comments if no neuron is selected?

function validateDetail(){

// To be implemented;
}
EOF
;

print header;

print
      start_html(-title=>"GFP::Chemosensory Genes in C. elegans",
                 -author=>'chenn@cshl.edu',
                 -meta=>{'copyright'=>'Copyright 2005'},
                 -BGCOLOR=>'White',
                 -style=>{-code=>$LOCAL_STYLE},
                 -script=>$JSCRIPT
                ),

      h1({-style=>'Color: blue;font-size: 200%;font-family: sans-serif', -align=>'center'}, "Chemosensory Gene Expression Data Resource"), q(<a href="http://dev.wormbase.org/SR_expression">Home</a>), hr,
      h2({-style=>'Color: blue;font-size: 150%;font-family: sans-serif'}, "<b>Data submission form</b>");

my $dbh = connect_to_database();

#All strains are retrieved from database for displaying
my $strains_ref 	= get_all_strains($dbh);	
my %strains_hash     	= %{$strains_ref};
my @strains          	= sort (keys %strains_hash);	

my $log_file = "/tmp/SR_expression_log";
open (LOG, ">>$log_file") || die $!;

#######################################################################################
#update database only when the page is submitted with a "lab" is selected
#This part has not been tested
#need to update two tables: gross_observation & detail_observation
#desired behavior: 
#click on "Update Gross" --> update gross_observation table --> display updated content
#click on "Update Detais" --> update detail_observation table --> display updated content
#######################################################################################

#If the page is first loaded (first log on the page), OR 
#if the page is reloaded (exp, via selecting a new strain) but "lab" are not selected 
#(suggesting the page has not been updated), print the website with data about the selected strain
if (!param() || 
    (param() && (param('lab_taken_gross') =~ /Select/) 
 && (param('lab_taken_detail') =~ /Select/)
 && (param('lab_image') =~ /Select/))){
  print_gene_input_table($strains_ref, $dbh);

  #disconnect database
  $dbh->disconnect;

  #If the page is reloaded and "lab" is (are) selected, then update the database first 
  #and then print out the web page with updated data about the strain
}elsif (param() && (param('lab_taken_gross') !~ /Select/) 
     || (param('lab_taken_detail') !~ /Select/)) {
  if (param('strain_name')){

    ###############################
    #update gross_observation table
    ###############################

    my $sth1 = $dbh->prepare(
        q[
                INSERT INTO gross_observation (strain_id, triage_head, triage_body, triage_tail, triage_gut, triage_muscle, triage_comment, laboratory_id, triage_time, ip_address)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]);

    #if user submit an entry
    my $current_strain = param('strain_name');	
    my $strain_id_update = get_strain_id($current_strain, $dbh); 
    my($strain_id) = @{$strain_id_update};

    my $comments = param('more_comments');
    my $head_update    = (param('r1') eq 'no')? '-' : param('r1');
    my $body_update    = (param('r2') eq 'no')? '-' : param('r2');
    my $tail_update    = (param('r3') eq 'no')? '-' : param('r3');
    my $gut_update     = (param('r4') eq 'no')? '-' : param('r4');
    my $muscle_update  = (param('r5') eq 'no')? '-' : param('r5');
    my $gross_lab = param('lab_taken_gross');
    my $detail_lab= param('lab_taken_detail'); 
    my $lab_ip = remote_addr();
    my $timestamp = $time{"yyyy-mm-dd hh:mm:ss"};

    #update database: gross observation
    #if no "gross observation" data is input, don't record it
    unless(($head_update =~ /look/ && 
           $body_update =~ /look/ && 
           $tail_update =~ /look/ &&
           $gut_update =~ /look/ &&
           $muscle_update =~ /look/ &&
           !$comments) || (param('lab_taken_gross') =~ /Select/)){
      $gross_lab = get_lab_id($gross_lab, $dbh);
      $sth1->execute($strain_id, $head_update, $body_update, $tail_update, $gut_update, $muscle_update, $comments || '-', $gross_lab, $timestamp, $lab_ip) or die $dbh->errstr;
      $dbh->commit;

      send_notification($strain_id, $gross_lab, $lab_ip, $timestamp, "Gross", $dbh);
    }

    ##########################
    #update detail observation
    ##########################

    my $sth2 = $dbh->prepare(
        q[
                INSERT INTO detail_observation (strain_id, adf, afd, adl, ase, asg, ash, asi, asj, ask, awa, awb, awc, pha, phb, il1d, il1, il2d, il2v, il2, detail_comment, laboratory_id, detail_time, ip_address)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]);

    my @amphid_neurons  = param('amphid_group');
    my @phasmid_neurons = param('phasmid_group');
    my @labial_neurons  = param('labial_group');
    my @total_neurons;
    push @total_neurons, @amphid_neurons;
    push @total_neurons, @phasmid_neurons;
    push @total_neurons, @labial_neurons;
    my ($adf_n, $afd_n, $adl_n, $ase_n, $asg_n, $ash_n, $asi_n, $asj_n, $ask_n, $awa_n, $awb_n, $awc_n, $pha_n, $phb_n, $il1d_n, $il1_n, $il2d_n, $il2v_n, $il2_n);
    for (@total_neurons){
      if (/ADF/i){
        $adf_n = 1;
      }elsif(/AFD/i){
        $afd_n = 1;
      }elsif(/ADL/i){
        $adl_n = 1;
      }elsif(/ASE/i){
        $ase_n = 1;
      }elsif(/ASG/i){
        $asg_n = 1;
      }elsif(/ASH/i){
        $ash_n = 1;
      }elsif(/ASI/i){
        $asi_n = 1;
      }elsif(/ASJ/i){
        $asj_n = 1;
      }elsif(/ASK/i){
        $ask_n = 1;
      }elsif(/AWA/i){
        $awa_n = 1;
      }elsif(/AWB/i){
        $awb_n = 1;
      }elsif(/AWC/i){
        $awc_n = 1;
      }elsif(/PHA/i){
        $pha_n = 1;
      }elsif(/PHB/i){
        $phb_n = 1;
      }elsif(/IL1D/i){
        $il1d_n = 1;
      }elsif(/IL1/i){
        $il1_n = 1;
      }elsif(/IL2D/i){
        $il2d_n = 1;
      }elsif(/IL2V/i){
        $il2v_n = 1;
      }elsif(/IL2/i){
        $il2_n = 1;
      }
    }

    unless((!$adf_n && !$afd_n && !$adl_n && !$ase_n && !$asg_n && !$ash_n && !$asi_n && !$asj_n && !$ask_n && !$awa_n && !$awb_n && !$awc_n && !$pha_n && !$phb_n && !$il1d_n && !$il1_n && !$il2d_n && !$il2v_n && !$il2_n && param('details')) || ($detail_lab =~ /Select/)){
      $detail_lab = get_lab_id($detail_lab, $dbh);
      $sth2->execute($strain_id, $adf_n || 0, $afd_n || 0, $adl_n || 0, $ase_n || 0, $asg_n || 0, $ash_n || 0, $asi_n || 0, $asj_n || 0, $ask_n || 0, $awa_n || 0, $awb_n || 0, $awc_n || 0, $pha_n || 0, $phb_n || 0, $il1d_n || 0, $il1_n || 0, $il2d_n || 0, $il2v_n || 0, $il2_n || 0, param('more_details') || '-', $detail_lab, $timestamp || '-', $lab_ip || '-') or die $dbh->errstr;
      $dbh->commit;

      send_notification($strain_id, $detail_lab, $lab_ip, $timestamp, "Detail", $dbh);
    }

    #print the updated website after each submission
    print_gene_input_table($strains_ref, $dbh);   

  }
} elsif (param('uploaded_file')){
  name_file_and_save(param('strain_name'), $dbh);
  #print the updated website after each submission
  print_gene_input_table($strains_ref, $dbh);   
}

#disconnect database
$dbh->disconnect;

close LOG;


#####################
#SUBROUTEINES
#####################
sub name_file_and_save{
  my $strain_name = shift;
  my $dbh = shift;

  #directory to save files: /usr/local/SR_images/
  #check how many images files have already been archieved in the directory
  #file names for each strain will be: BCXXXX_1, BCXXXX_2, etc

  my $image_dir = "/usr/local/SR_images/";
  my @existing_files = <$image_dir*>;
  my @related_files = grep(/$strain_name/, @existing_files);
  my $next_file_no = scalar @related_files + 1;

  my $filename = param('uploaded_file');

  my $image_name = $strain_name . "_" . $next_file_no;
  my $write_file = $image_dir . $image_name;

  open (FILE, ">$write_file" ) || die $!;

  my $data;
  while (read($filename, $data, 1024)){
    print FILE $data;
  }
  
  #update image table: image_name, strain_id, laboratory_id
  my $strain_id_ref = get_strain_id ($strain_name, $dbh);
  my ($strain_id) = @{$strain_id_ref};
  my $laboratory_id = get_lab_id(param('lab_image'), $dbh);

  my $sth3 = $dbh->prepare(
        q[
                INSERT INTO image (image_name, strain_id, laboratory_id)
                VALUES (?, ?, ?)
        ]);
  $sth3->execute($image_name, $strain_id, $laboratory_id) or die $dbh->errstr;
      $dbh->commit;

  my $lab_ip = remote_addr();
  my $timestamp = $time{"yyyy-mm-dd hh:mm:ss"};

  send_notification($strain_id, $laboratory_id, $lab_ip, $timestamp, "image", $dbh);

}

sub print_bottom{
  print br, br, hr;
  print q(Send comment to <a href="mailto:chenn@cshl.edu">chenn@cshl.edu</a>);
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
  my $dbh = DBI->connect('dbi:mysql:host=localhost;port=3306;database=SR_database', 'nchen', '',\%attr) || die $DBI::errstr;
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
    #push @strain_id, ($strain_id, $strain_name, $cosmid_name, $cgc_name, $transgene_name);
    @strain_id = ($strain_id, $strain_name, $cosmid_name, $cgc_name, $transgene_name);
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

  my $sth = $dbh->prepare("SELECT laboratory_name FROM laboratory where laboratory_id = \"$lab_id\"");
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

  print start_multipart_form(-name 	=> 'form1',
                 	     -onSubmit 	=> "return validateForm()");

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
  h3({-style=>'Color: blue;font-size: 15pt;font-family: sans-serif', -align=>'left'}, "Strain identification"),
  table({-border=>undef},
       Tr({-align=> 'CENTER',-valign=>'TOP'}, 
       [
         th(['Strain', 'Cosmid name', 'CGC name', 'Transgene']),
         td(\@strain_id),
       ]
  ));

  #Images upload
  print br,
  h3({-style=>'Color: blue;font-size: 15pt;font-family: sans-serif', -align=>'left'},"Upload images for strain $strain_value");

  print filefield(-name      => 'uploaded_file',
                  -default   => 'starting value',
                  -size      => 50,
                  -maxlength => 80,
                  );
  print br;
  print popup_menu( 
         -name 	=>'lab_image', 
         -values	=>['Select a lab', 'Baillie', 'Bargmann', 'Barr','Hobert', 'L\'Etoile', 'Moerman', 'Robertson', 'Sengupta', 'Stein', 'Taylor', 'Thomas'],
         -default	=>'Select a lab',
         -force 	=> 1);

  print submit(-name=>'Upload File');
  print br;


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

  print br,
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

  print br, 
  h3({-style=>'Color: blue;font-size: 15pt;font-family: sans-serif', -align=>'left'},"Detailed examination"), 
  table({-border=>undef, width=>"80%"}, Tr({-align=>'CENTER', -valign=>'TOP'}, \@detailed_rows));

  print_bottom();
  print end_form;
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
  my $change = ($type eq 'image')? 'New image uploaded' : ("$type observation");

  open (MAIL,"| /usr/lib/sendmail -oi -t") || return;
  print MAIL <<END;
From: "SR Resource"<chenn\@cshl.edu>
To: leroux\@sfu.ca, sengupta\@brandeis.edu, bjohnsen\@sfu.ca, crebecca\@interchange.ubc.ca, jht\@u.washington.edu, taylorjs\@uvic.ca, dbaillie\@gene.mbb.sfu.ca, hughrobe\@life.uiuc.edu, or38\@columbia.edu, cori\@mail.rockefeller.edu, ecrocke\@gs.washington.edu, ndletoile\@ucdavis.edu, mmbarr\@pharmacy.wisc.edu, lstein\@cshl.edu, chenn\@sfu.ca
#To: chenn\@cshl.edu, jack.n.chen\@gmail.com
Subject: SR Data Resource Updated 

This is an automatic announcement that the C. elegans 
Chemosensory Gene Expression Data Resource has been updated. 

http://dev.wormbase.org/SR_expression/

	Strain:   $strain_name
	Gene:     $cosmid_name
        CGC:      $cgc_name
	Change:	  $change 
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
