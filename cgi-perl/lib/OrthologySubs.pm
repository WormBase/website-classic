package OrthologySubs;


sub new {
   my $class = shift;
   my $this = bless{}, $class;
   return $class;
}

sub hello {
   my ($self) = @_;
	return "Hello World\n";
}

1;
