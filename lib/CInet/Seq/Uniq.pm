use Modern::Perl 2018;
use Carp;

package CInet::Seq::Uniq;

use Modern::Perl 2018;
use Carp;

use Role::Tiny::With;
with 'CInet::Seq';

sub new {
    my ($class, $prev, $code) = @_;
    $code //= sub { "". $_ };
    bless { prev => $prev, code => $code, seen => { } }, $class
}

sub next {
    my ($prev, $code) = shift->@{'prev', 'code'};
    while (1) {
        my $x = $prev->next;
        return undef if not defined $x;
        local $_ = $x;
        return $x if $code->($x);
    }
    my ($prev, $code, $seen) = shift->@{'prev', 'code', 'seen'};
    # Hash contains full orbits of every relation that we returned.
    while (defined(my $x = $prev->next)) {
        local $_ = $x;
        my $str = $code->($x);
        return $x if not $seen->{$str}++;
    }
    # Clean up cache
    undef($seen->%*);
    undef
}

":wq"
