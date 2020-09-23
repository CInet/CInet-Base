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

### Utils

sub sort {
    no strict 'refs';
    use Sub::Identify qw(stash_name);
    use Sort::Key::Natural;

    my $self = shift;
    my %arg = @_;

    my @list = $self->list;
    if (exists $arg{with}) {
        my $code = $arg{with};
        my $pkg = stash_name($code);
        @list = sort {
            # Make $a and $b available to $code's package
            local *{"${pkg}::a"} = \$a;
            local *{"${pkg}::b"} = \$b;
            $code->($a, $b)
        } @list;
    }
    else {
        my $code = $arg{by} // sub { shift };
        @list = natkeysort { $code->($_) } @list;
    }
    CInet::Seq::List->new(@list)
}

sub decorate {
    my ($self, $code) = @_;
    $self->map(sub{ [ $_, $code->($_) ] })
}

### Symmetry-related

# TODO: Add something that does not reduce modulo a group
# but inflates each element to its entire orbit, but returns
# each orbit just once.

sub modulo {
    CInet::Seq::Modulo->new(@_)
}

":wq"
