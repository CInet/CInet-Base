package CInet::Seq;

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
    CInet::Seq::Map->new(@_)
}

sub grep {
    CInet::Seq::Grep->new(@_)
}

sub first {
    my ($self, $code) = @_;
    $code //= sub { 1 };
    $self->grep($code)->next
}

sub any {
    my $self = shift;
    defined $self->first(@_)
}

sub none {
    my $self = shift;
    not defined $self->first(@_)
}

sub all {
    my ($self, $code) = @_;
    $code //= sub { 1 };
    not defined $self->first(sub{ not $code->($_) })
}

":wq"
