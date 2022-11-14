#!/usr/bin/env perl
use warnings;
use strict;
use locale;

use Math::Trig qw(:pi);
use POSIX qw(trunc fmod round);

my $BOLD  = "\e[1m";
my $FAINT = "\e[2m";
my $REST  = "\e[m";

for (my $i = 100; $i <= 1000; $i += 1) {
    my $log = (log($i) - log(100)) / log(10);
    my $rad = $log * pi2;
    my $sin = sin($rad);
    my $cos = cos($rad);

    my $highlightSin = abs($sin) < abs($cos);
    my $highlightCos = !$highlightSin;

    print(fmt(
        "D = %<D>6.3f  |  L = %<L>6.4f  |  %<H1>ssin = %<sin>s%<R1>s  |  %<H2>scos = %<cos>s%<R2>s\n",
        D => $i / 100,
        L => $log,
        sin => frac($sin * 10, 16),
        cos => frac($cos * 10, 16),
        H1 => $highlightSin ? $BOLD : '',
        R1 => $highlightSin ? $REST : '',
        H2 => $highlightCos ? $BOLD : '',
        R2 => $highlightCos ? $REST : '',
    ));
}

sub frac {
    my ($x, $sixteen) = @_;
    my $sign = $x < 0 ? -1 : 1;
    my $trunc = trunc(abs($x));
    my $fmod  = fmod(abs($x), 1);

    my $sixteenths = round($fmod * $sixteen);
    my $gcd        = gcd($sixteenths, $sixteen);
    my $num        = $sixteenths / $gcd;
    my $denom      = $sixteen    / $gcd;
    my $int        = $trunc;
    if ($num == 1 && $denom == 1) {
        $int += 1;
        $num = 0;
    }
    my $result = sprintf('%s%2d ', $sign < 0 ? '-' : ' ', $int);
    if ($num) {
        $result .= sprintf('%2d/%-2d', round($num), round($denom));
    } else {
        $result .= '     ';
    }
    return $result;
}

sub gcd {
    my ($a, $b) = @_;
    ($a, $b) = ($b, $a) if $a > $b; # a < b
    if ($a == 0 || $b == 0) {
        return 1;
    }
    while (1) {
        ($a, $b) = ($b % $a, $a);
        if ($a == 0) {
            return $b;
        }
    }
}
sub lcm {
    my ($a, $b) = @_;
    return $a * $b / gcd($a, $b);
}

sub fmt {
    my ($fmt, %args) = @_;
    my @args;
    $fmt =~ s{%<(?<name>[^<>]+)>}
             {push(@args, $args{$+{name}}); '%'}ge;
    return sprintf($fmt, @args);
}
