=encoding utf8

=head1 NAME

CInet::Cube::Face - Wrapper class for a CInet::Cube face

=head1 SYNOPSIS

    my $cube = Cube(5);  # ground set 1..5
    say FACE($_) for $cube->squares; # stringifies nicely

=cut

# ABSTRACT: Wrapper class for a CInet::Cube face
package CInet::Cube::Face;

use utf8;
use Modern::Perl 2018;
use Export::Attrs;
use Carp;

use overload (
    q[""] => \&_str,
);

=head1 DESCRIPTION

C<CInet::Cube::Face> exists to give face objects returned from C<CInet::Cube>
some methods and a stringification overload for convenience. Faces returned
from a cube object are normally B<not> blessed into this package. You have to
do this by yourself on-demand, for example via the exported C<FACE> sub.

=head2 Methods

=head3 new

    my $face = CInet::Cube::Face->new($face);

Bless the given C<$face> arrayref into the CInet::Cube::Face package.
The argument is not wrapped before being blessed, the same arrayref is
returned.

=cut

sub new {
    my ($class, $face) = @_;
    bless $face, $class
}

=head3 I

    my @I = $face->I;

Return the list of elements in the first component of the face,
the "varying part" which determines the dimension of the face.

=cut

sub I {
    shift->[0]->@*
}

=head3 K

    my @K = $face->K;

Return the list of elements in the second component of the face,
the "rigid part" which gives the axes along which the varying part
is translated in the cube.

=cut

sub K {
    shift->[1]->@*
}

=head3 dim

    my $dim = $face->dim;

Returns the dimension of this face.

=cut

sub dim {
    0+ shift->I
}

=head2 Overloaded operators

=head3 Stringification

    say $face;  # 12|46

A CInet::Cube::Face object stringifies into the format C<I|K> where
the I- and K-elements are joined without spaces. It is advisable to
only use single-letter names for cube axes.

=cut

sub _str {
    my $self = shift;
    sprintf "%s|%s", join('', $self->I), join('', $self->K)
}

=head2 Exports

=head3 FACE :Export(:DEFAULT)

    my $face = FACE($face);
    my $topical = FACE;

This is a shorthand for the C<< CInet::Cube::Face->new >> constructor.
It passes all given arguments to the real constructor, or forwards C<$_>
when no arguments are given.

This sub is exported by default.

=cut

sub FACE :Export(:DEFAULT) {
    __PACKAGE__->new(@_ ? @_ : $_)
}

=head1 AUTHOR

Tobias Boege <tobs@taboege.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (C) 2020 by Tobias Boege.

This is free software; you can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

=cut

":wq"
