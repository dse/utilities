package My::File::Wildcard;
use warnings;
use strict;

use base "Exporter";
our @EXPORT = qw();
our @EXPORT_OK = qw(wildcard_to_regexp);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

sub wildcard_to_regexp {
    my ($pattern) = @_;
    $pattern =~ s{.}{
        $& eq "*" ? "[^/]*" :
        $& eq "?" ? "[^/]" :
        quotemeta($&)
    }gex;
    $pattern =~ s{/+}{/}g;
    print("$pattern\n");
    return qr{^${pattern}$};
}

1;
