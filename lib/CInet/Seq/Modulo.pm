use Modern::Perl 2018;
use Carp;

package CInet::Seq::Modulo;

use Modern::Perl 2018;
use Carp;

use Role::Tiny::With;
with 'CInet::Seq';

use CInet::Symmetry;

sub new {
    my ($class, $prev, $group) = @_;
    bless { prev => $prev, group => $group, hash => { } }, $class
}

sub next {
    my ($prev, $group, $hash) = shift->@{'prev', 'group', 'hash'};
    # Hash contains full orbits of every relation that we returned.
    while (defined(my $x = $prev->next)) {
        next if $hash->{$x->str};
        # $x is new. Maintain the invariant before returning it.
        $hash->{$x->act($_)->str}++ for @$group;
        return $x;
    }
    undef
}

":wq"
