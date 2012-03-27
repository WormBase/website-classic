package WormBase::Toggle;

use strict;
use base 'Exporter';
use CGI 'div','span','img','url','cookie';
use Digest::MD5  'md5_hex';

our @EXPORT = qw/toggle_one toggle_many toggle_self/;

use constant PLUS      => '/gbrowse2/images/buttons/plus.png';
use constant MINUS     => '/gbrowse2/images/buttons/minus.png';

sub toggle_one {
  my %config = ref $_[0] eq 'HASH' ? %{shift()} : ();
  my ($name,$section_title,@section_body) = @_;

  # Consult cookie for visibility-state
  $config{on} = visibility($name) unless $config{override};

  my $visible = $config{on};
  my @title_style   = $config{title_style} ? (-style => $config{title_style}) : ();
  my @section_style = $config{section_style} ? (-style => $config{section_style}) : ();


  # Buttons are optional
  my ($plus,$minus) = ('','');
  unless ($config{nobuttons}) {
    $plus  = $config{plus_img}  || PLUS;
    $plus  = img({-src=>$plus,-alt=>'+'});
    $minus = $config{minus_img} || MINUS;
    $minus = img({-src=>$minus,-alt=>'-'});
  }

  my $ctl_style = 'cursor:pointer;';
  my $show_ctl = div({ -id      => "${name}_show",
		       -title   => "Click to expand section $name",
		       -style   => $ctl_style . ($visible ? 'display:none' : 'display:inline'),
		       -onClick => "visibility('$name',1)"
		       },
		     $plus.span({-class=>'tctl'},"View $section_title"));

  my $hide_ctl = div({ -id      =>  "${name}_hide",
		       -title   => "Click to collapse section $name",
		       -style   => $ctl_style . ($visible ? 'display:inline' : 'display:none'),
		       -onClick => "visibility('$name',0)"
                     },
		     $minus.span({-class=>'tctl'},"Hide $section_title"));

  my $content  = div({-id    => $name,
		      -style=>$visible ? 'display:inline' : 'display:none',
		      -class => 'el_visible'},
		     @section_body);
  
  my @result = ($show_ctl.$hide_ctl,$content);
  
  return wantarray ? @result : "@result";
}


sub toggle_self {
  my %config = ref $_[0] eq 'HASH' ? %{shift()} : ();

  my ($name,$small,$big) = @_;

  $config{on} = visibility($name) unless $config{override};

  my $visible = $config{on};

  my $el_style = 'cursor:pointer;';

  my $show_el = div({ -id=>"${name}_small",
                       -style=>$el_style . ($visible ? 'display:none' : 'display:inline'),
                       -onClick=>"visibility('${name}_small',0);visibility('${name}_big',1)"
			 }, $small);

  my $hide_el = div({ -id=>"${name}_big",
                       -style=>$el_style . ($visible ? 'display:inline' : 'display:none'),
		      -onClick=>"visibility('${name}_big',0);visibility('${name}_small',1)"
			 }, $big);


  return $show_el.$hide_el;
}

sub toggle_many {
  my %config = ref $_[0] eq 'HASH' ? %{shift()} : ();
  my ($name,$section_title,$section_body) = @_;

  my @section_titles = @$section_title;
  my @section_bodies = @$section_body;
  if (@section_titles != @section_bodies) {
    die "unequal number of section titles and contents\n";
  }
  if (@section_titles < 2) {
    die "at least two sections are required\n";
  }
  my @section_names = map {$name . "_$_"} 1 .. $#section_titles;
  unshift @section_names, $name;

  # At least the first section should be visible by default
  my $visible = 1 unless grep {visibility($_)} @section_names;

  my (@titles,@contents);
  for my $nm (@section_names) {
    my $title  = shift @section_titles;
    my $body   = shift @section_bodies;
    my @other_names = grep {$_ ne $nm} @section_names;

    # turn this one on, all other off
    my $vis_ctl = join (';', 
			"visibility('$nm',1)",
			"visibility('${nm}_control',0)", 
			map{"visibility('$_',0);visibility('${_}_control',1)"} @other_names);
    $visible  ||= visibility($nm);
    my $ctl_visibility = $config{nohide} ? 'display:inline' : ($visible ? 'display:none' : 'display:inline');
    my $visibility     = $visible ? 'display:inline' : 'display:none';
    my $title_style    = join ';', map {defined} 'display:inline', $config{title_style}; 
    my $section_style  = join ';', map {defined} $visibility, $config{section_style};

    my $show_ctl = div({-id      => "${nm}_control",
			-style   => $ctl_visibility,
			-onClick => $vis_ctl
			 }, $title);


    my $content  = div({-id  => $nm,
			-style => $visibility,
			-class => 'el_visible'},
		       $body
		       );
    
    push @titles, $show_ctl;
    push @contents, $content;
    $visible = 0;
  }
  
  my $joiner = wantarray ? "\n" : "\&nbsp;\n";
  my $controls = join($joiner,@titles); 
  my $sections = join("\n",@contents);

  return wantarray ?  (\@titles,\@contents) : $controls.$sections;
}

# consult cookies for visibility state
# turned off for now
sub visibility { return 0;
  my $id = shift;
  my $cookie_name = "div_visible_$id";
  return cookie($cookie_name);
}


1;

__END__

=head1 NAME

CGI::Toggle -- Utility methods for collapsible sections

=head1 SYNOPSIS

  use CGI ':standard';
  use CGI::Toggle

  print header(),
  start_html('Toggle Test'),
  h1("Toggle Test"),
  toggle_section({on=>1},p('This section is on by default'),
  toggle_section({on=>0},p('This section is off by default'),
  toggle_section({plus_img=>'/icons/open.png',
                  minus_img=>'/icons/close.png'},
                 p('This section has custom open and close icons.')),
  hr,
  alternate_sections(['option 1','option 2'], ['I am option one','I am option two']); 

  end_html;


=head1 DESCRIPTION

This package adds JavaScript/CSS based support for collapsible and alternating
sections.  The function toggle_section() supports toggling on/off of collapsible sections 
and the function alternate_sections supports toggling of alternative
sections, displayed one at a time.  The on/off state of toggled or alternating
sections is remembered between sessions via cookies.

CGI::Toggle overrides the CGI start_html() method, so CGI must be imported
before bringing this module in.

=head1 METHODS

=item General options

The toggle_section and alternate_sections methods accept an optional
\%options hashref as their first argument.  The following aoptiona apply to both
both methods: 

=over 4

=item B<title_style>

 If true (default false), this option will override the site-wide style
 for section titles (default underlined) for this toggle section only.
 It expects CSS style attributes [eg: "text-decoration:underline"]

=item B<section_style>

 If true (default false), this option will apply CSS style attributes to
 the toggled section.  It expects CSS style attributes
 [eg: "text-decoration:underline"]

=back 4

=head2 toggle_section()

  ($control,$content) = toggle_section([\%options],$section_title=>@section_content)
  
This method takes an optional \%options hashref, a section name, a section title
and one or more strings containing the section content and returns a list
of HTML fragments corresponding to the control link and the content.
In a scalar context the control and content will be concatenated
together.
                 
The option keys specific to the toggle_section method are as follows:
  
=over 4
  
=item B<on>

If true, the section will be on (visible) by default.  The default is
false (collapsed).

=item B<plus_img>

URL of the icon to display next to the section title when the section
is collapsed.  The default is /gbrowse/images/plus.png.

=item B<minus_img>

URL of the icon to display next to the section title when the section
is expanded.  The default is /gbrowse/images/minus.png.

=item B<buttons>

If false, no plus/minus buttons will be shown next to the section title.
The default value for this option is true.

=item B<override>

If false (default), the state of the section will be remembered in a
cookie.  If true, the initial state will be taken from the b<on>
option, ignoring the cookie (which will, however, still be generated).

=back 4

=head2 some other thing  


=item ($control,$content) = toggle_section([\%options],$section_title=>@section_content)
  
This method takes an optional \%options hashref, a section title and
one or more strings containing the section content and returns a list
of HTML fragments corresponding to the control link and the content.
In a scalar context the control and content will be concatenated
together.

The option keys are as follows:

=over 4

=item b<on>

If true, the section will be on (visible) by default.  The default is
false (collapsed).

=item b<plus_img>
  
URL of the icon to display next to the section title when the section
is collapsed.  The default is /gbrowse/images/plus.png.

=item b<minus_img>

URL of the icon to display next to the section title when the section
is expanded..  The default is /gbrowse/images/minus.png.
  
=item b<override>
  
If false (default), the state of the section will be remembered in a
cookie.  If true, the initial state will be taken from the b<on>
option, ignoring the cookie (which will, however, still be generated).

=back 4


=head1 SEE ALSO

L<CGI>

=head1 AUTHOR

Lincoln Stein E<lt>lstein@cshl.orgE<gt>.

Copyright (c) 2005 Cold Spring Harbor Laboratory

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

The xGetCookie() and xSetCookie() JavaScript functions were derived
from www.cross-browser.com, and are copyright (c) 2004 Michael Foster,
and licensed under the LGPL (gnu.org).

=cut
