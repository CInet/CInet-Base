=encoding utf8

=head1 NAME

CInet::Hash::FaceKey

=head1 SYNOPSIS

    use CInet::Hash::FaceKey;

    # Tie first
    tie %hfk, 'CInet::Hash::FaceKey';

    # Store
    $hfk{[[1,5], [3,4]]} = 1;

    # Fetch, notice set semantics
    $v = $hfk{[[1,5], [4,3]]};

=cut

package CInet::Hash::FaceKey;

use Modern::Perl 2018;

=head1 DESCRIPTION

This is a copy of L<Hash::MultiKey> that is slightly altered to support
using L<CInet::Cube> faces as keys with their correct I<set semantics>.

=head2 Implementation overview

A L<CInet::Cube> face is an arrayref holding a pair of arrayrefs, called
C<$I> and C<$K>, which in turn are disjoint sets (so the ordering inside
of each of them must be disregarded). Following L<Hash::MultiKey>, the
unique key for such a face is computed as

    $n   = @$I + @$K;
    $key = pack('NN', $n, 0+ @$I)
         . pack('w/a*' x $n, sort(@$I), sort(@$K));

The decoding is straight-forward:

    ($n, $i) = unpack 'NN', $key;
    $IK = [ unpack 'x4x4' . ('w/a*' x $n), $key ]
    $I = $IK->@[0 .. $i-1];
    $K = $IK->@[$i .. $IK->$#*];

=cut

sub pack_face {
	my ($I, $K) = shift->@*;
    my $n = @$I + @$K;
    pack('NN', $n, 0+ @$I) . pack('w/a*' x $n, sort(@$I), sort(@$K))
}

sub unpack_face {
	my $key = shift;
    my ($n, $i) = unpack 'NN', $key;
    my $IK = [ unpack 'x4x4' . ('w/a*' x $n), $key ];
    [ [$IK->@[0 .. $i-1]], [$IK->@[$i .. $IK->$#*]] ]
}

sub TIEHASH {
    bless {}, shift;
}

sub CLEAR {
    %{ shift() } = ();
}

sub FETCH {
    my ($self, $face) = @_;
    $self->{pack_face($face)};
}

sub STORE {
    my ($self, $face, $value) = @_;
    $self->{pack_face($face)} = $value;
}

sub DELETE {
    my ($self, $face) = @_;
    delete $self->{pack_face($face)};
}

sub EXISTS {
    my ($self, $face) = @_;
    exists $self->{pack_face($face)};
}

sub FIRSTKEY {
    my ($self) = @_;
    keys %$self; # reset iterator
    $self->NEXTKEY;
}

sub NEXTKEY {
    my ($self) = @_;
    defined(my $key = each %$self) or return;
    unpack_face($key)
}

sub SCALAR {
    my ($self) = @_;
    scalar %$self;
}

=head1 AUTHOR

Tobias Boege <tobs@taboege.de>

Authors of the inspiring L<Hash::MultiKey>:
Xavier Noria (FXN), Benjamin Goldberg (GOLDBB).

=head1 COPYRIGHT AND LICENSE

This software is copyright (C) 2020 by Tobias Boege.

This is free software; you can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

=cut

":wq"
