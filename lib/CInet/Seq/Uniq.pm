=encoding utf8

=head1 NAME

CInet::Seq::Uniq - Lazy stringy uniq on a Seq object

=head1 SYNOPSIS

    

=cut

# ABSTRACT: Lazy stringy uniq on a Seq object
package CInet::Seq::Uniq;

use Modern::Perl 2018;
use Carp;

=head1 DESCRIPTION

=cut

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

=head1 AUTHOR

Tobias Boege <tobs@taboege.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (C) 2020 by Tobias Boege.

This is free software; you can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

=cut

":wq"
