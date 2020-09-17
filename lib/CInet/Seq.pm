package CInet::Seq;

use Modern::Perl 2018;
use Carp;

use Role::Tiny;

requires qw(next);

### Basic data processing

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

### Standard functional

sub map {
    CInet::Seq::Map->new(@_)
}

sub grep {
    CInet::Seq::Grep->new(@_)
}

sub uniq {
    CInet::Seq::Uniq->new(@_)
}

sub reduce {
    no strict 'refs';
    use Sub::Identify qw(stash_name);

    my ($self, $code, $id) = @_;
    my $a = $id // $self->next;
    return undef if not defined $a;

    # This code setting special globals $a and $b for the call to the
    # reducer is is borrowed from List::Util::PP but using Sub::Identify
    # because we can't rely on $code using globals from caller's package.
    my $pkg = stash_name($code);
    local *{"${pkg}::a"} = \$a;
    my $glob_b = \*{"${pkg}::b"};
    while (defined(my $b = $self->next)) {
        local *$glob_b = \$b;
        $a = $code->($a, $b);
    }
    $a
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

### Symmetry-related

sub modulo {
    CInet::Seq::Modulo->new(@_)
}

":wq"
