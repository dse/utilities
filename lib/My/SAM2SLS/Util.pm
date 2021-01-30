package My::SAM2SLS::Util;
use warnings;
use strict;
use v5.10.0;
use utf8;

sub newHash {
    my ($self) = @_;
    my $hash = {};
    tie(%$hash, 'Tie::IxHash');
    return $hash;
}

sub cleanUpObject {
    my ($o) = @_;
    if (ref $o eq 'HASH') {
        my @keys = keys %$o;
        foreach my $key (@keys) {
            my $value = $o->{$key};
            if (ref $value eq 'HASH') {
                cleanUpObject($value);
            }
            if (ref $value eq 'HASH' && !scalar keys %$value) {
                delete $o->{$key};
            }
            if (ref $value eq 'ARRAY' && !scalar @$value) {
                delete $o->{$key};
            }
        }
    }
}

1;
