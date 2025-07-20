#!/usr/bin/env perl
use warnings;
use strict;

use File::Basename qw(dirname);
use HTML::TreeBuilder;

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
    local $/ = undef;
    my $orig_html = <$fh>;
    my $html = $orig_html;

    my $tree = HTML::TreeBuilder->new();
    $tree->implicit_tags(1);
    $tree->implicit_body_p_tag(0);
    $tree->no_expand_entities(0);
    $tree->ignore_unknown(0);
    $tree->ignore_text(0);
    $tree->ignore_ignorable_whitespace(0);
    $tree->no_space_compacting(1);
    $tree->p_strict(0);
    $tree->store_comments(1);
    $tree->store_declarations(1);
    $tree->store_pis(1);
    $tree->parse_content($html);

    close($fh);
    my $fh_out;
    my $temp_filename;
    if ($opt_in_place) {
        if ($filename eq "-") {
            select(STDOUT);
            binmode(STDOUT, $layers);
        } else {
            ($fh_out, $temp_filename) = tempfile(DIR => dirname($filename));
            select($fh_out);
            binmode($fh_out, $layers);
        }
    }
}
