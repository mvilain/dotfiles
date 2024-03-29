#!/usr/bin/env perl

# Usage: rename perlexpr [files]

($op = shift) || die "Usage: rename perlexpr [filenames]\n";
if(!@ARGV) {
   @ARGV = <STDIN>;
   chop (@ARGV);
}
for (@ARGV) {
   $was = $_;
   eval $op;
   die $@ if $@;
   rename($was, $_) unless $was eq $_;
}
