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
    q[""]  => \&str,
);

# A cube must be given. All extra arguments are coordinates to set to 1.
sub new {
    my ($class, $cube, @elts) = @_;
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

sub str {
    my $v = shift;
    join ' ', $v->@[1 .. $v->$#*]
}

":wq"
