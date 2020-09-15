package CInet::Results::List;

use Modern::Perl 2018;
use Carp;

use Role::Tiny::With;
with 'CInet::Results';

sub new {
    my $class = shift;
    bless [ @_ ], $class
}

sub next {
    shift shift->@*
}

sub count {
    0+ shift->@*
}

":wq"
