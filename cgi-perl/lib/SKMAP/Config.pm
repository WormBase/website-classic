package SKMAP::Config; 

use CGI();

use strict;
use Carp;
use vars qw($AUTOLOAD);

my $configPath	= '/usr/local/wormbase/cgi-perl/gene';
my $configFile	= 'expr.conf';

my %CONFIG;
my %CACHETIME;
my %CACHED;


sub new{
	my $class	= shift;
	$class	= ref($class) if ref($class);
	my %args	= @_;
	my $file	= $args{'config'} || $configFile;
	$file	.= ".pm";
	my $self	= {};
	$self->{'file'}		= $file;
	$self->{'confFile'}	= "${configPath}/${file}";
	$self->{'Config'}	= &getConfig($class, "${configPath}/${file}");
	bless $self, $class;
}



sub getConfig {
  my $package = shift;
  my $name    = shift;
  croak "Usage: getConfig(\$database_name)" unless defined $name;
  $package = ref $package if ref $package;
  my $file    = "${name}.pm";

  return unless -r $name;

  return $CONFIG{$name} if exists $CONFIG{$name} and $CACHETIME{$name} >= (stat(_))[9];
  return unless $CONFIG{$name} = $package->_load($name);
  $CONFIG{$name}->{'name'} ||= $name;  # remember name
  $CACHETIME{$name} = (stat(_))[9];
  return $CONFIG{$name};
}


sub AUTOLOAD {
    my($pack,$func_name) = $AUTOLOAD=~/(.+)::([^:]+)$/;
    my $self = shift;
    croak "Unknown field \"$func_name\"" unless $func_name =~ /^[A-Z]/;
    return $self->{$func_name} = $_[0] if defined $_[0];
    return $self->{$func_name} if defined $self->{$func_name};
    # didn't find it, so get default
    return if (my $dflt = $pack->getConfig('default')) == $self;
    return $dflt->{$func_name};
}

sub DESTROY { }


sub _load {
  my $package = shift;
  my $file    = shift;
  no strict 'vars';
  no strict 'refs';

  $file =~ m!([/a-zA-Z0-9._-]+)!;
  my $safe = $1;

  (my $ns = $safe) =~ s/\W/_/g;
  my $namespace = __PACKAGE__ . '::Config::' . $ns;
  unless (eval "package $namespace; require '$safe';") {
    die "compile error while parsing config file '$safe': $@\n";
  }
  # build the object up from the values compiled into the $namespace area
  my %data;

  # get the scalars
  local *symbol;
  foreach (keys %{"${namespace}::"}) {
    *symbol = ${"${namespace}::"}{$_};
    $data{ucfirst(lc $_)} = $symbol if defined($symbol);
    $data{ucfirst(lc $_)} = \%symbol if defined(%symbol);
    $data{ucfirst(lc $_)} = \@symbol if defined(@symbol);
    $data{ucfirst(lc $_)} = \&symbol if defined(&symbol);
    undef *symbol unless defined &symbol;  # conserve  some memory
  }

  # special case: get the search scripts as both an array and as a hash
  if (my @searches = @{"$namespace\:\:SEARCHES"}) {
    $data{Searches} = [ @searches[map {2*$_} (0..@searches/2-1)] ];
    %{$data{Search_titles}} = @searches;
  }

  # return this thing as a blessed object
  return bless \%data,$package;
}


1;
