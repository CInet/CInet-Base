=encoding utf8

=head1 NAME

CInet::Relation - An abstract (local) CI relation

=head1 SYNOPSIS

    # Create a relation from a string representation
    my $A = CInet::Relation->new(CUBE(5) => '01111111110111111110111111110111111011111111111011111101111101111011111111011111');

    # Partially defined and oriented structures are supported
    my $U = CInet::Relation->new(CUBE(4) => '****---0----0---+++++*++');

    # Print all isomorphic relations (with repetition)
    # in the same binary format.
    use Algorithm::Combinatorics qw(permutations);
    say $A->permute($_) for permutations($A->cube->set);

=cut

# ABSTRACT: An abstract (local) CI relation
package CInet::Relation;

use Modern::Perl 2018;
use Scalar::Util qw(blessed);
use Carp;

use CInet::Cube;
use Array::Set qw(set_union);

use Clone qw(clone);

=head1 DESCRIPTION

C<CInet::Relation> is the main object of interest of this distribution.
It represents an abstract CI relation (or CI structure), that is a
collection of local conditional independence statements C<< (ij|K) >>,
potentially with abstract coefficients.

Each relation requires a domain in the form of a L<CInet::Cube> to be
attached to it, which provides access to the ground set of the relation.
A CInet::Relation is a mapping of its cube's C<< ->squares >> to certain
coefficients. The type of coefficients used determines the type of
relation and how it is treated by other code:

=over

=item *

B<0> and B<1> mean true and false, respectively. Read that again:
B<0> means true and B<1> means false. This may seem backwards at
first, but it makes sense when you think of conditional independence
(the symbol is true) as an equation and dependence (the symbol is
false) as an inequation. A CI structure using only these coefficients
is I<ordinary> and is the most common type.

=item *

One can use additionally B<+> and B<-> to make the structure I<oriented>.
The B<+> and B<-> refine dependencies (B<1>) into positive and negative
correlations. It is legal to mix B<+>, B<-> and B<1>, depending on how
much you know about specific dependencies.

=item *

The symbol B<*> can be used for to denote unknown dependence status.
A CI structure with some B<*> coefficient is I<partially defined>.
It may be ordinary or oriented otherwise.

=back

This package provides methods for manipulating CI structures to the
extent that computational methods are available in this Base distribution:
acting with symmetry groups, taking minors, embedding, meeting and
joining structures.

Other topical modules in the C<CInet::*> namespace will B<extend>
this package from the outside by supplying new methods. For example,
L<CInet::Polyhedral> concerns approximations of the entropic region
with polyhedral cones. These approximations cast a combinatorial
shadow on conditional independence relations and so that module
would add a method to CInet::Relation to check whether a CI structure
is realized by a polymatroid. Another package, L<CInet::Algebraic>
concerns Gaussian-like distributions over arbitrary fields and
adds a method to check realizability of a CInet::Relation in that
sense. If you load the topical module, these methods automatically
become available on every CInet::Relation instance you have around.

=cut

use overload (
    q[=]  => sub { shift->clone },
    q[+]  => \&join,
    q[*]  => \&meet,
    q[""] => \&str,
);

=head2 Methods

=head3 new

    my $A = CInet::Relation->new($cube);
    my $A = CInet::Relation->new($cube => '111010001...');

Create a new CInet::Relation object. The first argument is the mandatory
L<CInet::Cube> instance which provides the ground set of the relation.
The second argument is an optional string that gives the exact CI structure
as a string of coefficients, just like one that the L<str> method would
produce. If this string is not provided, the structure starts out
completely undefined, that is consisting of all B<*> coefficients.

=cut

sub new {
    my ($class, $cube, $A) = @_;
    $cube = CUBE($cube) unless $cube->isa('CInet::Cube');
    my $self = bless [ $cube ], $class;

    $A //= '*' x $cube->squares;
    $self->@[1 .. $cube->squares] = split(//, $A);

    $self
}

=head3 clone

    my $B = $A->clone

Creates a deep copy of the relation.

=cut

=head3 cube

    my $cube = $A->cube

Retrieve the L<CInet::Cube> domain of this relation.

=cut

sub cube {
    shift->[0]
}

=head3 ci

    say $A->ci($ijK) ? "independent" : "dependent";

Given a square C<$ijK>, return whether its corresponding CI statement
holds in the relation.

The statement holds if and only if its coefficient is B<0>. It is not
taken to hold when it is undefined.

=cut

sub ci {
    my ($self, $ijK) = @_;
    $self->[ $self->[0]->pack($ijK) ] eq 0
}

=head3 independent

    my @indeps = $A->independent;

Return all independence statements that hold for the relation, as a list
of C<< $cube->squares >> objects. These are all squares for which the
coefficient is B<0>.

=cut

sub indepenent {
    my $self = shift;
    my $cube = $self->[0];
    grep { $self->[ $cube->pack($_) ] eq 0 } $self->squares
}

=head3 dependent

    my @deps = $A->dependent;

Return all dependence statements that hold for the relation, as a list
of C<< $cube->squares >> objects. A statement with coefficient B<1>,
B<+> or B<-> is dependent.

=cut

sub dependent {
    use Perl6::Junction qw(any);
    my $self = shift;
    my $cube = $self->[0];
    grep { $self->[ $cube->pack($_) ] eq any('1', '+', '-') } $self->squares
}

=head3 permute

    my $Ap = $A->permute($p);

Apply a permutation of the ground set to the relation. The resulting
structure exists over the same C<$cube> and contains exactly the images
of the invocant's squares under the C<< $cube->permute >> method.

=cut

sub permute {
    my ($self, $p) = @_;
    my $new = $self->clone;
    my $cube = $new->[0];
    for my $ijK ($cube->squares) {
        my $i = $cube->pack($ijK);
        my $j = $cube->pack($cube->permute($p => $ijK));
        $new->[$j] = $self->[$i];
    }
    $new
}

=head3 dual

    my $Ad = $A->dual;

Return the dual relation. The return value exists over the same C<$cube>
and contains exactly the images of the invocant's squares under the
C<< $cube->dual >> method.

=cut

sub dual {
    my $self = shift;
    my $new = $self->clone;
    my $cube = $new->[0];
    for my $ijK ($cube->squares) {
        my $i = $cube->pack($ijK);
        my $j = $cube->pack($cube->dual($ijK));
        $new->[$j] = $self->[$i];
    }
    $new
}

=head3 swap

    my $AZ = $A->swap($Z);

Apply a swap of the ground set to the relation. The resulting structure
exists over the same C<$cube> and contains exactly the images of the
invocant's squares under the C<< $cube->swap >> method.

=cut

sub swap {
    my ($self, $Z) = @_;
    my $new = $self->clone;
    my $cube = $new->[0];
    for my $ijK ($cube->squares) {
        my $i = $cube->pack($ijK);
        my $j = $cube->pack($cube->swap($Z => $ijK));
        $new->[$j] = $self->[$i];
    }
    $new
}

=head3 act

    my $Ag = $A->act($g);

Apply a permutation C<$g> of the array C<< $cube->squares >> to the
relation. All groups in L<CInet::Symmetry> are implement in this form.
The returned structure exists over the same cube.

=cut

sub act {
    my ($self, $g) = @_;
    my $new = $self->clone;
    my $cube = $new->[0];
    my @M = 1 .. $cube->squares;
    $new->@[@M] = $self->@[@$g];
    $new
}

=head3 orbit

    my $seq = $A->orbit(SYMMETRIC);

Return a L<CInet::Seq> instance which enumerates the orbit of the
invocant under a given symmetric group from L<CInet::Symmetry>.
If a C<CInet::Symmetry::Type> is passed, it will be instantiated
with C<< $A->cube >>.

=cut

sub orbit {
    my ($self, $group) = @_;
    $group = $group->($self) if blessed($group) and $group->isa('CInet::Symmetry::Type');
    CInet::Seq::List->new(@$group)->map(sub{ $self->act($_) })
}

=head3 representative

    my $rep = $A->representative(SYMMETRIC);

Return the distinguished representative of the invocant's orbit
under a given symmetric group from L<CInet::Symmetry>. If a
C<CInet::Symmetry::Type> is passed, it will be instantiated with
C<< $A->cube >>.

This method will always return a distinguished representative of
the symmetry orbit. This is unlike other methods, for examples in
L<CInet::Seq::Modulo>, which return the first element encountered
from every incoming orbit.

The representative is distinguished by having the lexicographically
smallest stringification.

=cut

sub representative {
    use List::Util qw(minstr);
    my ($self, $group) = @_;
    $group = $group->($self) if blessed($group) and $group->isa('CInet::Symmetry::Type');
    minstr map { $self->act($_) } @$group
}

=head3 minor

    my $a = $A->minor($IK);

Return the C<< I|K >>-minor of the invocant. This is the structure
obtained by marginalizing to C<I ∪ K> and then conditioning C<K>.
Equivalently, it contains all the squares which lie on the
C<< I|K >>-face of the ambient cube. The minor is defined over
the ground set C<$I>. The required cube object is obtained from
the C<CUBE> sub.

The opposite of this method is L<embed>.

=cut

sub minor {
    my ($self, $face) = @_;
    my $cube = $self->[0];
    my ($I, $L) = @$face;
    my $Icube = CUBE($I);
    my $new = CInet::Relation->new($Icube);
    for my $ijK ($Icube->squares) {
        my ($ij, $K) = @$ijK;
        my $j = $Icube->pack($ijK);
        my $i = $cube->pack([ $ij, set_union($K, $L) ]);
        $new->[$j] = $self->[$i];
    }
    $new
}

=head3 embed

    my $A = $a->embed($IK);

When the invocant is a structure over ground set C<$I> and given a
face C<[$I, $K]> of a larger cube over C<$N>, this method produces
a new structure over C<$N> which contains the invocant's squares
embedded into the C<< I|K >>-face and nothing else.

The opposite of this method is L<minor>.

=cut

sub embed {
    my ($self, $M, $face) = @_;
    my $cube = $self->[0];
    $face //= [$cube->set, []];
    my ($I, $L) = @$face;
    my $Mcube = CUBE($M);
    my $new = CInet::Relation->new($Mcube);
    for my $ijK ($cube->squares) {
        my ($ij, $K) = @$ijK;
        my $i = $cube->pack($ijK);
        my $j = $Mcube->pack([ $ij, set_union($K, $L) ]);
        $new->[$j] = $self->[$i];
    }
    $new
}

=head3 minors

    my $k_minors = $A->minors($k, %opts);
    my $all_minors = $A->minors(%opts);

Return a L<CInet::Seq> object for iterating over all minors of a structure.
With a given dimension C<$k>, only the minors in that dimension are enumerated.

If C<< $opts{faces} >> is truthy, then the elements of the Seq are decorated
arrayrefs of C<< [ $minor_relation, $face ] >>. Otherwise (in particular by
default), the Seq enumerates only the minor C<CInet::Relation> objects.

=cut

sub minors {
    my $self = shift;
    my ($k, %opts) = (@_ % 2 == 1 ? @_ : (undef, @_));
    my $with_faces = $opts{faces};

    my $cube = $self->[0];
    my @faces = $cube->faces($k);
    CInet::Seq::List->new(@faces)->map(sub{
        $with_faces ?
            [ $self->minor($_) => $_ ] :
            $self->minor($_)
    })
}

=head3 union

    my $AB = $A->union($B);

Return the union of the two given CI structures. This operation is only
defined for 0/1-valued relations on the same ground set.

=cut

sub union {
    my ($A, $B) = @_;
    my $AB = $A->clone;
    for my $i (1 .. $AB->$#*) {
        $AB->[$i] &= $B->[$i];
    }
    $AB
}

=head3 intersect

    my $AB = $A->intersect($B);

Return the intersection of the two given CI structures. This operation is
only defined for 0/1-valued relations on the same ground set.

=cut

sub intersect {
    my ($A, $B) = @_;
    my $AB = $A->clone;
    for my $i (1 .. $AB->$#*) {
        $AB->[$i] ||= $B->[$i];
    }
    $AB
}

=head3

    my $ID = $A->ID;

Returns the ID of a 0/1-valued relation. This is a hexadecimal rendering
of the bit string. The ID is of fixed length (depending on the ground set),
printable and preserves the CI structure entirely, except for the labeling
on its ground set.

Each chunk of four bits (most significant bit first) in C<< $A->str >> is
converted (in order) to a hexadecimal digit.

=cut

sub ID {
    unpack 'H*', pack 'B*', shift->str
}

=head2 Overloaded operators

=head3 Addition

    my $C = $A + $B;
    my $C = $A->join($B);

Addition of two CInet::Relation objects over the same ground set
computes their I<join>, which is the element-wise commutative
operation defined by the following table:

TODO: NYI

=cut

sub join {
    my ($R, $S, $swap) = @_;
    ($R, $S) = ($S, $R) if $swap;
    my $T = $R->clone;
    for my $i (keys @$R) {
        next unless $i;
        ...
    }
    $T
}

=head3 Multiplication

    my $C = $A * $B;
    my $C = $A->meet($B);

Multiplication of two CInet::Relation objects over the same ground set
computes their I<meet>, which is the element-wise commutative operation
defined by the following table

TODO: NYI

=cut

sub meet {
    my ($R, $S, $swap) = @_;
    ($R, $S) = ($S, $R) if $swap;
    my $T = $R->clone;
    for my $i (keys @$R) {
        next unless $i;
        ...
    }
    $T
}

=head3 Stringification

    say $A;  # 11101001...

Return a string representing the CI structure. The string contains
C<< $cube->squres >>-many symbols from the coefficient alphabet B<0>,
B<1>, B<+>, B<->, B<*>. Each symbol corresponds to a CI statement
via the proper ordering of squares documented in L<CInet::Cube>.

=cut

sub str {
    my $self = shift;
    CORE::join '', $self->@[1 .. $self->$#*]
}

=head2 AUTOLOAD

    $A->unknown_method;
    # dies but helpfully

Since CInet::Relation is pieced together from multiple distributions,
it can happen that you call a method on it which is implemented in a
module which you forgot to load. We supply an AUTOLOAD which catches
all unknown methods and displays a reminder about that.

=cut

# Try to be helpful.
sub AUTOLOAD {
    our $AUTOLOAD;
    my $meth = $AUTOLOAD =~ s/.*:://r;
    return if $meth eq 'DESTROY';
    confess <<~EOF;
        Method '$meth' not found in @{[ __PACKAGE__ ]}.
        This class is composed of pieces from multiple modules.
        Did you forget to load the topical module?
        EOF
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
