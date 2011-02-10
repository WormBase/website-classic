package WormBase::Formatting;

=pod

  =head1 WormBase::Formatting.pm

=head1 Synposis

=head1 Description

=cut

use strict;
use Ace::Browser::AceSubs;
use CGI qw/:standard/;

use lib '../';
use WormBase::Util::Rearrange;
use ElegansSubs qw/autocomplete_field autocomplete_end/;
use vars qw/$VERSION @ISA/;


=pod

# Display a number of examples at the top of each page.
# Intended for the first phase of the WormBase remodel,
# this subroutine is intended to replace PrintExamples
# It expects an hash reference containing keys of
# - message (the message to display
# - class to link to (for linking to the referring page)
# - examples (array reference of classes and object names)
#              classes will be translated into a more human readable string


# $wb->print_prompt(-message  => 'Specify a gene using',
#	            -examples  => [ locus   => 'unc-26',
#		                    gene    => 'R13A5.9']
#                   -class     => 'Expr_profile');

=cut

sub print_prompt {
  my $self = shift;
  $self->_do_prompt(1,@_);
}

sub prompt {
  my $self = shift;
  $self->_do_prompt(0,@_);
}

sub _do_prompt {
  my ($self,$print,@p) = @_;
  my ($message,$examples,$class) = rearrange([qw/MESSAGE EXAMPLES CLASS/],@p);

  my ($string,$c);

  # Convert classes (or pseudoclasses) to more appropriate messages...
  my %prompt_messages = (
			 Gene  => 'a predicted gene id',
			 Gene_class => 'a three letter gene class',
			 Locus => 'a gene name',
			 Gene_regulation => 'a gene regulation ID',
			 Protein => 'a protein ID',
			 Clone   => 'a clone ID',
			 RNAi    => 'an RNAi experiment ID',
			 CDS     => 'a coding sequence',
			 Expr_profile => 'an expression profile ID',
			 Variation    => 'an allele',
			 Strain       => 'a strain ID',
			 WB_id        => 'a wormbase gene ID',
			 );
  
  foreach my $example (@$examples) {
    my ($example_class) = eval { keys %$example  };
    my $name = eval { $example->{$example_class} };
    $name ||= $example;   # Might have passed a simple array ref for objects of the same class
    $c++;
    my $join = ($c == @$examples) ? ', or ' : ', ';
    $join = ' or ' if (@$examples == 2);
    $join = '' if $c == 1;
    my $submessage = $prompt_messages{$example_class}; # Fetch the appropriate message for this class

    # Use locus as a name, but link to the Gene_name class
    # $example_class = ($example_class eq 'Locus') ? 'Gene_name' : $example_class;
    # This DOES NOT WORK as expected.  I really want to Object2URL to map to the current display
    # but to use class=specific_class. Oh well, for now...
    if ($name && $submessage) {
      $string .= $join . $submessage . ' (' . a({-href=>Object2URL($name,$class)},$name) . ')';
    } else {
      $string .=  $join . a({-href=>Object2URL($name,$class)},$name);
    }
  }
#<<<<<<< Formatting.pm
#
#  my $form = start_form .
#      p({-class=>'caption'},"$message $string: ",
#	textfield(-name=>'name'),hidden('class')) .
#      end_form;
#
#  if ($print) {
#    print $form;
#  }
#  else {
#    return $form;
#  }
#=======

  print $self->autocomplete_form("$message $string",$class);
#>>>>>>> 1.12
}


sub autocomplete_form {
  my $self    = shift;
  my $caption = shift;
  my $class   = shift;

  # 2 is a generic ID used to distinguish per-page and global prompts
  # 'name' is the name of the textfield (query is the global search textfield)
  my $textfield = autocomplete_field('prompt');

  # If a page has been called for the first time, it won't have a class
  # Additionally, some pages can handle display of multiple classes

  my $autocomplete_end = autocomplete_end('prompt',$class);

  return div({-id=>'autoComplete2'},
	     start_form,
	     span({-class=>'caption'},$caption),
	     $textfield,
	     hidden('class'),
	     end_form,
	     ) .
	       $autocomplete_end;
}



# Deprecated - now provided by ElegansSubs.pm
#sub autocomplete_form_original {
#  my $self    = shift;
#  my $caption = shift;
#  my $class   = shift;
#
#  # If a page has been called for the first time, it won't have a class
#  # Additionally, some pages can handle display of multiple classes
#
#  my $textfield = <<'END';
#<script type="text/javascript">
#<!--
#if (doAutocomplete) {
#   document.write('<span id="autoCompleteSearch2">');
#   document.write('<input id="autoCompleteInput2" type="text" name="name" autocomplete="off" size="20" style="width:20em">');
#   document.write('<div id="autoCompleteContainer2"></div>');
#   document.write('</span>');
#} else {
#   document.write('<input id="autoCompleteInput2" type="text" name="name" size="20">');
#}
#//-->
#</script>
#<noscript><input type="text" name="name" size="20"></noscript>
#END
#
#  my $postscript = <<"END";
#<script type="text/javascript">
#<!--
#if (doAutocomplete) {
#   var autoCompleteServer2  = "/db/autocompleter2";
#   var autoCompleteSchema2  = ["\\n","\\t"];
#   var autoCompleteData2    = new YAHOO.widget.DS_XHR(autoCompleteServer2, autoCompleteSchema);
#   autoCompleteData2.responseType = autoCompleteData2.TYPE_FLAT;
#
#   var autoComplete2 = new YAHOO.widget.AutoComplete("autoCompleteInput2","autoCompleteContainer2",autoCompleteData2);
#   autoComplete2.allowBrowserAutocomplete = false;
#   autoComplete2.useShadow = true;
#   autoComplete2.queryDelay = 0;
#   autoComplete2.minQueryLength = 1;
#   autoComplete2.maxResultsDisplayed = 15;
#   autoCompleteData2.scriptQueryAppend = 'class=$class;max='+autoComplete2.maxResultsDisplayed;
#   autoCompleteData2.maxCacheEntries = 0;
#
#   /* paste the result into the textbox as "common name (ID)" */
#   autoComplete2.formatResult = function(aResultItem, sQuery) {
#      var sKey       = aResultItem[0];
#      var sDisplay   = aResultItem[1];
#      var sNote      = aResultItem[2];
#      return "<b>"+sDisplay+"</b>"+" <i class='tiny' title='"+sNote+"'> "+sNote+"</i>";
#   };
#}
#// -->
#</script>
#END
#
#  return div({-id=>'autoComplete2'},
#	     start_form,
#	     span({-class=>'caption'},$caption),
#	     $textfield,
#	     hidden('class'),
#	     end_form,
#	     ) .
#	       $postscript;
#}


1;
