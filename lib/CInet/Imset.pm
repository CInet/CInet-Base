# Integer-valued multiset. A mapping from domain-specific objects to integers.
# The domain-specificness requires a $cube object which translates objects
# to 1-based indices and back. Otherwise this is just a blessed arrayref.
package CInet::Imset;

use Modern::Perl 2018;
use Carp;

# Add a clone method
use parent 'Clone';

use overload (
    q[=]   => sub { shift->clone },
    q[+]   => \&add,
    q[neg] => \&neg,
    q[-]   => \&sub,
    q[*]   => \&mul,
    q[""]  => \&str,
);

# A cube must be given. All extra arguments are coordinates to set to 1.
sub new {
    my ($class, $cube, @elts) = @_;
    $cube = CUBE($cube) unless $cube->isa('CInet::Cube');
    # $cube->pack indices are 1-based. We keep them 1-based and leave
    # the $cube at the zeroth index, for the future.
    my $v = [ $cube, map { 0 } 1 .. $cube->size ];
    for my $elt (@elts) {
        $v->[$cube->pack($elt)] = 1;
    }
    bless $v, $class
}

sub is_zero {
    my $v = shift;
    for my $i (keys @$v) {
        next unless $i;
        return 0 if $v->[$i] != 0;
    }
    return 1;
}

sub cube {
    shift->[0]
}

sub ci {
    my ($self, $ijK) = @_;
    my $cube = $self->[0];
    $self * $cube->ci($ijK) == 0
}

sub relation {
    my $self = shift;
    my $cube = $self->[0];
    my $rel = join '', map { $self->ci($_) ? '0' : '1' } $cube->squares;
    CInet::Relation->new($cube, $rel)
}

sub permute {
    my ($self, $p) = @_;
    my $new = $self->clone;
    my $cube = $new->[0];
    for my $I ($cube->vertices) {
        my $i = $cube->pack($I);
        my $j = $cube->pack($cube->permute($p => $I));
        $new->[$j] = $self->[$i];
    }
    $new
}

sub dual {
    my $self = @_;
    my $new = $self->clone;
    my $cube = $new->[0];
    for my $I ($cube->vertices) {
        my $i = $cube->pack($I);
        my $j = $cube->pack($cube->dual($I));
        $new->[$j] = $self->[$i];
    }
    $new
}

sub swap {
    my ($self, $Z) = @_;
    my $new = $self->clone;
    my $cube = $new->[0];
    for my $I ($cube->vertices) {
        my $i = $cube->pack($I);
        my $j = $cube->pack($cube->swap($Z => $I));
        $new->[$j] = $self->[$i];
    }
    $new
}

sub add {
    my ($v, $w, $swap) = @_;

    my $u = $v->clone;
    for my $i (keys @$w) {
        next unless $i;
        $u->[$i] += $w->[$i];
    }
    $u
}

sub neg {
    my $u = shift->clone;
    for my $i (keys @$u) {
        next unless $i;
        $u->[$i] = - $u->[$i];
    }
    $u
}

sub sub {
    my ($v, $w, $swap) = @_;

    my $u = $v->clone;
    for my $i (keys @$w) {
        next unless $i;
        $u->[$i] -= $w->[$i];
    }
    $u
}

# Inner product
sub mul {
    my ($v, $w, $swap) = @_;
    my $d = 0;
    for my $i (keys @$v) {
        next unless $i;
        $d += $v->[$i] * $w->[$i];
    }
    $d
}

sub str {
    my $v = shift;
    join ' ', $v->@[1 .. $v->$#*]
}

":wq"
