package CInet::Results;

use Modern::Perl 2018;
use Carp;

use Role::Tiny;

requires qw(next);

sub inhabited {
    defined shift->next
}

sub list {
    my $self = shift;
    my (@list, $count);
    while (defined(my $x = $self->next)) {
        push @list, $x if wantarray;
        $count++;
    }
    wantarray ? @list : $count // 0
}

sub count {
    scalar shift->list
}

sub map {
    CInet::Results::Map->new(@_)
}

sub grep {
    CInet::Results::Grep->new(@_)
}

sub any {
    my ($self, $code) = @_;
    $code //= sub { 1 };
    $self->grep($code)->inhabited
}

sub all {
    my ($self, $code) = @_;
    $code //= sub { 1 };
    not $self->grep(sub{ not $code->($_) })->inhabited
}

sub none {
    my ($self, $code) = @_;
    $code //= sub { 1 };
    not $self->any($code)
}

":wq"
