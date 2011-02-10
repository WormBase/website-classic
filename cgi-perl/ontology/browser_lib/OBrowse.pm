package OBrowse;

use strict;
use IO::Socket::UNIX;

our @ISA=qw(IO::Socket::UNIX);

our $VERSION=0.021;

sub new {
    my $class=shift;
    my $sock=$class->SUPER::new(@_);
    unless ($sock) {
	return undef;
    }
    return $sock;
}

=head
sub DESTROY {
    my $self=shift;
    my $serveraddr=$self->hostpath();
    my $clientaddr=$self->peerpath();
    close $self;
    if ($serveraddr) {
	unlink $serveraddr;
    }
}
=cut

sub getAnnotations {
    my $self=shift;
    my $terms=shift;
    my $not=shift;
    my @annotations=();
    unless ($terms) {
	$!=22;
	close $self;
	return undef;
    }
    print $self "-l ", join('|', @$terms), "\n";
    if ($not) {
	print $self "-n";
    }
    shutdown($self, 1);
    while (<$self>) {
	chomp;
	my @tmp=split("\t");
	push @annotations, [@tmp]
    }
    close $self;
    return \@annotations;
}

sub findTerms {
    my $self=shift;
    my $query=shift;
    my %terms=();
    unless ($query) {
	$!=22;
	close $self;
	return undef;
    }
    print $self "-q $query";
    shutdown($self, 1);
    while (<$self>) {
	chomp;
	my @tmp=split("\t");

	$terms{$tmp[0]}{name}=$tmp[1];
	for (my $i=2; $i<=$#tmp; $i++) {
	    my $tag=$tmp[$i]=~/^([^:]+)/ ? $1 : '';
	    if ($tag) {
		$tmp[$i]=~s/$tag//;
		$tmp[$i]=~s/^:\s+//;
		if ($tag eq 'namespace') {
		    $terms{$tmp[0]}{namespace}=$tmp[$i];
		}
		else {
		    push @{$terms{$tmp[0]}{other}{$tag}}, $tmp[$i];
		}
	    }
	}
    }
    close $self;
    return \%terms;
}


sub browseTerm {
    my $self=shift;
    my $term=shift;
    my $propagate_to_root=shift;   # this only matters for NOT annotations
    my %data=();
    my ($id, $path)=('','');
    unless ($term) {
	$!=22;
	close $self;
	return undef;
    }
    print $self "-t $term\n-c\n-p\n";
    if ($propagate_to_root) {
	print $self "-r";
    }
    shutdown($self, 1);
    while (<$self>) {
#	print;
	next if /^ERROR:/;
	chomp;
	next unless $_;
	my @tmp=split('\t');
	if ($tmp[0] eq '[Term]') {
	    if ($id) {
		$data{$id}{path_count}=$path;
	    }
	    $id=''; 
	    $path=0;
	}
	elsif ($tmp[0] eq 'id:') {
	    $id=$tmp[1];
	}
	elsif ($tmp[0] eq 'Path_count') {
	    #skip
	}
	elsif ($tmp[0] eq 'name:') {
	    $data{$id}{name}=$tmp[1];
	}
	elsif ($tmp[0] eq 'Total_annotated_object_count') {
	    $data{$id}{taoc}{count}=$tmp[1];
	    $tmp[2]=~s/\(//;
	    $tmp[2]=~s/\)//;
	    $data{$id}{taoc}{terms}=$tmp[2];
	}
	elsif ($tmp[0] eq 'Total_annotation_count_combined') {
	    $data{$id}{tac}{combined}=$tmp[1];
	}
	elsif ($tmp[0] eq 'Total_annotation_count') {
	    $data{$id}{tac}{$tmp[1]}=$tmp[2];
	}
	elsif ($tmp[0] eq 'Total_NOT_annotated_object_count') {
	    $data{$id}{taoc_not}{count}=$tmp[1];
	    $tmp[2]=~s/\(//;
	    $tmp[2]=~s/\)//;
	    $data{$id}{taoc_not}{terms}=$tmp[2];
	}
	elsif ($tmp[0] eq 'Total_NOT_annotation_count_combined') {
	    $data{$id}{tac_not}{combined}=$tmp[1];
	}
	elsif ($tmp[0] eq 'Total_NOT_annotation_count') {
	    $data{$id}{tac_not}{$tmp[1]}=$tmp[2];
	}
	elsif ($tmp[0] eq 'self:' && defined $tmp[3]) {
	    $data{$id}{self}=$tmp[3];
	}
	elsif ($tmp[0] eq 'self:' && !defined $tmp[3]) {
	    #skip
	}
	elsif ($tmp[0] eq 'all_parent_term_count:') {
	    #skip
	}
	elsif ($tmp[0] eq 'parent_term_count:') {
	    #skip
	}
	elsif ($tmp[0] eq 'parent:') {
	    shift @tmp;
	    unshift @{$data{$id}{parents}}, [@tmp];    # proximal-most parent will be last in array - like in path_parent
	}
	elsif ($tmp[0] eq 'all_children_term_count:') {
	    #skip
	}
	elsif ($tmp[0] eq 'child:') {
	    shift @tmp;
	    push @{$data{$id}{children}}, [@tmp];
	}
	elsif ($tmp[0] eq 'immediate_children_term_count:') {
	    #skip
	}
	elsif ($tmp[0] eq 'immediate_child:') {
	    shift @tmp;
	    push @{$data{$id}{immediate_children}}, [@tmp];
	}
	elsif ($tmp[0] eq 'Path') {
	    $path++;
	}
	elsif ($tmp[0] eq 'path_parent:') {
	    shift @tmp;
	    push @{$data{$id}{paths}{$path}{path_parent}}, [@tmp];
	}
	elsif ($tmp[0] eq 'proximal_path_parent_child:') {
	    shift @tmp;
	    push @{$data{$id}{paths}{$path}{proximal_path_parent_child}}, [@tmp];
	}
	elsif ($tmp[0] eq 'self_in_path:') {
	    push @{$data{$id}{paths}{$path}{proximal_path_parent_child}}, [@tmp];  # do not shift @tmp - will have self_in_path: in [0]
	}
	else {
	    my $tag=$tmp[0]=~/^([^:]+)/ ? $1 : '';
	    if ($tag) {
		$tmp[0]=~s/$tag//;
		$tmp[0]=~s/^:\s+//;
		push @{$data{$id}{other}{$tag}}, $tmp[0];
	    }
	}
    }
    if ($id) {
	$data{$id}{path_count}=$path;
    }
    close $self;
    return \%data;
}



sub getAssociatedTerms {
    my $self=shift;
    my $obj=shift;
    my %all_terms=();
    my ($id, $path)=('','');
    unless ($obj) {
	$!=22;
	close $self;
	return undef;
    }
    print $self "-g $obj\n-p";
    shutdown($self, 1);
    while (<$self>) {
	if (/^ERROR:/) {
	    next;
	}
	chomp;
	next unless $_;
	my @tmp=split('\t');
	if ($tmp[0] eq 'id:') {
	    $id=$tmp[1];
	}
	elsif ($tmp[0] eq 'name:') {
	    $all_terms{$id}{name}=$tmp[1];
	}
	elsif ($tmp[0] eq 'parent:') {
	    $all_terms{$tmp[1]}{name}=$tmp[2];
	}
    }
    close $self;
    return \%all_terms;
}







sub getInfo {
    my $self=shift;
    our %annotations;
    our %not_annotations;
    our %ontology;
    print scalar keys %annotations, " annotations in object\n";
    print scalar keys %not_annotations, " NOT annotations in object\n";
    print scalar keys %ontology, " terms in object\n";
    return 1;
}

sub killServer {
    my $self=shift;
    print $self "-k";
    shutdown($self, 1);
    while (<$self>) {
	chomp;
	print "$_\n";
    }
    close $self;
    return 1;
}
    

sub loadOntology {
    my $self=shift;
    my $ontologyFile=shift;
    open (IN, "<$ontologyFile") || return undef;
    our %ontology=();
    my ($id, $name, @parents, @other, $namespace);
    my $default_namespace='';
    my $in_term='';
    while (<IN>) {
	chomp;
	unless ($_) {
	    $in_term=0;
	    if ($id) {
		@{$ontology{$id}{parents}}=@parents;
		$ontology{$id}{name}=$name;
		if (! $namespace) {
		    push @other, "namespace: $default_namespace";
		}
		@{$ontology{$id}{other}}=@other if @other;
		foreach my $c (@parents) {
		    push @{$ontology{$$c[0]}{children}}, [$id, $$c[1]];
		}
	    }
	    $id='';
	    @parents=();
	    $name='';
	    @other=();
	    $namespace='';
	    next;
	}
	if (/^\[Term\]/) {
	    $in_term=1;
	}
	elsif (/^id:/ && $in_term) {
	    $id=$_=~/^id:\s+(\S+)/ ? $1 : '';
#	    $id=$_=~/(GO:\d+)/ || /(WB[\w:]+)/ ? $1 : '';
	    if (!$id) {
		warn "$_ : cannot parse term ID\n";
		next;
		
	    }
	}
	elsif (/^is_a:/) {
	    my $tmp=$_=~/^is_a:\s+(\S+)/ ? $1 : '';
#	    my $tmp=$_=~/(GO:\d+)/ || /(WB[\w:]+)/ ? $1 : '';
	    if (!$tmp) {
		warn "$_ : cannot parse is_a term ID\n";
		next;
	    }
	    push @parents, [$tmp, 'i'];
	}
	elsif (/part_of/ && !(/^id/ || /^name/)) {
	    my $tmp=$_=~/part_of[:]*\s+(\S+)/ ? $1 : '';
#	    my $tmp=$_=~/(GO:\d+)/ || /(WB[\w:]+)/ ? $1 : '';
	    if (!$tmp) {
		warn "$_ : cannot parse part_of term ID\n";
		next;
	    }
	    push @parents, [$tmp, 'p'];
	}
	
	elsif(/^name:/) {
	    $name=$_=~/^name: (.+)/ ? $1 : '';
	}
	elsif(/^default-namespace:/) {
	    $default_namespace=$_=~/^default-namespace: (.+)/ ? $1 : '';
	}
	else {
	    push @other, $_;
	    if (/^namespace:/) {
		$namespace=1;
	    }
	}
    }
    if ($id) {
	@{$ontology{$id}{parents}}=@parents;
	$ontology{$id}{name}=$name;
	if (! $namespace) {
	    push @other, "namespace: $default_namespace";
	}
	@{$ontology{$id}{other}}=@other if @other;
	foreach my $c (@parents) {
	    push @{$ontology{$$c[0]}{children}}, [$id, $$c[1]];
	}
    }
    close IN;
    return scalar keys %ontology;
}

sub loadAnnotations {
    my $self=shift;
    my $annotationsFile=shift;
    open (IN, "<$annotationsFile") || return undef;
    
    our %annotations=();
    our %not_annotations=();
    our %annotations_lines=();
    our %not_annotations_lines=();


    while (<IN>) {
	chomp;
	next unless $_;
	next if /^!/;
	my @tmp=split('\t');
#	unless ($tmp[4]=~/^GO:/ || $tmp[4]=~/^WBPhenotype/ || $tmp[4]=~/^WBbt:/ ) {
	unless ($tmp[4]) {
	    next;
	}
	my $type='';
	if ($tmp[6]) {
	    $type=$tmp[6];
	}
	else {
	    $type='NA';
	}
	if ($tmp[3]=~/NOT/i) {
	    $not_annotations{$tmp[4]}{$tmp[1]}{$type}++;
	    push @{$not_annotations_lines{$tmp[4]}}, [@tmp];
	}
	else {
	    $annotations{$tmp[4]}{$tmp[1]}{$type}++;
	    push @{$annotations_lines{$tmp[4]}}, [@tmp];
	}
    }

    return [(scalar keys %annotations, scalar keys %not_annotations)];
}

sub startServer {
    my $self=shift;
    our %annotations;
    our %not_annotations;
    our %annotations_lines;
    our %not_annotations_lines;
    our %ontology;

    my %new_ontology=();

#    use sigtrap 'handler' => sub { return $self->stopServer(); },  'untrapped', 'normal-signals'; # this works but generates errors on systsm restart
    $SIG{TERM} = sub { return $self->stopServer(); };

    while (my $client=$self->accept()) {

	my @go2process=();
	my @query=();
	my @list2retrieve=();
	my $object2process='';
	
	my $not='';
	my $propagate_to_root='';   # propagate 'NOT' annotations to root? If not, report NOT annotations attached directly to term only
	my $print_children='';
	my $print_parents='';
	my $kill_server='';
	
	while (<$client>) {         # process query
	    chomp;
	    my @tmp=split('\s+');
	    if ($tmp[0] eq '-t') {
		push @go2process, $tmp[1];
	    }
	    elsif ($tmp[0] eq '-c') {
		$print_children=1;
	    }
	    elsif ($tmp[0] eq '-p') {
		$print_parents=1;
	    }
	    elsif ($tmp[0] eq '-q') {
		shift @tmp;
		@query=map qr/$_/i, @tmp;
	    }
	    elsif ($tmp[0] eq '-l') {
		shift @tmp;
		@list2retrieve=map split('\|'), @tmp;
	    }
	    elsif ($tmp[0] eq '-g') {
		$object2process= $tmp[1];
	    }
	    elsif ($tmp[0] eq '-n') {
		$not=1;
	    }
	    elsif ($tmp[0] eq '-k') {
		$kill_server=1;
	    }
	    elsif ($tmp[0] eq '-r') {
		$propagate_to_root=1;
	    }
	}
	
	select $client;

	if ($kill_server) {
	    print "stopping server\n";    #goes to client
	    warn "stopping server\n";     #goes to  server
	    return $self->stopServer();
	}
	
	if ($object2process) {     # only positive annotations are considered, at least for now
	    @go2process=();
	    my %tmp=();
	    foreach my $a (keys %annotations) {
		if ($annotations{$a}{$object2process}) {
		    $tmp{$a}++;
		}
	    }
	    push @go2process, sort {$a cmp $b} keys %tmp;
	}
	
	if (@list2retrieve) {
#	    foreach my $l (sort {$a cmp $b} @list2retrieve) {
	    foreach my $l (@list2retrieve) {
		if ($not) {
		    if ($not_annotations_lines{$l}) {
			foreach (@{$not_annotations_lines{$l}}) {
			    my $name=$ontology{$l}{name} ? $ontology{$l}{name} : '';
			    print join("\t", $name, @{$_}), "\n";
			}
		    }
		}
		else {
		    if ($annotations_lines{$l}) {
			foreach (@{$annotations_lines{$l}}) {
			    my $name=$ontology{$l}{name} ? $ontology{$l}{name} : '';
			    print join("\t", $name, @{$_}), "\n";
			}
		    }
		}
	    }

	    close $client;
	    next;
	}

	if (@query) {
	    my %results=();
	    foreach my $id (keys %ontology) {
		if (! $ontology{$id}{other}) {
		    $ontology{$id}{other}[0]='';
		}
		if (! $ontology{$id}{name}) {
		    $ontology{$id}{name}='';
		}
		my $line=join(' ', $id, $ontology{$id}{name}, grep {/synonym:/} @{$ontology{$id}{other}});
		my $match=0;
		foreach (@query) {
		    if ($line=~/$_/) {
			$match++;
		    }
		}
		if ($match == scalar @query) {
		    $results{$id}=1;
		}
		
	    }
	    foreach my $id (sort {$a cmp $b} keys %results) {
		my $line=join("\t", $id, $ontology{$id}{name});
		if ($ontology{$id}{other}) {
		    $line.="\t".join("\t", @{$ontology{$id}{other}});    # print all fields, sort them in client
		}
		print "$line\n";
	    }
	    close $client;
	    next;
	}
	

	foreach my $id (@go2process) {    # build trees and collect annotations
	    if (!$ontology{$id}) {
		print "ERROR: $id ID is not in ontology\n";
		next;
	    }
	    
	    %new_ontology=();     # unless you want to store the hash later, but it's big...
	    my @aggr_parents=();
	    my @aggr_stack=();
	    my %aggr_tree=();
	    @aggr_stack=@{$ontology{$id}{parents}} if $ontology{$id}{parents};
	    my $aggr_order=0;
	    while (@aggr_stack) {
		$aggr_order++;
		my $new_go=pop @aggr_stack;
		$aggr_tree{$$new_go[0]}{order}=$aggr_order;
		$aggr_tree{$$new_go[0]}{rel}=$$new_go[1];         # relationship within a merged tree does not really make sense...
		if ($ontology{$$new_go[0]}{parents}) {
		    push @aggr_stack, @{$ontology{$$new_go[0]}{parents}};
		}
	    }
	    foreach (sort {$aggr_tree{$a}{order} <=> $aggr_tree{$b}{order}} keys %aggr_tree) {
		push @aggr_parents, [$_, $aggr_tree{$_}{rel}];
	    }

	    
	    
	    
	    
	    my @tree_stack=();
	    my @trees=();
	    my $i=0;
	    my @stack=();

	    @stack=[$id, 's'];
	    my $order=0;
	    my $prev_count=$#stack;
	    my %tree=();
	    
	    while (@stack) {
		$order++;
		my $new_go=pop @stack;

		$tree{$$new_go[0]}{order}=$order;
		$tree{$$new_go[0]}{rel}=$$new_go[1];
		if ($ontology{$$new_go[0]}{parents}) {
		    push @stack, @{$ontology{$$new_go[0]}{parents}};
		}
		if ($#stack > $prev_count) {
		    my $diff = $#stack - $prev_count;
		    for (my $i=0; $i<$diff; $i++) {
			%{$tree_stack[$#tree_stack + 1]} = %tree;
		    }
		    $prev_count=$#stack;
		}
		elsif ($#stack < $prev_count) {
		    %{$trees[$#trees + 1]}=%tree;
		    if (@tree_stack) {
			my $ref=pop @tree_stack;
			%tree=%$ref;
		    }
		    $prev_count=$#stack;
		}
	    }

	    my %tracker=();
	    my $path=0;
	    if (@trees) {
		foreach my $t (@trees) {
		    my $par_string=join("-", sort {$$t{$a}{order} <=> $$t{$b}{order}} keys %{$t});
		    if ($tracker{$par_string}) {
			next;
		    }
		    else {
			$tracker{$par_string}=1;
		    }
		    
		    $path++;
		    $new_ontology{$id}{$path}{name}=$ontology{$id}{name};
		    if ($ontology{$id}{other}) {
			@{$new_ontology{$id}{$path}{other}}=@{$ontology{$id}{other}};
		    }
		    else {
			@{$new_ontology{$id}{$path}{other}}=();
		    }
		    @{$new_ontology{$id}{$path}{parents}}=();
		    @{$new_ontology{$id}{$path}{children}}=();
		    if ($ontology{$id}{children}) {
			@{$new_ontology{$id}{$path}{immediate_children}}=@{$ontology{$id}{children}};
		    }
		    else {
			@{$new_ontology{$id}{$path}{immediate_children}}=();
		    }
		    
		    my @sorted_terms=sort {$$t{$a}{order} <=> $$t{$b}{order}} keys %{$t};
		    for (my $i=0; $i<=$#sorted_terms; $i++) {
			if ($i < $#sorted_terms) {
			    push @{$new_ontology{$id}{$path}{parents}}, [$sorted_terms[$i], $$t{$sorted_terms[$i+1]}{rel}];
			}
			else {
			    push @{$new_ontology{$id}{$path}{parents}}, [$sorted_terms[$i], 'i'];    # top level - is_a ontology
			}
		    }
		    
		}
	    }
	    else {
		$path++;
		$new_ontology{$id}{$path}{name}=$ontology{$id}{name};
		if ($ontology{$id}{other}) {
		    @{$new_ontology{$id}{$path}{other}}=@{$ontology{$id}{other}};
		}
		else {
		    @{$new_ontology{$id}{$path}{other}}=();
		}
		@{$new_ontology{$id}{$path}{parents}}=();
		@{$new_ontology{$id}{$path}{children}}=();
		if ($ontology{$id}{children}) {
		    @{$new_ontology{$id}{$path}{immediate_children}}=@{$ontology{$id}{children}};
		}
		else {
		    @{$new_ontology{$id}{$path}{immediate_children}}=();
		}
	    }
	    
	    
	    
	    
	    @stack=();
	    %tree=();
	    @stack=@{$ontology{$id}{children}} if $ontology{$id}{children};
	    $order=0;
	    my %total_annotation_count=();
	    my @total_terms=($id);
	    my %total_annotated_gene_hash=();

	    my %total_NOT_annotation_count=();
	    my @total_NOT_terms=($id);
	    my %total_NOT_annotated_gene_hash=();

	    
	    if ($annotations{$id}) {
		foreach (keys %{$annotations{$id}}) {
		    $total_annotated_gene_hash{$_}++;
		    foreach my $t (keys %{$annotations{$id}{$_}}) {
			$total_annotation_count{$t}+=$annotations{$id}{$_}{$t};
		    }
		}
	    }
	    if ($not_annotations{$id}) {
		foreach (keys %{$not_annotations{$id}}) {
		    $total_NOT_annotated_gene_hash{$_}++;
		    foreach my $t (keys %{$not_annotations{$id}{$_}}) {
			$total_NOT_annotation_count{$t}+=$not_annotations{$id}{$_}{$t};
		    }
		}
	    }
	    

	    while (@stack) {
		$order++;
		my $new_go=pop @stack;
		$tree{$$new_go[0]}{order}=$order;
		$tree{$$new_go[0]}{rel}=$$new_go[1];
		if ($ontology{$$new_go[0]}{children}) {
		    push @stack, @{$ontology{$$new_go[0]}{children}};
		}
	    }
	    

            for (my $p=1; $p<=$path; $p++) {
	        foreach (sort {$tree{$a}{order} <=> $tree{$b}{order}} keys %tree) {
		    push @{$new_ontology{$id}{$p}{children}}, [$_, $tree{$_}{rel}];
		    if ($p==1 and $annotations{$_}) {
			push @total_terms, $_;                   # these are children go terms, not annotations
			foreach my $a (keys %{$annotations{$_}}) {
			    $total_annotated_gene_hash{$a}++;                    # these are all annotated genes
			    foreach my $t (keys %{$annotations{$_}{$a}}) {
				$total_annotation_count{$t}+=$annotations{$_}{$a}{$t};  # these are total annotations
			    }
			}
		    }
		}
	    }
	    if ($propagate_to_root) {       # count NOT terms associated with parents only if $propagate_to_root is true
		foreach (@aggr_parents) {
		    if ($not_annotations{$$_[0]}) {
			push @total_NOT_terms, $$_[0];                   # these are parents go terms, not annotations
			foreach my $a (keys %{$not_annotations{$$_[0]}}) {
			    $total_NOT_annotated_gene_hash{$a}++;                    # these are all annotated genes
			    foreach my $t (keys %{$not_annotations{$$_[0]}{$a}}) {
				$total_NOT_annotation_count{$t}+=$not_annotations{$$_[0]}{$a}{$t};  # these are total annotations
			    }
			}
		    }
		}
	    }

	    
	    my $path_count = scalar keys %{$new_ontology{$id}};
	    if ($path_count == 0) {
		next;
	    }


	    my $p=1;
	    print "[Term]\n";

	    print "id:\t$id\t$new_ontology{$id}{$p}{name}\n";
	    print "Path_count\t$path_count\n";
	    print "name:\t$new_ontology{$id}{$p}{name}\n";
	    print "Total_annotated_object_count\t", scalar keys %total_annotated_gene_hash, "\t(", join('|', @total_terms), ")\n";
	    my $total_annotation_count_combined=0;
	    foreach (keys %total_annotation_count) {
		$total_annotation_count_combined+=$total_annotation_count{$_};
	    }
	    print "Total_annotation_count_combined\t$total_annotation_count_combined\n";
	    foreach (keys %total_annotation_count) {
		print "Total_annotation_count\t$_\t$total_annotation_count{$_}\n";
	    }

	    print "Total_NOT_annotated_object_count\t", scalar keys %total_NOT_annotated_gene_hash, "\t(", join('|', @total_NOT_terms), ")\n";
	    my $total_NOT_annotation_count_combined=0;
	    foreach (keys %total_NOT_annotation_count) {
		$total_NOT_annotation_count_combined+=$total_NOT_annotation_count{$_};
	    }
	    print "Total_NOT_annotation_count_combined\t$total_NOT_annotation_count_combined\n";
	    foreach (keys %total_NOT_annotation_count) {
		print "Total_NOT_annotation_count\t$_\t$total_NOT_annotation_count{$_}\n";
	    }
	    


	    foreach (@{$new_ontology{$id}{$p}{other}}) {
		print "$_\n";
	    }
	    if ($print_parents) {
		print "all_parent_term_count:\t", scalar @aggr_parents, "\n";
		if ($not_annotations{$id}) {
		    print "self:\t$id\t$ontology{$id}{name}\t", scalar keys %{$not_annotations{$id}}, "\tNOT\n";
		}
		else {
		    print "self:\t$id\t$ontology{$id}{name}\t0\n";
		}
		foreach (@aggr_parents) {
		    my $term_count=0;
		    if ($not_annotations{$$_[0]}) {
			$term_count=scalar keys %{$not_annotations{$$_[0]}};
		    }
		    print "parent:\t$$_[0]\t$ontology{$$_[0]}{name}\t$term_count\tNOT\n";  #NOT - have to count annotations in parents
		}
	    }
	    
	    print "immediate_children_term_count:\t", scalar @{$new_ontology{$id}{$p}{immediate_children}}, "\n";
	    foreach (sort {lc $ontology{$$a[0]}{name} cmp lc $ontology{$$b[0]}{name}} @{$new_ontology{$id}{$p}{immediate_children}}) {
		my $expand='';
		if ($ontology{$$_[0]}{children}) {
		    $expand='+';
		}
		if ($$_[1] eq 'i') {
		    print "immediate_child:\tis_a\t$$_[0]\t$ontology{$$_[0]}{name}\t$expand\n";
		}
		else {
		    print "immediate_child:\tpart_of\t$$_[0]\t$ontology{$$_[0]}{name}\t$expand\n";
		}
	    }
	    if ($print_children) {
		print "all_children_term_count:\t", scalar @{$new_ontology{$id}{$p}{children}}, "\n";
		if ($annotations{$id}) {
		    print "self:\t$id\t$new_ontology{$id}{$p}{name}\t", scalar keys %{$annotations{$id}}, "\n";
		}
		else {
		    print "self:\t$id\t$new_ontology{$id}{$p}{name}\t0\n";
		}
		foreach (@{$new_ontology{$id}{$p}{children}}) {
		    my $term_count=0;
		    if ($annotations{$$_[0]}) {
			$term_count=scalar keys %{$annotations{$$_[0]}};
		    }
		    print "child:\t$$_[0]\t$ontology{$$_[0]}{name}\t$term_count\n";  # in aggregated trees relationship does not make sence - each term can have multiple paths (and relationships) to it
		    
	    	}
	    }
	    
	    foreach $p (sort {$a <=> $b} keys %{$new_ontology{$id}}) {
		print "Path\t$p of $path_count\n";
		print "parent_term_count:\t", scalar @{$new_ontology{$id}{$p}{parents}} - 1 , "\n"; # first one is self, not parent
		my $first_parent=0;
		my $proximal_parent=0;
		my $counter=0;
		foreach (reverse @{$new_ontology{$id}{$p}{parents}}) {
		    if ($counter == $#{$new_ontology{$id}{$p}{parents}} - 1) {
			$proximal_parent=1;
		    }
		    if ($$_[0] eq $id) {
			last;
		    }
		    
		    if ($$_[1] eq 'i') {
			print "path_parent:\tis_a\t$$_[0]\t$ontology{$$_[0]}{name}\n";
		    }
		    else {
			print "path_parent:\tpart_of\t$$_[0]\t$ontology{$$_[0]}{name}\n";
		    }
		    if ($proximal_parent) {
			foreach my $c (sort {lc $ontology{$$a[0]}{name} cmp lc $ontology{$$b[0]}{name}} @{$ontology{$$_[0]}{children}}) {
			    my $expand='';
			    if ($ontology{$$c[0]}{children}) {
				$expand='+';
			    }
			    if ($$c[0] eq $id) {
				if ($$c[1] eq 'i') {
				    print "self_in_path:\tis_a\t$$c[0]\t$ontology{$$c[0]}{name}\t$expand\n";
				}
				else {
				    print "self_in_path:\tpart_of\t$$c[0]\t$ontology{$$c[0]}{name}\t$expand\n";
				}
			    }
			    else {
				if ($$c[1] eq 'i') {
				    print "proximal_path_parent_child:\tis_a\t$$c[0]\t$ontology{$$c[0]}{name}\t$expand\n";
				}
				else {
				    print "proximal_path_parent_child:\tpart_of\t$$c[0]\t$ontology{$$c[0]}{name}\t$expand\n";
				}
			    }
			}
			$proximal_parent=0;
		    }
		    $counter++;
		}
	    }
	    print "\n";
	}
	close $client;
	
    }
    return 1;
}


sub stopServer {
    my $self=shift;
    my $serveraddr=$self->hostpath();
    close $self;
    unlink $serveraddr;
    return 1;
}





1
