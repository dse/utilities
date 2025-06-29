#!/usr/bin/env perl
use warnings;
use strict;
use open IO => qw(:locale);

use HTML::Entities qw(decode_entities);
use File::Temp qw(tempfile);
use File::Basename qw(dirname);
use Getopt::Long;

our $opt_in_place;

Getopt::Long::Configure(qw(gnu_getopt));
Getopt::Long::GetOptions('i|in-place|inplace' => \$opt_in_place)
  or die(":-(\n");

my $blank_so_far = 1;
my $modified = 0;
my $new_file = 1;
my $OUT;                        # in-place
my $temp_filename;              # in-place

@ARGV = grep { !-B $_ } @ARGV;  # don't POSTPROCESS binary files

my %FILE;

while (<>) {
    warn("$ARGV\n");
    if ($opt_in_place && $new_file) {
        if ($ARGV eq '-') {
            select(STDOUT);
        } else {
            ($OUT, $temp_filename) = tempfile(DIR => dirname($ARGV));
            select($OUT);
        }
    }
    $new_file = 0;
    my $orig_line = $_;
    s{^(\s*)<!doctype}{<!DOCTYPE} if $blank_so_far;
    s{ class=""}{};
    $_ = decode_entities($_);

    $modified ||= ($_ ne $orig_line);
    $blank_so_far = 0 if /\S/;
} continue {
    print;
    if (eof) {
        if ($opt_in_place) {
            select(STDOUT);
            close($OUT);
            if ($modified) {
                rename($temp_filename, $ARGV);
            } else {
                unlink($temp_filename);
            }
        }
        undef $OUT;
        $blank_so_far = 1;
        $modified = 0;
        $new_file = 1;
    }
}
