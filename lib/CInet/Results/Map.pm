use Modern::Perl 2018;
use Carp;

package CInet::Results::Map;

use Modern::Perl 2018;
use Carp;

use Role::Tiny::With;
with 'CInet::Results';

sub new {
    my ($class, $prev, $code) = @_;
    bless { prev => $prev, code => $code }, $class
}

sub next {
    my ($prev, $code) = shift->@{'prev', 'code'};
    my $x = $prev->next;
    return undef if not defined $x;
    local $_ = $x;
    $code->($x)
}

":wq"
