#!/usr/bin/env perl
use warnings;
use strict;
use feature 'say';

while (<>) {
    s{\R\z}{};
    $_ = prependExtension($_, 'foo');
    say $_;
}

sub prependExtension {
    my ($filename, $extension) = @_;
    if ($filename =~ s{([^.\\/])(\.+[^.\\/]+)$}{$1.$extension$2}) {
        return $filename;
    }
    return $filename . '.' . $extension;
}
