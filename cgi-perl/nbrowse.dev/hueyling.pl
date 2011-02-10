#!/usr/bin/perl

my $input = <STDIN>;
my $temp_dir = "/var/www/cgi-bin/NBrowse/temp_data";
chomp $input;
open(OUT, ">$temp_dir/$input.pl") || die "cannot create and append file $!";
print OUT "#!/usr/bin/perl\n";
print OUT "use CGI;\n";
print OUT "my \$query = new CGI;\n";
print OUT "my \$temp_dir = \"$temp_dir\";\n";
print OUT "my \$jar_file =  \"\$temp_dir/$input.jar\";\n";
print OUT "print \$query->header( -type => \"application/x-java-archive\");\n";
print OUT "print `cat \$jar_file`;\n";

print OUT "if (! -e \"$temp_dir/$input\"){\n";
print OUT "    open(OUT_temp, \">$temp_dir/$input\") || die \"cannot create and append file \$!\";\n";
print OUT "    print OUT_temp \"\";\n";
print OUT "    close(OUT_temp);\n";
print OUT "}else {\n";
print OUT "   `rm -f \$temp_dir/$input.pl`;\n";
print OUT "   `rm -f \$temp_dir/$input.jar`;\n";
print OUT "   `rm -f \$temp_dir/$input`;\n";
print OUT "}";

#print OUT "`rm -f \$temp_dir/$input.pl`;\n";
#print OUT "`rm -f \$temp_dir/$input.jar`;\n";
close(OUT);
