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
    bless { prev => $prev, group => $group, seen => { } }, $class
}

sub next {
    my ($prev, $group, $seen) = shift->@{'prev', 'group', 'seen'};
    # Hash contains full orbits of every relation that we returned.
    while (defined(my $x = $prev->next)) {
        next if $seen->{$x->str};
        # $x is new. Maintain the invariant before returning it.
        $seen->{$x->act($_)->str}++ for @$group;
        return $x;
    }
    # Clean up cache
    undef($seen->%*);
    undef
}

":wq"
