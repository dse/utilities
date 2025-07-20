#!/usr/bin/env perl
use warnings;
use strict;

use HTML::Entities qw(decode_entities);
use File::Temp qw(tempfile);
use File::Basename qw(dirname);
use Getopt::Long;

use HTML::Tagset;
use HTML::Valid::Tagset;
use HTML::TreeBuilder;
use HTML::Selector::XPath 0.20 qw(selector_to_xpath);
use HTML::TreeBuilder::XPath;
use HTML::Entities qw(encode_entities);

our $layers = ":encoding(UTF-8)";

our $opt_in_place;
our @opt_exclude;

Getopt::Long::Configure(qw(gnu_getopt));
Getopt::Long::GetOptions(
    "i|in-place|inplace" => \$opt_in_place,
    "exclude=s@" => \@opt_exclude,
) or die(":-(\n");

@ARGV = grep { !-B $_ } @ARGV;  # don't POSTPROCESS binary files

foreach my $filename (@ARGV) {
    my $blank_so_far = 1;
    my $modified = 0;
    my $new_file = 1;
    my $fh_out;                    # in-place
    my $temp_filename;          # in-place
    my $fh;

    if ($filename eq "-") {
        $fh = \*STDIN;
    } else {
        if (!open($fh, "<${layers}", $filename)) {
            warn("$filename: $!\n");
            next;
        }
    }
    binmode($fh, $layers);

    while (defined($_ = <$fh>)) {
        if ($opt_in_place && $new_file) {
            if ($filename eq "-") {
                select(STDOUT);
                binmode(STDOUT, $layers);
            } else {
                ($fh_out, $temp_filename) = tempfile(DIR => dirname($filename));
                select($fh_out);
                binmode($fh_out, $layers);
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
                binmode(STDOUT, $layers);
                close($fh_out);
                if ($modified) {
                    rename($temp_filename, $filename);
                } else {
                    unlink($temp_filename);
                }
            }
            undef $fh_out;
            $blank_so_far = 1;
            $modified = 0;
            $new_file = 1;
        }
    }
}
