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
    my ($prev, $code, $seen) = shift->@{'prev', 'code', 'seen'};
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
