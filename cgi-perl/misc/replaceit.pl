#!/usr/bin/perl

use strict;
use CGI ':standard';
use DB_File;
use Fcntl qw(O_CREAT O_RDWR);

my $save        = param('Save');
my $edit        = param('edit');
my $name        = param('name');
my $description = param('description');
my $escaped_description = CGI::escape($description);
my $escaped_name        = CGI::escape($name);
my $url            = url();

if ($save) {
  my %h;
  tie %h,'DB_File','/tmp/descriptions',O_CREAT|O_RDWR, 0666, $DB_HASH;
  $h{$name} = $description;
  print redirect("$url/../gbrowse?redisplay=1");
  exit 0;
}

warn "escaped name = $escaped_name";

my $edit_script =<<END;
new Ajax.Request('$url',
                  { method: 'post',
                    asynchronous: false,
                    parameters:
		    { edit:        1,
		      description: "$escaped_description",
		      name:        "$escaped_name"
		    },
                    onSuccess: function(t) {
                      document.getElementById('contents').innerHTML=t.responseText
                    },
                    onFailure: function(t) {
                      alert('AJAX Failure! '+t.statusText)
                    }
                  }
                );
END

print header();

if ($edit) {
    warn "name = $name";
  print b("Editing the description of $name");
  print div(
	  start_form(),
          textarea(-id=>'description',
		   -rows=>3,-cols=>30,
		   -name=>'description',-value=>$description),
	  br(),
	  submit(-name    =>'Save'
		),
	  button(-name   => 'Cancel',
		 -onClick=> 'Balloon.prototype.hideTooltip(1)'
		),
	  hidden(-name=>'name'),
	  end_form
	 );
}
else {
  print h2("$name: Description");
  print p($description);
  print p(button({-onClick=>$edit_script,
		  -name=>'Edit'
		 },
		),
	  button(-name   => 'Cancel',
		 -onClick=> 'Balloon.prototype.hideTooltip(1)'
		),
	 );
}

print end_html;
