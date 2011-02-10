#!/usr/bin/perl

use strict;
while (<>) {
  next unless /^==FROM==/../^==WHAT==/;
  next if /^==/;
  next unless /[a-zA-Z]/;
  print;
}
