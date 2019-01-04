package My::Text::GFMTable::Parser;
use warnings;
use strict;
use v5.10.0;

use Carp::Always;

use Moo;

has 'table' => (
    is => 'rw',
    default => sub {
        return undef;
    },
);
has 'handleLine' => (
    is => 'rw',
    default => sub {
        return sub {
        };
    },
);
has 'handleTable' => (
    is => 'rw',
    default => sub {
        return sub {
        };
    },
);

use List::Util qw(max);

sub parseLine {
    my ($self, $line) = @_;
    $line =~ s{\R\z}{};
    local $_ = $line;
    if (s{^\|\s*}{}) {
        if (!$self->table) {
            $self->table({
                rows => [],
                lines => [],
            });
        }
        my $table = $self->table;
        push(@{$table->{lines}}, $line);
        my @data = ();
        my $rx_cell = qr{(
                             (?:
                                 [^\`\|]+?
                             |
                                 (\`+).*?\2
                             )*?
                         )
                         \s*(?:$|\|\s*)}x;

        while ($_ =~ m{\S} && $_ =~ s{$rx_cell}{}) {
            push(@data, $1);
        }
        if (!defined $self->table->{headerRow}) {
            $self->table->{headerRow} = \@data;
        } elsif (!defined $self->table->{delimiterRow}) {
            $self->table->{delimiterRow} = \@data;
        } else {
            push(@{$self->table->{rows}}, \@data);
        }
    } else {
        if ($self->table) {
            my $ht = $self->handleTable;
            $self->$ht($self->table);
            $self->table(undef);
        }
        $self->handleLine->($self, $_);
    }
}

use Data::Dumper;

sub printTable {
    my ($self, $table) = @_;

    my $dr = $table->{delimiterRow};
    if (!defined $dr) {
        if (defined $table->{lines}) {
            print("$_\n") foreach @{$table->{lines}};
        }
        return;
    }
    my @align;
    foreach my $delimiter (@$dr) {
        if ($delimiter =~ m{^:-*:$}) {
            push(@align, 'center');
        } elsif ($delimiter =~ m{^-+:$}) {
            push(@align, 'right');
        } else {
            push(@align, 'left');
        }
    }

    my @r = (
        $table->{headerRow},
        @{$table->{rows}}
    );

    my $hcolumns = scalar @{$table->{headerRow}};
    my $dcolumns = scalar @{$table->{delimiterRow}};
    my @rcolumns = map { scalar @$_ } @{$table->{rows}};
    my $columns = max ($hcolumns, $dcolumns, @rcolumns);
    push(@align, ('left') x ($columns - $dcolumns));

    my @columnWidths = map {
        my $index = $_;
        max map { length $_->[$index] } @r
    } (0 .. ($columns - 1));

    my @h = @{$table->{headerRow}};

    my $hl = ('| ' . join(' | ', map { sprintf('%-*s', $columnWidths[$_], $h[$_] // '-') } (0 .. $#columnWidths)) . ' |');
    say $hl;

    my $dl = ('|' . join('|', map {
        my $a = $align[$_];
        my $w = $columnWidths[$_];
        $a eq 'center' ? (':' . '-' x $w . ':') :
            $a eq 'right' ? ('-' x ($w + 1) . ':') :
            (':' . '-' x ($w + 1));
    } (0 .. $#columnWidths)) . '|');
    say $dl;

    foreach my $row (@{$table->{rows}}) {
        my $l = ('| ' .
                     join(' | ', map {
                         my $w = $columnWidths[$_];
                         my $t = $row->[$_];
                         my $a = $align[$_];
                         $a eq 'right' ? sprintf('%*s', $w, $t) : sprintf('%-*s', $w, $t);
                     } (0 .. $#columnWidths))
                     . ' |');
        say $l;
    }
}

sub eof {
    my ($self) = @_;
    if ($self->table) {
        my $ht = $self->handleTable;
        $self->$ht($self->table);
        $self->table(undef);
    }
}

1;
