#!/usr/bin/env perl
use warnings;
use strict;
use Getopt::Long;
use IO::Handle;
use Data::Dumper qw(Dumper);
use open IO => qw(:locale);

our $opt_inverse = 0;
our $opt_verbose = 0;
Getopt::Long::Configure(qw(gnu_getopt));
Getopt::Long::GetOptions(
    'x|inverse' => \$opt_inverse,
    'v|verbose+' => \$opt_verbose,
) or die(":-(\n");

our $COLOR_RX = qr{
    (?:
        \e\[
            (?:[0-9]+
               (?:;[0-9]+)*
              |(?:38|48)
               (?::[0-9]*)*)
        m
    )
}x;

our $DIFF_TYPE_1 = qr{^${COLOR_RX}*[-+]};
our $DIFF_TYPE_2 = qr{${COLOR_RX}(?:\[-|\{\+)};
our $DIFF_TYPE_3 = qr{(?:-\]|\+\})${COLOR_RX}};

our @diff_header;
our @ctx;
our $after_count = 0;
our $in_diff_header = 0;
our $blank_count = 0;
our $hunk_header;
our @lines;

$Data::Dumper::Terse = 1;
$Data::Dumper::Useqq = 1;

while (<>) {
    s{\R\z}{};
    my $this_line = { line_nr => $., text => $_, print => 0 };
    push(@lines, $this_line);

    if (!/\S/) {
        $blank_count += 1;
        if ($blank_count >= 2) {
            $this_line->{type} = 'excess-blank';
            $this_line->{neverprint} = 1;
            next;
        }
        $this_line->{type} = 'blank';
        next;
    } else {
        $blank_count = 0;
    }
    if (ignored($_)) {
        $this_line->{type} = 'ignored';
        next;
    }
    if (/^${COLOR_RX}*diff /) { # start of diff header
        $after_count = 0;
        $in_diff_header = 1;
        @ctx = ();
        @diff_header = ($this_line);
        $this_line->{type} = 'diff-header';
        next;
    }
    if (/^${COLOR_RX}*@@\s+/) { # hunk header (ends diff header, we wait tp)
        @ctx = ();
        $in_diff_header = 0;
        $after_count = 0;
        $this_line->{type} = 'hunk-header';
        $hunk_header = $this_line;
        next;
    }
    if ($in_diff_header) {
        $this_line->{type} = 'diff-header';
        push(@diff_header, $this_line);
        next;
    }

    if (m{$DIFF_TYPE_1} || m{$DIFF_TYPE_2} || m{$DIFF_TYPE_3}) {
        # line containing differences
        $hunk_header->{print} = 1;
        foreach my $line (@diff_header) {
            $line->{print} = 1;
        }
        @diff_header = ();
        if (scalar @ctx) {
            $hunk_header->{print} = 1;
            foreach my $line (@ctx) {
                $line->{print} = 1;
            }
            @ctx = ();
        }
        $this_line->{type} = 'diff';
        $this_line->{print} = 1;
        print_lines();
        $after_count = 3;
        next;
    }
    if ($after_count) {
        $this_line->{type} = 'after-ctx';
        $this_line->{print} = 1;
        print_lines();
        $after_count -= 1;
        next;
    }
    # collect context lines
    push(@ctx, $this_line);
    $this_line->{type} = 'before-ctx';
    # $this_line->{print} = 1;
    while (scalar @ctx > 3) { # if more than three collected, a new hunk will forthcome
        $ctx[0]->{type} = 'out-of-ctx';
        shift(@ctx);
    }
} continue {
    if (eof) {
        print_lines();
        @diff_header = ();
        @ctx = ();
        $after_count = 0;
        $in_diff_header = 0;
        $blank_count = 0;
        undef $hunk_header;
        @lines = ();
        undef $.;
    }
}

sub print_line {
    my ($line) = @_;
    if ($opt_verbose) {
        printf("                    - %s", Dumper($_));
        print ($line->{neverprint} ? "NP " : "   ");
        printf ("%-16s ", $line->{type});
        print ("| ", $line->{text}, "\n");
        return;
    }
    return if $line->{neverprint};
    if (($opt_inverse && !$line->{print}) ||
        (!$opt_inverse && $line->{print})) {
        printf("%s\n", $line->{text});
    }
}

sub print_lines {
    while (scalar @lines) {
        my $line = shift @lines;
        print_line($line);
    }
}

sub ignored {
    my ($str) = @_;
    return 1 if $str =~ m{assets/js/main\.bundle\.js};
    return 1 if $str =~ m{assets/css/main\.css};
    return 1 if $str =~ m{_astro/page\.DNAVqjDn\.js};
    return;
}
