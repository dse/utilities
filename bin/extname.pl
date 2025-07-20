#!/usr/bin/env perl
use warnings;
use strict;
foreach my $arg (@ARGV) {
    printf("arg is '%s'\n", $arg);
    my $ext = extname($arg);
    printf("    ext is '%s'\n", $ext);
}
sub is_win_device_root {
    my $char = shift;
    my $code = ord($char);
    return ($code >= 65 && $code <= 90) || ($code >= 97 && $code <= 122);
}
sub is_path_separator {
    my $char = shift;
    return $char eq '/' || $char eq '\\';
}
sub is_posix_path_separator {
    my $char = shift;
    return $char eq '/';
}
sub is_win_path_separator {
    my $char = shift;
    return $char eq '/' || $char eq '\\';
}
