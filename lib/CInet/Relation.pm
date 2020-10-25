=encoding utf8

=head1 NAME

CInet::Relation - An abstract (local) CI relation

=head1 SYNOPSIS

    # Create a relation from a string representation
    my $A = CInet::Relation->new(CUBE(5) => '01111111110111111110111111110111111011111111111011111101111101111011111111011111');

    # Print all isomorphic relations (with repetition)
    # in the same binary format.
    use Algorithm::Combinatorics qw(permutations);
    say $A->permute($_) for permutations($A->cube->set);

=cut

# ABSTRACT: An abstract (local) CI relation
package CInet::Relation;

use Modern::Perl 2018;
use Carp;

use CInet::Cube;
use Array::Set qw(set_union);

use Clone qw(clone);

=head1 DESCRIPTION

C<CInet::Relation> is the main object of interest of this distribution.
It represents an abstract CI relation (or CI structure), that is a
collection of local conditional independence statements C<< (ij|K) >>.

Each relation requires a domain in the form of a L<CInet::Cube> to be
attached to it, which provides access to the ground set of the relation.
A CInet::Relation is a mapping of its cube's C<< ->squares >> to true
and false. In stringifications, B<true> will be represented by B<0>
and B<false> by B<1>. This may seem backwards at first, but it makes
sense when you think of conditional independence as defined by an
equation and dependence by an inequation.

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
as a binary string, just like one that the L<str> method would produce.
If this string is not provided, the structure starts out B<empty>, that is
no independencies hold, everything is dependent.

=cut

sub new {
    my ($class, $cube, $A) = @_;
    $cube = CUBE($cube) unless $cube->isa('CInet::Cube');
    my $self = bless [ $cube ], $class;

    $A //= '1' x $cube->squares;
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

=cut

sub ci {
    my ($self, $ijK) = @_;
    $self->[ $self->[0]->pack($ijK) ] == 0
}

=head3 independent

    my @indeps = $A->independent;

Return all independence statements that hold for the relation, as a list
of C<< $cube->squares >> objects.

=cut

sub indepenent {
    my $self = shift;
    my $cube = $self->[0];
    grep { $self->[ $cube->pack($_) ] == 0 } $self->squares
}

=head3 dependent

    my @deps = $A->dependent;

Return all dependence statements that hold for the relation, as a list
of C<< $cube->squares >> objects. A statement which is not independent
is dependent.

=cut

sub dependent {
    my $self = shift;
    my $cube = $self->[0];
    grep { $self->[ $cube->pack($_) ] != 0 } $self->squares
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
    my @M = 0 .. (-1 + $cube->squares);
    $new->@[@M] = $self->@[$g->@[@M]];
    $new
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

    my @kminors = $A->minors($k);
    my @allminors = $A->minors;

Return a list of all minors of a structure. With a given dimension C<$k>,
only the minors in that dimension are returned. This calls the L<minor>
method on the invocant once per face.

=cut

sub minors {
    my ($self, $k) = @_;
    my $cube = $self->[0];
    my @res;
    for my $IK ($cube->faces($k)) {
        push @res, [ $IK => $self->minor($IK) ];
    }
    @res
}

=head2 Overloaded operators

=head3 Addition

    my $C = $A + $B;
    my $C = $A->join($B);

Addition of two CInet::Relation objects over the same ground set
computes their I<join>, which is just the set-theoretic union.

=cut

sub join {
    my ($R, $S, $swap) = @_;
    ($R, $S) = ($S, $R) if $swap;
    my $T = $R->clone;
    for my $i (keys @$R) {
        next unless $i;
        $T->[$i] = 0 if $S->[$i] == 0;
    }
    $T
}

=head3 Multiplication

    my $C = $A * $B;
    my $C = $A->meet($B);

Multiplication of two CInet::Relation objects over the same ground set
computes their I<meet>, which is just the set-theoretic intersection.

=cut

sub meet {
    my ($R, $S, $swap) = @_;
    ($R, $S) = ($S, $R) if $swap;
    my $T = $R->clone;
    for my $i (keys @$R) {
        next unless $i;
        $T->[$i] = 1 if $S->[$i] != 0;
    }
    $T
}

=head3 Stringification

    say $A;  # 11101001...

Return a string representing the CI structure. The string contains
C<< $cube->squres >>-many binary digits, either C<0> or C<1>.
Each such bit indicates whether the corresponding square in the
proper ordering of squares is contained (C<0>) or not contained (C<1>)
in the relation.

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
