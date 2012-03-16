package Bio::Graphics::Browser2::Plugin::MotifFinder;
 
# test plugin
use strict;
use Bio::Graphics::Browser2::Plugin;
use File::Temp 'tempfile';
use CGI qw(:standard *table );
use CGI::Toggle;
use vars '$VERSION','@ISA';
$VERSION = '0.10';

@ISA = qw(Bio::Graphics::Browser2::Plugin);

my %MATRICES;
my %ALPHA=('a'=>0,
	   'c'=>1,
	   'g'=>2,
	   't'=>3,
	   );

my @COLORS = qw(red green blue orange cyan black 
		turquoise brown indigo wheat yellow emerald);

sub name { "Sequence Motif" }

sub description {
  p("This plugin finds sequence motif using Position Weight Matrix."),
  p("It was written by Xiaoqi Shi &amp; Lincoln Stein.");
}

sub type { 'annotator' }

# sub init {shift->configure_matrices}

sub config_defaults {
  my $self = shift;
  return { 
      pfm => '',
      on    => 1,
      indel_len => 0,
      indel => 0,
      bg    => [0.32, 0.18, 0.18, 0.32], #    background probability
      threshold => '0.85',
      "DAF-16" => 1,
  };
}

sub reconfigure {
  my $self = shift;
  my $current_config = $self->configuration;
  %$current_config = map {$_=>1} $self->config_param('matrix');
  $current_config->{pfm} = $self->config_param('pfm');
  my @add;
   @add=grep {$_ =~ />/}  split( /\n/, $current_config->{pfm})   ; 
  foreach (@add) {
      chomp();
      ~s/^>//;
      $current_config->{$_}=1;
  }
  $current_config->{on} = $self->config_param('on');
  $current_config->{indel} = $self->config_param('indel');
  $current_config->{indel_len} = $self->config_param('indel_len');
  $current_config->{threshold} = $self->config_param('threshold');
  $current_config->{bg} = [split /[ :]/, $self->config_param('bg')];
}

sub configure_form {
  my $self = shift;
  my $current_config = $self->configuration;
  $self->configure_matrices($current_config->{pfm}); 
  my @buttons = checkbox_group(-name   => $self->config_name('matrix'),
			       -values => [sort keys %MATRICES],
			       -cols   => 4,
			       -defaults => [grep {$current_config->{$_}} keys %$current_config],
			       );
  my @content=br.textarea(-name=>$self->config_name('pfm'),-default=>$current_config->{pfm},-rows=>4,-columns=>35);
			
  return table(	TR(th(a({-href=>"http://gmod.org/wiki/MotifFinder.pm"},"click here for instructions"))),
		TR({-class=>'searchtitle'},
		  th({-align=>'LEFT'},
		     "Sequence Motif Site Display ",
		  	radio_group(-name=>$self->config_name('on'),
			-values  =>[0,1], -labels  => {0=>'off',1=>'on'},
			-default => $current_config->{on}, -override=>1,
                  ))),
		TR({-class=>'searchtitle'},
		  th({-align=>'LEFT'},"Indel size(1-6) ".textfield(-name=>$self->config_name('indel_len'),
			-value=>$current_config->{indel_len},-size=>1).radio_group(-name=>$self->config_name('indel'),
			-values  =>[0,-1,1], -labels  => {0=>'off',-1=>'deletion',1=>'insertion'},
			-default => $current_config->{indel},-override=>1,
                  ))),
		TR({-class=>'searchtitle'},
		  th({-align=>'LEFT'}," Threshold(0-1)",
		  textfield(-name=>$self->config_name('threshold'),
			-value=>$current_config->{threshold},-size=>3))),
		TR(th({-align=>'LEFT'},"Background Probability(A C G T)",
		  textfield(-name=>$self->config_name('bg'),
			-value=>(join " ",@{$current_config->{bg}}),-size=>20))),
 	       TR(th(toggle_section('config_panel','Paste PFMs Here',@content))),
	       TR({-class=>'searchtitle'},
		  th("Select Position Matrices To Annotate")),
		TR({-class=>'searchbody'},
		  td(@buttons)));
}

sub annotate {
  my $self = shift;
  my $segment = shift;
  my $config  = $self->configuration;
  $self->configure_matrices($config->{pfm}) ;
  return unless %MATRICES;
  return unless %$config;
  return unless $config->{on};
 
  my $ref        = $segment->seq_id;
  my $abs_start  = $segment->start; 
 
  # write DNA out into a tempfile
  my ($fh,$seqfile) = tempfile('tfbs_seqXXXXXXX',
				SUFFIX => '.fa',
				UNLINK => 1,
				DIR    => File::Spec->tmpdir,
			       );
  print $fh lc($segment->dna);
  close $fh;

  my $feature_list =  $self->new_feature_list;
  my $count=0;
  for my $type (keys %$config) {
    my $matrix = $MATRICES{$type};
    next unless $matrix;
  
    #   caculate position weight matrix and intermediate thresholds
    my $pwm_length = caculate_pwm($matrix, $config->{bg}, $config->{threshold});
    my $matrixfile = print_pwm($pwm_length,$matrix);
    #  calling external C program for faster speed   (find transcription factor binding sites)
    my $command = join ' ',$self->config_path()."/".$self->browser_config->global_setting('plugin_path')."/motiffinder",$pwm_length,$config->{threshold},$matrixfile,$seqfile,$config->{indel}*$config->{indel_len};
    open (F,"$command |") or die "Couldn't open tfbsfinder. Did you install the tfbsfinder C program?: $!";
    $feature_list->add_type($type=>{glyph   => 'heat_map',
 			  vary_fg => 1,
			  start_color=>'red',
			  end_color=> 'blue',
			  pure_hue =>1,
			  strand_arrow   => 1,
			  description => 0,
			  max_score => 1,
			  min_score => $config->{threshold} ,
			  key=>$type." high scoring motif",
			  link=>'http://www.google.com/search?q=$type',
    			  title=> '$type (Score:$description) $ref:$start..$stop',	
		  });
     
    while (<F>) {
	next unless /^[+-]/;
	chomp();
	my ($strand,$pos,$score,$indel_pos,$indel) = split "\t";
	my $formatted_score=sprintf("%.5f",($score-$matrix->{min})/($matrix->{max}-$matrix->{min}));
	my $feature =  Bio::Graphics::Feature->new(  
			 -ref=>$ref,
			 -start=>$pos+$abs_start,
			 -end=> $pos+$abs_start+$pwm_length-1+$indel,
			 -strand=> $strand eq "+" ? '+1':'-1',
 			 -desc=> $formatted_score,
			  -score=> $formatted_score,
	  );
	$feature_list->add_feature($feature,$type) ;
    }
    close(F);
    $count++;
  }
  return $feature_list;
}

 
sub configure_matrices{
  my $self = shift;
  my ($content)=@_;
  %MATRICES=();
  my @lines;
  if ($content) {
      push @lines,split /\n/, $content;
  }
  my $filename = $self->browser_config->plugin_setting('matrix');
  if($filename) {
    #   my $conf_dir = $self->config_path();
      my $file     = $self->config_path."/$filename";
      open (MS, "$file") or die "Error: cannot open file $file: $!.\n";
      push @lines, <MS>;
      close(MS);
  }

  while (@lines) {
    $_ = shift @lines;
    ~s/^>//;
    next unless($_);
    chomp;
    my $matrix_name = $_;
    my @array;
    my $sum=0;
    my ($len,$i);
    for($i=0;$i<scalar keys %ALPHA;$i++){
	my $line = shift @lines;
	last unless($line);
	my @sp=split /\t|\s+/, $line;
	unless($len){
	    $len = scalar(@sp);
	}
	else{
	    last if($len != scalar(@sp));
	}
	$sum += $_ for @sp;
	push @array, \@sp;
    }  
    next unless($i==scalar keys %ALPHA);
    $MATRICES{$matrix_name}{value} = \@array;
    $MATRICES{$matrix_name}{len} = $len;
    $MATRICES{$matrix_name}{nseq} = $sum/$len;
  }
}

sub caculate_pwm{
  my ($matrix,$bg,$threshold)=@_;
  my ($i,$j);
  my $size = $matrix->{len};
  my $nseq_sqrt = sqrt($matrix->{nseq});
  my $nseq_base = $nseq_sqrt + $matrix->{nseq};
 
    my (@W,@minW,@maxW,@th);
    $matrix->{min}=0;
    $matrix->{max}=0;
    for($i=0;$i < $size; $i++){
      my @array;
      $maxW[$i] = -9999;
      $minW[$i] = 9999;
      for($j=0;$j<scalar keys %ALPHA;$j++){
	  my $weight = ($matrix->{value}->[$j][$i]+$bg->[$j]*$nseq_sqrt) / $nseq_base ;
	  $weight =  log($weight*4)/log(2) ;
	  push @array, $weight;
      }
      push @W,\@array;
      my @sort = sort {$a<=>$b}  @array;
      $minW[$i] = $sort[0];
      $maxW[$i] = $sort[$j-1];
      $matrix->{min} +=   $minW[$i];
      $matrix->{max} +=   $maxW[$i];
    }
    $matrix->{weight}=\@W;
    # caculate intermediate threshold 
    $th[$size-1]= ($threshold * ($matrix->{max} - $matrix->{min}) ) + $matrix->{min};
    for($i=$size-2;$i>=0;$i--){
      $th[$i]=$th[$i+1]-$maxW[$i+1];
    }
    $matrix->{threshold}=\@th;      
  
  return $size;
}

#   write position weight matrix out into a tempfile
sub print_pwm{ 
    my ($pwm_length, $matrix)=@_;
    my ($fh,$matrixfile) = tempfile('tfbs_pwmXXXXXXX',
				SUFFIX => '.ma',
				UNLINK => 1,
				DIR    => File::Spec->tmpdir,
			       );
    for(my $i=0;$i<$pwm_length;$i++) {
      for(my $j=0;$j<scalar keys %ALPHA;$j++){
	  print $fh $matrix->{weight}->[$i][$j]," ";
      }
      print $fh "\n";
    }
    close $fh;
    return $matrixfile;
}
 
1;

__END__

