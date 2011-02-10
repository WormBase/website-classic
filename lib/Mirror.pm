package Mirror;
# file: Mirror.pm
# ftp mirroring module

use strict;
use Carp;
use Net::FTP;
use File::Path;

# options:
# host  -- ftp host
# path  -- ftp path
# localpath -- localpath
# verbose -- verbose listing
# user  -- username
# pass  -- password
# passive -- use passive FTP
sub new {
    my $class = shift;
    croak "Usage: Mirror->new(\$host:/path)" unless @_ >= 1;
    my %opts;
    if (@_ == 1) {
	$opts{host} = shift;
    } else {
	my $counter;
	%opts = map { $counter++ % 2 ? $_
			             : /^-?(.*)/ && lc($1) 
		  } @_;  # clean up options
    }
    
    croak "Must provide host argument" unless $opts{host};
    if ($opts{host} =~ /(.+):(.+)/) {
	@opts{qw(host path)} = ($1,$2);
    }
    $opts{path} ||= '/';
    $opts{user} ||= 'anonymous';
    $opts{pass} ||= "$opts{user}\@localhost.localdomain";

    my %transfer_opts;
    $transfer_opts{Passive} = 1 if $opts{passive};

    my $ftp = Net::FTP->new($opts{host},%transfer_opts) || croak "Can't connect: $@\n";
    $ftp->login($opts{user},$opts{pass}) || croak "Can't login: ",$ftp->message;
    $ftp->binary;
    $ftp->hash(1) if $opts{hash};

    return bless {%opts,ftp=>$ftp},$class;
}

sub path {
    my $p = $_[0]->{path};
    $_[0]->{path} = $_[1] if defined $_[1];
    $p;
}

sub ftp {
    my $p = $_[0]->{ftp};
    $_[0]->{ftp} = $_[1] if defined $_[1];
    $p;
}

sub verbose {
    my $p = $_[0]->{verbose};
    $_[0]->{verbose} = $_[1] if defined $_[1];
    $p;
}

# top-level entry point for mirroring.
sub mirror {
    my $self = shift;
    $self->path(shift) if @_;
    my $path = $self->path;

    my $cd;
    if ($self->{localpath}) {
	chomp($cd = `pwd`);
	chdir($self->{localpath}) or croak "can't chdir to $self->{localpath}: $!";
    }


    my $type = $self->find_type($self->path) or croak "top level file/directory not found";

    my ($prefix,$leaf) = $path =~ m!^(.*?)([^/]+)/?$!;
    $self->ftp->cwd($prefix) if $prefix;

    my $ok;
    if ($type eq '-') {  # ordinary file
	$ok = $self->get_file($leaf);
    } elsif ($type eq 'd') {  # directory
	$ok = $self->get_dir($leaf);
    } else {
	carp "Can't parse file type for $leaf\n";
	return;
    }
    
    chdir $cd if $cd;
    $ok;
}

# mirror a file
sub get_file {
    my $self = shift;
    my ($path,$mode) = @_;
    my $ftp = $self->ftp;

    my $rtime = $ftp->mdtm($path);
    my $rsize = $ftp->size($path);
    $mode = ($self->parse_listing($ftp->dir($path)))[2] unless defined $mode;
    
    my ($lsize,$ltime) = stat($path) ? (stat(_))[7,9] : (0,0);
    if ( defined($rtime) and defined($rsize) 
	 and ($ltime >= $rtime) 
	 and ($lsize == $rsize) ) {
	warn "Getting file $path: not newer than local copy.\n" if $self->verbose;
	return;
    }

    warn "Getting file $path\n" if $self->verbose;
    $ftp->get($path) or (warn $ftp->message,"\n" and return);
    chmod $mode,$path if $mode;
}

# mirror a directory, recursively
sub get_dir {
    my $self = shift;
    my ($path,$mode) = @_;

    my $localpath = $path;
    -d $localpath or mkpath $localpath or carp "mkpath failed: $!" && return;
    chdir $localpath                   or carp "can't chdir to $localpath: $!" && return;
    $mode = 0755 if ($mode == 365); # Kludge-can't mirror non-writable directories
    chmod $mode,'.' if $mode;

    my $ftp = $self->ftp;

    my $cwd = $ftp->pwd                or carp("can't pwd: ",$ftp->message) && return;
    $ftp->cwd($path)                   or carp("can't cwd: ",$ftp->message) && return;
    
    warn "Getting directory $path/\n" if $self->verbose;

    foreach ($ftp->dir) {
	next unless my ($type,$name,$mode) = $self->parse_listing($_);
	next if $name =~ /^(\.|\.\.)$/;  # skip . and ..
	$self->get_dir ($name,$mode)    if $type eq 'd';
	$self->get_file($name,$mode)    if $type eq '-';
	$self->make_link($name)         if $type eq 'l';
    }
    
    $ftp->cwd($cwd)     or carp("can't cwd: ",$ftp->message) && return;
    chdir '..';
}

# subroutine to determine whether a path is a directory or a file
sub find_type {
    my $self = shift;
    my $path = shift;

    my $ftp = $self->ftp;
    my $pwd = $ftp->pwd;
    my $type = '-';  # assume plain file
    if ($ftp->cwd($path)) {
	$ftp->cwd($pwd);
	$type = 'd';
    }
    return $type;
}

# Attempt to mirror a link.  Only works on relative targets.
sub make_link {
    my $self = shift;
    my $entry = shift;

    my ($link,$target) = split /\s+->\s+/,$entry;
    return if $target =~ m!^/!;
    warn "Symlinking $link -> $target\n" if $self->verbose;
    return symlink $target,$link;
}

# parse directory listings 
# -rw-r--r--   1 root     root          312 Aug  1  1994 welcome.msg
sub parse_listing {
    my $self = shift;
    my $listing = shift;
    return unless my ($type,$mode,$name) =
	
	$listing =~ /^([a-z-])([a-z-]{9})  # -rw-r--r--
                 \s+\d*                # 1
                 (?:\s+\w+){2}         # root root
                 \s+\d+                # 312
                 \s+\w+\s+\d+\s+[\d:]+ # Aug 1 1994
                 \s+(.+)               # welcome.msg
                 $/x;           
    return ($type,$name,$self->filemode($mode));
}

# turn symbolic modes into octal
sub filemode {
    my $self = shift;
    my $symbolic = shift;

    my (@modes) = $symbolic =~ /(...)(...)(...)$/g;
    my $result;
    my $multiplier = 1;

    while (my $mode = pop @modes) {
	my $m = 0;
	$m += 1 if $mode =~ /[xsS]/;
	$m += 2 if $mode =~ /w/;
	$m += 4 if $mode =~ /r/;
	$result += $m * $multiplier if $m > 0;
	$multiplier *= 8;
    }
    $result;
}


1;
