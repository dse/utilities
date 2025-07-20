package My::Color;
use warnings;
use strict;
use List::Util qw(max min);
use POSIX qw(ceil round);

use base "Exporter";
our @EXPORT = qw();
our @EXPORT_OK = qw(rgb_str_to_hsl_str
                    hsl_str_to_rgb_str
                    $RX_RGB_STRING
                    $RX_HSL_STRING);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

our $RX_FLOAT = qr{(?:(?:\d+(?:\.\d*))?|\.\d+)};

our $RX_RGB_STRING = qr{(?: \#
                            (?<rx>[[:xdigit:]])
                            (?<gx>[[:xdigit:]])
                            (?<bx>[[:xdigit:]])
                            (?<ax>[[:xdigit:]])?
                            (?![[:xdigit:]])
                        |
                            \#
                            (?<rxx>[[:xdigit:]]{2})
                            (?<gxx>[[:xdigit:]]{2})
                            (?<bxx>[[:xdigit:]]{2})
                            (?<axx>[[:xdigit:]]{2})?
                            (?![[:xdigit:]])
                        |
                            rgba?\(\s*
                            (?:(?<r>${RX_FLOAT})(?<r_pct>%)?)
                            (?:\s+|\s*,\s*)
                            (?:(?<g>${RX_FLOAT})(?<g_pct>%)?)
                            (?:\s+|\s*,\s*)
                            (?:(?<b>${RX_FLOAT})(?<b_pct>%)?)
                            (?:(?:\s+|\s*,\s*|\s*/\s*)
                               (?:(?<a>${RX_FLOAT})(?<a_pct>%)?))?
                            \s*\)
                        )}x;

our $RX_HSL_STRING = qr{(?: hsla?\(
                            \s*(?<h>${RX_FLOAT})(?:deg)?
                            (?:\s+|\s*,\s*)
                            (?:(?<s>${RX_FLOAT})(?<s_pct>%)?)
                            (?:\s+|\s*,\s*)
                            (?:(?<l>${RX_FLOAT})(?<l_pct>%)?)
                            (?:(?:\s+|\s*,\s*|\s*/\s*)
                               (?:(?<a>${RX_FLOAT})(?<a_pct>%)?))?
                            \s*\)
                        )}x;

sub parse_rgb_str {
    my ($str) = @_;
    if ($str =~ ${RX_RGB_STRING}) {
        my @plus = %+;
        my ($r, $g, $b, $a);
        if (defined $+{rx} && defined $+{gx} && defined $+{bx}) {
            $r = hex($+{rx}) / 15;
            $g = hex($+{gx}) / 15;
            $b = hex($+{bx}) / 15;
            $a = hex($+{ax}) / 15 if defined $+{ax};
        }
        elsif (defined $+{rxx} && defined $+{gxx} && defined $+{bxx}) {
            $r = hex($+{rxx}) / 255;
            $g = hex($+{gxx}) / 255;
            $b = hex($+{bxx}) / 255;
            $a = hex($+{axx}) / 255 if defined $+{axx};
        }
        elsif (defined $+{r} && defined $+{g} && defined $+{b}) {
            if (defined $+{r_pct}) {
                $r = clamp($+{r} / 100, 0, 1);
            } else {
                $r = clamp($+{r} / 255, 0, 1);
            }
            if (defined $+{g_pct}) {
                $g = clamp($+{g} / 100, 0, 1);
            } else {
                $g = clamp($+{g} / 255, 0, 1);
            }
            if (defined $+{b_pct}) {
                $b = clamp($+{b} / 100, 0, 1);
            } else {
                $b = clamp($+{b} / 255, 0, 1);
            }
            if (defined $a) {
                if (defined $+{a_pct}) {
                    $a = clamp($+{a} / 100, 0, 1);
                } else {
                    $a = clamp($+{a}, 0, 1);
                }
            }
        }
        if (defined $a) {
            return ($r, $g, $b, $a) if wantarray;
            return [$r, $g, $b, $a];
        }
        return ($r, $g, $b) if wantarray;
        return [$r, $g, $b];
    }
    return;
}

sub parse_hsl_str {
    my ($str) = @_;
    if ($str =~ ${$RX_HSL_STRING}) {
        my $h = $+{h_360} % 360;
        my $s = $+{s};
        my $l = $+{l};
        my $a = $+{a};
        $s /= 100 if defined $+{s_pct};
        $l /= 100 if defined $+{l_pct};
        $a /= 100 if defined $+{a_pct};
        if (defined $a) {
            return ($h, $s, $l, $a) if wantarray;
            return [$h, $s, $l, $a];
        }
        return ($h, $s, $l) if wantarray;
        return [$h, $s, $l];
    }
    return;
}

sub hsl_to_rgb {
    my ($h, $s, $l, $a) = @_;
    $h %= 360;
    $s = clamp($s, 0, 1);
    $l = clamp($l, 0, 1);
    $a = clamp($a, 0, 1) if defined $a;

    my $c = (1 - abs(2 * $l - 1) * $s);
    my $x = $c * (1 - abs(($h / 60) % 2 - 1));
    my $m = $l - $c / 2;
    my ($r, $g, $b);
    if (0 <= $h && $h < 60) {
        ($r, $g, $b) = ($c, $x, 0);
    } elsif (60 <= $h && $h < 120) {
        ($r, $g, $b) = ($x, $c, 0);
    } elsif (120 <= $h && $h < 180) {
        ($r, $g, $b) = (0, $c, $x);
    } elsif (180 <= $h && $h < 240) {
        ($r, $g, $b) = (0, $x, $c);
    } elsif (240 <= $h && $h < 300) {
        ($r, $g, $b) = ($x, 0, $c);
    } elsif (300 <= $h && $h < 360) {
        ($r, $g, $b) = ($c, 0, $x);
    }
    $r += $m;
    $g += $m;
    $b += $m;
    return ($r, $g, $b, $a);
}

sub clamp {
    my ($x, $min, $max) = @_;
    $x = $min if $x < $min;
    $x = $max if $x > $max;
    return $x;
}

sub hsl_str_to_rgb_str {
    my ($hsl_str) = @_;
    my ($r, $g, $b, $a) = hsl_str_to_rgb($hsl_str);
    my $rgb_str;
    if (defined $a) {
        $rgb_str = sprintf("#%02x%02x%02x%02x", round($r * 255), round($g * 255), round($b * 255), round($a * 255));
    } else {
        $rgb_str = sprintf("#%02x%02x%02x", round($r * 255), round($g * 255), round($b * 255));
    }
    # if ($verbose) {
    #     return sprintf("%s /* %s */", $rgb_str, $hsl_str);
    # }
    return $rgb_str;
}

sub rgb_str_to_hsl_str {
    my ($rgb_str) = @_;
    my ($h, $s, $l, $a) = rgb_str_to_hsl($rgb_str);
    my $hsl_str;
    if (defined $a) {
        $hsl_str = sprintf("hsla(%3d, %3d%%, %3d%%, %3d%%)",
                           $h, $s * 100, $l * 100, $a * 100);
    } else {
        $hsl_str = sprintf("hsl(%3d, %3d%%, %3d%%)",
                           $h, $s * 100, $l * 100);
    }
    # if ($verbose) {
    #     return sprintf("%s /* %s */", $hsl_str, $rgb_str);
    # }
    return $hsl_str;
}

sub rgb_str_to_hsl {
    my ($rgb_str) = @_;
    my ($r, $g, $b, $a) = parse_rgb_str($rgb_str);
    return if !defined $r || !defined $g || !defined $b;
    my (undef, undef, undef, $cmax, $cmin, $delta, $l) = compute($r, $g, $b);
    my $h = rgb_to_hsl_hue($r, $g, $b, $cmax, $cmin, $delta, $l);
    my $s = rgb_to_hsl_sat($r, $g, $b, $cmax, $cmin, $delta, $l);
    if (defined $a) {
        return ($h, $s, $l, $a) if wantarray;
        return [$h, $s, $l, $a];
    }
    return ($h, $s, $l) if wantarray;
    return [$h, $s, $l];
}

sub rgb_to_hsl_hue {
    my ($r, $g, $b, $cmax, $cmin, $delta, $l) = @_;
    if ($delta == 0) {
        return 0;
    }
    if ($cmax == $r) {
        return rotmod(60 * (($g - $b) / $delta));
    }
    if ($cmax == $g) {
        return rotmod(60 * (($b - $r) / $delta + 2));
    }
    if ($cmax == $b) {
        return rotmod(60 * (($r - $g) / $delta + 4));
    }
}

sub rgb_to_hsl_sat {
    my ($r, $g, $b, $cmax, $cmin, $delta, $l) = @_;
    if ($delta == 0) {
        return 0;
    }
    return $delta / (1 - abs(2 * $l - 1));
}

sub rotmod {
    my ($deg, $mod) = @_;
    $mod //= 360;
    if ($deg < 0) {
        return ($deg + ceil(-$deg / $mod) * $mod) % $mod;
    }
    return $deg % $mod;
}

sub compute {
    my ($r, $g, $b, $cmax, $cmin, $delta, $l) = @_;
    $cmax  //= max($r, $g, $b);
    $cmin  //= min($r, $g, $b);
    $delta //= $cmax - $cmin;
    $l     //= ($cmax + $cmin) / 2;
    return ($r, $g, $b, $cmax, $cmin, $delta, $l);
}

1;
