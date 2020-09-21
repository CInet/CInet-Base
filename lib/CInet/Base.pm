=encoding utf8

=head1 NAME

CInet::Base - The basis for computations on CI structures

=head1 SYNOPSIS

    # Imports CInet::{Cube,Relation,Symmetry,Seq}
    use CInet::Base;

=head2 VERSION

This document describes CInet::Base v1.0.0.

=cut

# ABSTRACT: The basis for computations on CI structures
package CInet::Base;

our $VERSION = "v1.0.0";

=head1 DESCRIPTION

This module imports all modules of the CInet::Base distribution.
Here we given an overview of what and why these modules are and how
they interact. For more information, see the specific documentation
of each module.

=head2 Brief introduction

Conditional independence structures are combinatorial abstractions of the
ternary relations of stochastic conditional independence on a vector of
finitely many random variables. If the vector is indexed by a set C<N>
and we have three disjoint subsets C<I>, C<J> and C<K>, then this
relation is usually written

    I ⫫ J | K

or abbreviated as C<< (I,J|K) >>. Such ternary symbols are referred to
as I<global> CI statements. It is well-known that under the semigraphoid
axioms, I<local> CI statements suffice to completely describe a CI
structure. That is to say: semigraphoids are uniquely given by their
subset of local CI statements. Such a local statement has C<I = i> and
C<J = j> be singletons and they are written C<< (ij|K) >> where the
first component C<ij> is taken as a two-element subset of C<N>.

Because of this equivalence and because the semigraphoid axioms are a
very weak assumption, we work only with CI structures in the local world
in this module.

=head2 CInet::Cube

A L<CInet::Cube> object represents a ground set C<N> and contains related
methods. Imagine the unit cube in a space whose coordinates are indexed by
the set C<N>. We also say that the axes of the cube are labeled by the
elements of C<N>.

The face lattice of this cube stores different combinatorial data related
to C<N>, all accessible through one common abstraction -- the cube:

=over

=item *

The vertices of the cube are in bijection to the subsets of C<N>,

=item *

The edges encode elementary functional dependence statements on a random
vector whose coordinates are indexed by C<N>,

=item *

The squares (2-dimensional faces) encode local CI statements on such
a random vector.

=back

In addition to this data, the cube object implements transformations on the
face lattice which are induced by symmetries of the cube: permutation of
axes (implementing isomorphy of CI structures) or reflection over selected
axes.

The cube structure imposes an order on each stratum (of fixed dimensional
faces) of the face lattice. This order is necessary to translate an object
represented by a face (as described in the list above) to a unique integer
number and back. These serializations of parts of the lattice are required
to formulate decision problems for properties of CI structures in formats
that external solvers understand. For example, some properties can be
computed using solvers for the Boolean satisfiability problem SAT where
one Boolean variable must be allocated for every CI statement. This allocation
is provided by the proper ordering of 2-face of the cube.

The cube is a kind of I<domain> object which must be associated to a
L<CInet::Relation> objects in order for it to work properly.

=head2 CInet::Relation

A L<CInet::Relation> object represents a CI structure. It associates to
every 2-face of its domain L<CInet::Cube> a boolean: does the statement
C<(ij|K)> encoded by the 2-face assert a dependence or an independence?
Since we take the point of view of conditional independence, the
independence assertion receives the true value and the dependence
assertion the false value.

Every action on the cube over which a relation is defined induces a
lifted action on the relation. L<CInet::Relation> therefore has methods
which mirror corresponding L<CInet::Cube> methods and execute the lifted
action. It contains additional combinatorial operations for passing
between cubes of different dimensions like taking minors or embedding.
Minors correspond to a fusion of marginalization and conditioning from
the statistical perspective.

L<CInet::Relation> is the main class of the C<CInet> modules. The other
topical C<CInet::*> modules extend this class with methods for deciding
properties of CI structures with the methods of that module, for example
Boolean satisfiability, graphical, polyhedral, algebraic or semidefinite
optimization methods. To read about these methods, refer to the
documentation of these other modules.

=head2 CInet::Symmetry

Three symmetry groups are commonly used on CI structures. They are all
subgroups of the symmetry group of the cube, which is the I<hyperoctahedral group>.
The largest symmetry group implemented in L<CInet::Symmetry> is exactly
this group. Not all properties of interested are invariant under this
action.

The smallest group is the symmetric group on the ground set. Every reasonable
property of CI structures is invariant under this group.

In the middle between these two groups is the twisted symmetric group,
which adds one hyperoctahedral involution to the standard symmetric group.

The L<CInet::Symmetry> module provides these three groups in a form that
is suitable to reduce a collection of L<CInet::Relation> obejcts modulo
each group in bulk. See L<CInet::Seq::Modulo> for how to do this.

=head2 CInet::Seq

Collections of L<CInet::Relation> or related objects are dealt with I<en masse>
using objects of type L<CInet::Seq>. Such an object stands for a I<sequence>
of objects that are lazily produced. They can be filtered and transformed lazily.
The L<CInet::Seq> package is a role which topical modules in the C<CInet::*>
namespace specialize when certain transformations on collections of relations
can be implemented more efficiently.

This mix of composable topical specializations and inherent laziness leads
to very nice, self-clocking pipelines.

Implementations of the L<CInet::Seq> role included in this distribution are

=over

=item *

L<CInet::Seq::List> wrapping a L<CInet::Seq> interface around an array,

=item *

L<CInet::Seq::Map> a C<map> on a sequence,

=item *

L<CInet::Seq::Grep> a C<grep> on a sequence,

=item *

L<CInet::Seq::Uniq> a C<uniq> on a sequence,

=item *

L<CInet::Seq::Modulo> for reducing a sequence of relations modulo one
of the symmetry groups from L<CInet::Symmetry>.

=back

=cut

use Modern::Perl 2018;
use Import::Into;

sub import {
    CInet::Cube     -> import::into(1);
    CInet::Relation -> import::into(1);
    CInet::Symmetry -> import::into(1);

    CInet::Seq         -> import::into(1);
    CInet::Seq::Map    -> import::into(1);
    CInet::Seq::Grep   -> import::into(1);
    CInet::Seq::Uniq   -> import::into(1);
    CInet::Seq::List   -> import::into(1);
    CInet::Seq::Modulo -> import::into(1);
}

=head1 AUTHOR

Tobias Boege <tobs@taboege.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (C) 2020 by Tobias Boege.

This is free software; you can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

=cut

":wq"
