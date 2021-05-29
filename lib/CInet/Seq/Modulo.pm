=encoding utf8

=head1 NAME

CInet::Seq::Modulo - Lazy symmetry reduction on a Seq object

=head1 SYNOPSIS

    my $mod = $seq->modulo(SymmetricGroup);

=cut

# ABSTRACT: Lazy symmetry reduction on a Seq object
package CInet::Seq::Modulo;

use Modern::Perl 2018;
use Carp;

=head1 DESCRIPTION

This class adapts a given L<CInet::Seq> object by reducing the
L<CInet::Relation> objects enumerated by it modulo a symmetric
group from L<CInet::Symmetry>.

Only the first incoming element of every orbit is passed through.
The implementation uses a hash to cache stringifications of all
the seen orbits. The cache is cleared immediately after the sequence
is exhausted, before the final C<undef> is returned.

This class implements the L<CInet::Seq> role.

=cut

use Role::Tiny::With;
with 'CInet::Seq';

=head3 new

    my $mod = CInet::Seq::Modulo->new($group);

Constructs a CInet::Seq::Modulo object which reduces incoming elements
from the C<$source> Seq modulo a C<$group> as presented in L<CInet::Symmetry>.

You can pass the C<CInet::Symmetry::Type> object returned from calling
one of the symmetry group subs without arguments into this constructor.
In that case the group will be resolved when the first element's orbit
must be computed.

Only the first element of any orbit is forwarded to the consumer.

=cut

sub new {
    my ($class, $src, $group) = @_;
    bless { src => $src, group => $group, seen => { } }, $class
}

=head2 Implementation of CInet::Seq

=head3 next

    my $elt = $seq->next;
    last if not defined $elt;

Pull elements from the source Seq until the first time one of them
belongs to a hitherto unknown orbit under the group. Return either
that element or C<undef> if the source is exhausted in the process.

The cache always contains the stringifications of elements of
B<entire> orbits of the group. Therefore, a test for a seen orbit
is very fast. When an element of an unseen orbit is discovered,
its entire orbit is computed and added to the cache. For this, each
group element is passed into the object's C<< ->act >> method.

The cache of seen strings is cleared immediately after the source
is exhausted.

=cut

sub next {
    my ($src, $group, $seen) = shift->@{'src', 'group', 'seen'};
    # Hash contains full orbits of every relation that we returned.
    while (defined(my $x = $src->next)) {
        next if $seen->{$x};
        # Resolve the group if only a group type was given.
        $group = $group->($x) if $group->isa('CInet::Symmetry::Type');
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
