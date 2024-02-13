=encoding utf8

=head1 NAME

CInet::Cube - The ground set of a CInet::Relation

=head1 SYNOPSIS

    my $cube = Cube(5);  # ground set 1..5

    # Print the permuted ordering of 2-faces.
    my $p = [4,1,3,5,2];
    for my $ijK ($cube->squares) {
        my $pijK = $cube->permute($p => $ijK);
        say $cube->pack($ijK), ' -> ', $cube->pack($pijK);
    }

=cut

# ABSTRACT: The ground set of a CInet::Relation
package CInet::Cube;

use utf8;
use Modern::Perl 2018;
use Export::Attrs;
use Carp;

use Scalar::Util qw(reftype);
use Algorithm::Combinatorics qw(subsets);
use Array::Set qw(set_union set_intersect set_diff set_symdiff);

use CInet::Hash::FaceKey;

=head1 DESCRIPTION

A C<CInet::Cube> object represents a finite ground set and provides access
to related combinatorial data in the form of the face lattice of the cube.
For example, all subsets of the ground set are available as C<< ->vertices >>,
or all CI statements on a random vector indexed by the ground set are C<< -> squares >>.
This object bundles this data and implements transformations on them and
provides a common geometric language to talk about them.

In addition, the cube implements the I<proper ordering> of each set of
fixed-dimensional faces. These orderings are used in L<CInet::Relation>
and topical C<CInet::*> modules whenever combinatorial objects must be
mapped to a contiguous sequence of integers C<1 .. k> usually to allocate
variables in a domain-specific solver that computes a certain property
of the CI structure.

The proper, agreed-upon ordering allows to write problem descriptions
which are mutually consistent. It also allows to serialize a L<CInet::Relation>
to a unique string that can be read in by other programs implementing the
same canonical ordering.

=cut

# Process the first argument into an arrayref as CInet::Cube->new requires.
sub _make_set {
    my $argref = reftype($_[0]);
    my $N = $argref && $argref eq 'ARRAY' ? $_[0] : [1 .. $_[0]];
}

=head2 Methods

=head3 new

    my $cube = CInet::Cube->new($n);
    my $cube = CInet::Cube->new($set);

Create a new cube object on the given ground set. If the argument is an
arrayref C<$set>, then that is the ground set. The caller is responsible
for ensuring that it is properly sorted and deduplicated. Otherwise the
ground set is taken to be C<1 .. $n>.

=cut

sub new {
    my $class = shift;
    my $N = _make_set(@_);
    bless { set => $N, dim => 0+ @$N }, $class
}

# Reify the array and lookup structure of $k-dimensional faces in the
# invocant and return the array.
sub _make_faces {
    my ($self, $k) = @_;
    my $N = $self->{set};

    tie my %codes, 'CInet::Hash::FaceKey';
    $self->{codes}->[$k] = \%codes;
    $self->{faces}->[$k] = \my @faces;

    $faces[0] = "(NaV)";
    my $v = 1;
    for my $I (subsets($N, $k)) {
        my $M = set_diff($N, $I);
        for my $k (0 .. @$M) {
            for my $K (subsets($M, $k)) {
                my $face = [$I, $K];
                $faces[$v] = $face;
                $codes{$face} = $v;
                $v++;
            }
        }
    }

    @faces
}

=head3 dim

    my $dim = $cube->dim;

Returns the dimension, that is the size of the ground set, of this cube.

=cut

sub dim {
    shift->{dim}
}

=head3 set

    my $set = $cube->set;

Returns the ground set of this cube, which are axis labels.

=cut

sub set {
    shift->{set}
}

=head3 faces, vertices, edges, squares

    my @all_faces  = $cube->faces;
    my @some_faces = $cube->faces(0, 2, $cube->dim - 1);

Returns faces of the cube. If no arguments are given, all faces are returned
in order of ascending dimension and each fixed-dimensional slice in its
proper order.

When specific dimensions are asked for in the arguments to this method, only
these faces are returned.

Each cube object computes the array of d-dimensional faces only on demand.
Once computed, the array is cached. Other methods besides L<faces|/"faces">
which can cause the face array to be reified are L<pack|/"pack"> and
L<unpack|/"unpack">.

=cut

sub faces {
    my $self = shift;
    my @dims = @_ ? @_ : 0 .. $self->{dim};
    my @res;
    for (@dims) {
        my $faces = $self->{faces}->[$_] // [$self->_make_faces($_)];
        push @res, $faces->@[1 .. $faces->$#*];
    }
    @res
}

=pod

There are predefined accessors for faces which are often used:

    my @vertices = $cube->vertices;  # ->faces(0)
    my @edges    = $cube->edges;     # ->faces(1)
    my @squares  = $cube->squares;   # ->faces(2)

These methods return, respectively, the zero-, one- and two-dimensional
faces.

=cut

sub vertices {
    shift->faces(0)
}

sub edges {
    shift->faces(1)
}

sub squares {
    shift->faces(2)
}

=head3 pack

    my $nr = $cube->pack($face);

Maps a (d-dimensional) face to its 1-based position in the proper ordering
of d-dimensional faces of the cube. If the face was not found, an exception
is thrown.

=cut

sub pack {
    my ($self, $IK) = @_;
    my $d = $IK->[0]->@*;
    $self->_make_faces($d) unless defined $self->{codes}->[$d];
    $self->{codes}->[$d]->{$IK} //
        confess "lookup failed on $d/@{[
            join('', $IK->[0]->@*) . '|' .
            join('', $IK->[1]->@*)
        ]} over ground set @{[ join('', $self->{set}->@*) ]}";
}

=head3 unpack

    my $face = $cube->unpack($d => $nr);

The opposite of the L<pack|/"pack"> method, takes a dimension and 1-based
position number and returns the corresponding face object, or dies.

=cut

sub unpack {
    my ($self, $d, $v) = @_;
    $self->_make_faces($d) unless defined $self->{faces}->[$d];
    $self->{faces}->[$d]->[$v] //
        confess "lookup failed on $d/$v";
}

=head3 permute

    my $pface = $cube->permute($p => $face);

The symmetric group on C<< $cube->set >> acts on the axes of the cube
and gives rise to I<permutation symmetries> of the face lattice. Given
a permutation and a face, this method returns the corresponding face
on the permuted cube.

The permutation is given in "one-line notation", that is the i-th entry
gives the image of the i-th element of the ground set.

=cut

# Convert a list of ground set elements to their 0-based indices into
# the ground set.
sub _index {
    use List::SomeUtils qw(firstidx any);
    my $self = shift;
    my @indices = map {
        my $x = $_;
        firstidx { $x eq $_ } $self->{set}->@*
    } @_;
    confess "could not find some of the elements [@{[ join(', ', @_) ]}] "
        . " over ground set @{[ join('', $self->{set}->@*) ]}"
        if any { $_ < 0 } @indices;
    @indices
}

sub permute {
    my ($self, $p, $IK) = @_;
    my ($I, $K) = $IK->@*;
    [
        [ $p->@[$self->_index(@$I)] ],
        [ $p->@[$self->_index(@$K)] ],
    ]
}

=head3 dual

    my $dface = $cube->dual($face);

The cube has a distinguished symmetry by which all mirror symmetries are
applied simultaneously. This is referred to as I<duality>.

This is the same as calling L<swap|/"swap"> with C<< $Z = $cube->set >>.

=cut

sub dual {
    my ($self, $IK) = @_;
    my ($I, $K) = $IK->@*;
    my $N = $self->{set};
    [ $I, set_diff($N, set_union($I, $K)) ]
}

=head3 swap

    my $Zface = $cube->swap($Z => $face);

For each subset C<$Z> of the axes of the cube, there is a mirror symmetry
which applies simultaneously all the reflections orthogonal to each axis
in C<$Z>. This is called I<swapping> and it generalizes the operation of
L<dual|/"dual">.

=cut

sub swap {
    my ($self, $Z, $IK) = @_;
    my ($I, $K) = $IK->@*;
    [ $I, set_symdiff($K, set_diff($Z, $I)) ]
}

=head2 Exports

=head3 Cube :Export(:DEFAULT)

    my $cube = Cube($n);
    my $cube = Cube($set);
    my $cube = Cube($object);

This is not only a shorthand for the C<< CInet::Cube->new >> constructor,
but it also keeps a cache of cube objects indexed by ground sets and it
tries harder to extract a cube from its input arguments:

=over

=item If the argument is a L<CInet::Cube>, return that.

=item If the argument has a C<cube> method, return that value.

=item Otherwise pass all arguments to the L<new|/"new"> constructor.

=back

Prefer this function for getting cubes that you often use. Many gears
of CInet already use this function for convenience.

This sub is exported by default.

=cut

# The Cube sub keeps one instance per ground set around.
tie my %CUBES, 'CInet::Hash::FaceKey';

sub _get_cube {
    use Scalar::Util qw(blessed);

    my $x = shift;
    my $blessed = defined blessed $x;

    $blessed && $x->isa('CInet::Cube') ? $x :
    $blessed && $x->can('cube') ? $x->cube  :
    __PACKAGE__->new($x, @_)
}

sub Cube :Export(:DEFAULT) {
    my $cube = _get_cube(@_);
    $CUBES{[ $cube->set, [] ]} //= $cube
}

=head1 AUTHOR

Tobias Boege <tobs@taboege.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (C) 2020 by Tobias Boege.

This is free software; you can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

=cut

":wq"
