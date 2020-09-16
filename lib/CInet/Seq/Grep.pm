use Modern::Perl 2018;
use Carp;

package CInet::Seq::Grep;

use Modern::Perl 2018;
use Carp;

use Role::Tiny::With;
with 'CInet::Seq';

sub new {
    my ($class, $prev, $code) = @_;
    bless { prev => $prev, code => $code }, $class
}

sub next {
    my ($prev, $code) = shift->@{'prev', 'code'};
    while (1) {
        my $x = $prev->next;
        return undef if not defined $x;
        local $_ = $x;
        return $x if $code->($x);
    }
}

":wq"
