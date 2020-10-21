=encoding utf8

=head1 NAME

CInet::Seq::Modulo - Lazy symmetry reduction on a Seq object

=head1 SYNOPSIS

    

=cut

# ABSTRACT: Lazy symmetry reduction on a Seq object
package CInet::Seq::Modulo;

use Modern::Perl 2018;
use Carp;

=head1 DESCRIPTION

=cut

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
        next if $seen->{$x};
        # $x is new. Maintain the invariant before returning it.
        $seen->{$x->act($_)}++ for @$group;
        return $x;
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
