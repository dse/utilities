package My::Text::Table;
use utf8;
use warnings;
use strict;
use v5.10.0;

use List::Util qw(max);
use Data::Dumper;
use Text::Tabs;

use Moo;
has 'headerArray' => (
    is => 'rw',
    default => undef,
);
has 'rows' => (
    is => 'rw',
    default => sub { return []; },
);
has 'footerArray' => (
    is => 'rw',
    default => undef,
);
has 'hasSolidHorizontalBorders' => (
    is => 'rw',
    default => 0,
);
has 'hasRowBorders' => (
    is => 'rw',
    default => 0,
);
has 'hasVerticalBorders' => (
    is => 'rw',
    default => 0,
);
has 'hasExcelHeader' => (
    is => 'rw',
    default => 0,
);
has 'useUnicode' => (
    is => 'rw',
    default => 0,
);
has 'inputFieldSeparator' => (
    is => 'rw',
);
has 'outputFieldSeparator' => (
    is => 'rw',
);
has 'columnAlignment' => (
    is => 'rw',
    default => sub { return []; },
);

sub header {
    my ($self, @header) = @_;
    $self->headerArray(\@header);
}

sub footer {
    my ($self, @footer) = @_;
    $self->footerArray(\@footer);
}

sub no_header {
    goto &noHeader;
}
sub noHeader {
    my ($self) = @_;
    $self->headerArray(undef);
}

sub no_footer {
    goto &noFooter;
}
sub noFooter {
    my ($self) = @_;
    $self->footerArray(undef);
}

sub add {
    goto &addRow;
}
sub addRow {
    my ($self, @data) = @_;
    push(@{$self->rows}, \@data);
}

sub add_rows {
    goto &addRows;
}
sub addRows {
    my ($self, @rows) = @_;
    push(@{$self->rows}, grep { ref($_) eq "ARRAY" } @rows);
}

sub reset_data {
    goto &resetData;
}
sub resetData {
    my ($self) = @_;
    $self->headerArray(undef);
    $self->rows([]);
    $self->footerArray(undef);
}

sub setColumnAlignment {
    my ($self, $column, $alignment) = @_;
    return $self->columnAlignment->[$column] = $alignment;
}
sub getColumnAlignment {
    my ($self, $column) = @_;
    return $self->columnAlignment->[$column] // 'left';
}

sub as_string {
    goto &asString;
}
sub asString {
    my ($self) = @_;
    my $numColumns = $self->getNumberOfColumns();

    my $saveHeaderArray = $self->headerArray;

    if ($self->hasExcelHeader) {
        my @header = ("A" .. "Z");
        if ($numColumns > 26) {
            push(@header, "AA" .. "ZZ");
        }
        if ($numColumns > (26 + 26 * 26)) {
            push(@header, "AAA" .. "ZZZ");
        }
        splice(@header, $numColumns);
        $self->headerArray(\@header);
    }

    my @columnWidths = $self->getColumnWidths();
    my @rows = (($self->headerArray || ()), @{$self->rows}, ($self->footerArray || ()));
    my $firstDataRow = $self->headerArray ? 1 : 0;
    my $lastDataRow  = $self->footerArray ? (scalar(@rows) - 2) : (scalar(@rows) - 1);
    my $result = "";
    if ($self->hasVerticalBorders) {
        $result .= $self->getTopBorderString();
    }
    for (my $j = 0; $j < scalar @rows; $j += 1) {
        my $row = $rows[$j];
        if (defined $self->footerArray && $row eq $self->footerArray) {
            $result .= $self->getHeaderFooterBorderString();
        }
        my @row = map { [expand(split(qr{\R}, $_))] } @$row;
        my $lines = max map { scalar @$_ } @row;
        if (!$lines) {
            @row = ([" "]);
            $lines = 1;
        }
        for (my $i = 0; $i < $lines; $i += 1) {
            my ($join, $left, $right);
            if (defined $self->outputFieldSeparator) {
                $join  = $self->outputFieldSeparator;
                $left  = "";
                $right = "";
            } elsif ($self->useUnicode) {
                $join  = $self->hasVerticalBorders ? " │ " : "  ";
                $left  = $self->hasVerticalBorders ? "│ " : "";
                $right = $self->hasVerticalBorders ? " │" : "";
            } else {
                $join  = $self->hasVerticalBorders ? " | " : "  ";
                $left  = $self->hasVerticalBorders ? "| " : "";
                $right = $self->hasVerticalBorders ? " |" : "";
            }
            $result .= $left . join($join, map {
                $self->getColumnString($_, $row[$_][$i]);
            } (0 .. ($numColumns - 1))) . $right . "\n";
        }
        if ($self->hasRowBorders && $j >= $firstDataRow && $j < $lastDataRow) {
            $result .= $self->getRowBorderString();
        }
        if (defined $self->headerArray && $row eq $self->headerArray) {
            $result .= $self->getHeaderFooterBorderString();
        }
    }
    if ($self->hasVerticalBorders) {
        $result .= $self->getBottomBorderString();
    }

    $self->headerArray($saveHeaderArray);

    return $result;
}

use POSIX qw(round);

sub getColumnString {
    my ($self, $column, $string) = @_;
    $string //= '';
    my $alignment = $self->getColumnAlignment($column);
    my $width = $self->getColumnWidth($column);
    if ($alignment eq 'right') {
        return sprintf('%*s', $width, $string);
    }
    if ($alignment eq 'center') {
        my $length = length($string);
        my $diff = round($length + ($width - $length) / 2);
        return sprintf('%-*s', $width, sprintf('%*s', $length + $diff, $string));
    }
    return sprintf('%-*s', $width, $string);
}

sub top_border {
    goto &getTopBorderString;
}
sub getTopBorderString {
    my ($self) = @_;
    my $result = "";
    my @columnWidths = $self->getColumnWidths();
    my ($join, $left, $right, $h);
    if (defined $self->outputFieldSeparator) {
        $join  = "-" x length $self->outputFieldSeparator;
        $left  = "";
        $right = "";
        $h     = "-";
    } elsif ($self->useUnicode) {
        $join  = "─┬─";
        $left  = "┌─";
        $right = "─┐";
        $h     = "─";
    } else {
        $join  = "-.-";
        $left  = ".-";
        $right = "-.";
        $h     = "-";
    }
    $result .= $left . join($join, map { $h x $_ } @columnWidths) . $right . "\n";
    return $result;
}

sub bottom_border {
    goto &getBottomBorderString;
}
sub getBottomBorderString {
    my ($self) = @_;
    my $result = "";
    my @columnWidths = $self->getColumnWidths();
    my ($join, $left, $right, $h);
    if (defined $self->outputFieldSeparator) {
        $join  = "-" x length $self->outputFieldSeparator;
        $left  = "";
        $right = "";
        $h     = "-";
    } elsif ($self->useUnicode) {
        $join  = "─┴─";
        $left  = "└─";
        $right = "─┘";
        $h     = "─";
    } else {
        $join  = "-'-";
        $left  = "'-";
        $right = "-'";
        $h     = "-";
    }
    $result .= $left . join($join, map { $h x $_ } @columnWidths) . $right . "\n";
    return $result;
}

sub header_footer_border {
    goto &getHeaderFooterBorderString;
}
sub getHeaderFooterBorderString {
    my ($self) = @_;
    my $result = "";
    my @columnWidths = $self->getColumnWidths();
    my ($join, $left, $right, $h);
    if (defined $self->outputFieldSeparator) {
        $join  = "=" x length $self->outputFieldSeparator;
        $left  = "";
        $right = "";
        $h     = "=";
    } elsif ($self->useUnicode) {
        $join  = $self->hasVerticalBorders ? "═╪═" : $self->hasSolidHorizontalBorders ? "══" : "  ";
        $left  = $self->hasVerticalBorders ? "╞═" : "";
        $right = $self->hasVerticalBorders ? "═╡" : "";
        $h     = "═";
    } else {
        $join  = $self->hasVerticalBorders ? "=|=" : $self->hasSolidHorizontalBorders ? "==" : "  ";
        $left  = $self->hasVerticalBorders ? "|=" : "";
        $right = $self->hasVerticalBorders ? "=|" : "";
        $h     = "=";
    }
    $result .= $left . join($join, map { $h x $_ } @columnWidths) . $right . "\n";
    return $result;
}

sub row_border {
    goto &getRowBorderString;
}
sub getRowBorderString {
    my ($self) = @_;
    my $result = "";
    my @columnWidths = $self->getColumnWidths();
    my ($join, $left, $right, $h);
    if (defined $self->outputFieldSeparator) {
        $join  = "-" x length $self->outputFieldSeparator;
        $left  = "";
        $right = "";
        $h     = "-";
    } elsif ($self->useUnicode) {
        $join  = $self->hasVerticalBorders ? "─┼─" : $self->hasSolidHorizontalBorders ? "──" : "  ";
        $left  = $self->hasVerticalBorders ? "├─" : "";
        $right = $self->hasVerticalBorders ? "─┤" : "";
        $h     = "─";
    } else {
        $join  = $self->hasVerticalBorders ? "-|-" : $self->hasSolidHorizontalBorders ? "--" : "  ";
        $left  = $self->hasVerticalBorders ? "|-" : "";
        $right = $self->hasVerticalBorders ? "-|" : "";
        $h     = "-";
    }
    $result .= $left . join($join, map { $h x $_ } @columnWidths) . $right . "\n";
    return $result;
}

sub numColumns {
    goto &getNumberOfColumns;
}
sub getNumberOfColumns {
    my ($self) = @_;
    my @numColumns = map { scalar @$_ }
        (($self->headerArray || ()),
         @{$self->rows},
         ($self->footerArray || ()));
    my $numColumns = max @numColumns;
    return $numColumns;
}

sub column_widths {
    goto &getColumnWidths;
}
sub getColumnWidths {
    my ($self) = @_;
    return map { $self->getColumnWidth($_) }
        (0 .. ($self->getNumberOfColumns() - 1));
}

sub column_width {
    goto &getColumnWidth;
}
sub getColumnWidth {
    my ($self, $column) = @_;
    my @column =
        map { (scalar @$_ > $column) ? $_->[$column] : () }
        (($self->headerArray || ()),
         @{$self->rows},
         ($self->footerArray || ()));
    @column = map { $_ =~ m{\R} ? split(qr{\R}, $_) : $_ } @column;
    @column = expand(@column);
    return max map { length $_ } @column;
}

sub split {
    my ($self, $data) = @_;
    return split(qr{\R}, $data);
}

1;
