=head1 NAME

demo_session_manager.pl

=head1 SYNOPSIS

 demo_session_manager.pl

=head1 DESCRIPTION

This is a test script for demonstrating features of the WormBase::Session::Manager module.

=cut

use lib '/usr/local/wormbase-new/lib/';
use lib '/home/canaran/wormbase-new/lib/';

use strict;
use WormBase::Session::Manager;
use CGI qw(:standard);

# CONSTRUCTOR
# ----------

# Create session manager object
# -----------------------------

my $wsm = WormBase::Session::Manager->new(
                                         -session_dir => '/tmp',
                                         -hist_length => 15,
                                         );

# Make sure that constructor comes before everything else as it
# generates a header with the cookie used for tracking sessions.
# - Additional header is unnecessary (will be overwritten).
# - If you need to specify a different mime type (e.g. text),
#   do it before, but will not be able to use tracking.

print "<h1>demo_session_manager.pl</h1>\n";

# During creation, this object will record, some session information
# automatically. These can be accessed in formatted form using
# accessor methods.
#
# A set of CGI environment variables are stored. Currently,
# only a page_history accessor is defined that retrieves the page
# history (stored as many times as -hist_length parameter).
#
# Every cgi script will call this module (directly or indirectly) so,
# a complete browse history can be captured. This can be used to generate,
# for example, a side bar that allows to go back to browsed genes within that
# session. Or a list of related items displayed on the side based on session
# history.
#
# For demonstration, in this script we write the time and accessed page (along with 'GET'
# params to the screen every time we access this script.

print "<h2>Session History</h2>\n";
print '<pre>' . join("\n", $wsm->page_history) . '</pre>';

# To demonstrate how to store arbitrary session varibales (e.g. user preferences),
# here's a form that information can be entered and stored in the session file.

my $url = $wsm->cgi->url; # the original cgi object can be accessed by the cgi method

print <<HTML;
<h2>User Preference Entry</h2>
Enter a value to change stored value<br><br>
<FORM method="GET" action="$url">
</b>User Preference</>: <INPUT type="text" name="user_pref" size="25">
<INPUT type="submit" name="submit" value="submit">
</FORM>
HTML

# We are going to change the stored value of *session param* 'user_pref',
# whenever we have a cgi param 'user_pref'.

# We use the 'session_param' method, to access/change session params. This is a direct
# call of the 'param' method of CGI::Session.

if (param('user_pref')) { $wsm->session_param('user_pref', param('user_pref')); }

my $current_user_pref = $wsm->session_param('user_pref');

print "Currently, the user preference value is: $current_user_pref<br><br>\n";

print "<b>[End of Demo]</b><br>\n";

=head1 AUTHOR

Payan Canaran <canaran@cshl.edu>

=head1 VERSION

$Id: demo_session_manager.pl,v 1.1.1.1 2010-01-25 15:35:54 tharris Exp $

=head1 CREDITS

=head1 COPYRIGHT AND LICENSE

Copyright 2005 Cold Spring Harbor Laboratory

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
