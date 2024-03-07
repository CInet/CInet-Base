=encoding utf8

=head1 NAME

CInet::Seq::List - Reified list representation of a Seq

=head1 SYNOPSIS

    my $list = CInet::Seq::List->new(@elts);
    say $list->count, " elements left:";
    while (defined(my $elt = $list->next)) {
        say "got $elt";
    }

=cut

# ABSTRACT: Reified list representation of a Seq
package CInet::Seq::List;

use Modern::Perl 2018;
use Carp;

=head1 DESCRIPTION

A C<CInet::Seq:::List> object represents a Seq with a reified list
of all its values. Whenever an operation cannot be performed lazily
and there is no other efficient overload, the lazy Seq decays into
a Seq::List object, which provides the Seq interface on a complete
in-memory array.

You usually want to avoid creating an instance of this type when
dealing with large amounts of lazily produced data. Methods which
have to reify will indicate this in their documentation.

This class implements the L<CInet::Seq> role.

=cut

use Role::Tiny::With;
with 'CInet::Seq';

=head2 Methods

=head3 new

    my $list = CInet::Seq::List->new(@elts);

Constructs a new CInet::Seq::List object from the given array.

=cut

sub new {
    my $class = shift;
    bless [ @_ ], $class
}

=head3 description

    my $str = $seq->description;

=cut

sub description {
    use Scalar::Util qw(blessed);
    my $self = shift;
    'Materialized sequence of type ' . blessed($self) . ' and size ' . $self->count
}

=head2 Implementation of CInet::Seq

=head3 next

    my $elt = $seq->next;
    last if not defined $elt;

Return the next unconsumed element from the backing array or
C<undef> if no elements are left.

=cut

sub next {
    shift shift->@*
}

=head3 count

    my $count = $seq->count;

Return how many elements are left unconsumed in this Seq.
Unlike the default C<count> implementation of L<CInet::Seq>,
this method can quickly return the answer without exhausting
all the elements. You can continue iterating where you left
off after calling this method.

=cut

sub count {
    0+ shift->@*
}

=head1 AUTHOR

Tobias Boege <tobs@taboege.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (C) 2020 by Tobias Boege.

This is free software; you can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

=cut

":wq"
