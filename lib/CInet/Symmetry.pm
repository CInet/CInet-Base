=encoding utf8

=head1 NAME

CInet::Symmetry - Symmetry groups

=head1 SYNOPSIS

    # Food for CInet::Relation's ->act method
    say $relation->act($_) for HYPEROCTAHEDRAL($relation);

    # or for CInet::Seq symmetry reduction
    my $mod = $seq->modulo(SYMMETRIC($cube));

=cut

# ABSTRACT: Symmetry groups
package CInet::Symmetry;

use utf8;
use Modern::Perl 2018;
use Export::Attrs;
use Carp;

use CInet::Cube;
use Algorithm::Combinatorics qw(subsets permutations);

=head1 DESCRIPTION

This module implements common symmetry groups acting on L<CInet::Relation>
objects. All groups are implemented and interfaced in a similar fashion.

For each group, there is an ALLCAPS sub which is exported by default.
This sub returns a permutation presentation of the group which can be
passed to L<CInet::Relation>'s C<< ->act >> method or to L<CInet::Seq>'s
C<< ->modulo >> adapter. In addition, these subs keep a cache of group
presentations indexed by cubes, so that each is only computed once.

=cut

# Keep the groups around once computed.
tie my %SYMMETRICS, 'CInet::Hash::FaceKey';
tie my %TWISTEDS, 'CInet::Hash::FaceKey';
tie my %HYPEROCTAHEDRALS, 'CInet::Hash::FaceKey';

=pod

The arguments to each of these subs are interpreted as follows:

=over

=item If the argument is a L<CInet::Cube>, take it.

=item If the argument has a C<cube> method, take its return value.

=item Otherwise pass all arguments to the C<CUBE> function.

=back

=cut

sub _get_cube {
    my $x = shift;
    $x->isa('CInet::Cube') ? $x :
    $x->can('cube') ? $x->cube  :
    CUBE($x, @_)
}

=head2 Exported subs

=head3 SYMMETRIC :Export(:DEFAULT)

    my $Sn = SYMMETRIC($cube);

Return a presentation of the symmetric group on the C<$cube>.

=cut

sub SYMMETRIC :Export(:DEFAULT) {
    my $cube = _get_cube(@_);
    my $N = $cube->set;
    $SYMMETRICS{[$N, []]} //= do {
        # Take an arrayref permuting $cube->set and lift it to an arrayref
        # permuting a Relation on the $cube.
        my $lift = sub {
            my $p = shift;
            my @lifted;
            for my $ijK ($cube->squares) {
                my $im = $cube->permute($p => $ijK);
                push @lifted, $cube->pack($im);
            }
            \@lifted
        };

        my @group;
        for my $p (permutations $N) {
            push @group, $lift->($p);
        }
        \@group
    }
}

=head3 TWISTED :Export(:DEFAULT)

    my $Tn = TWISTED($cube);

Return a presentation of the twisted symmetric group on the C<$cube>.

=cut

sub TWISTED :Export(:DEFAULT) {
    my $cube = _get_cube(@_);
    my $N = $cube->set;
    $TWISTEDS{[$N, []]} //= do {
        my $lift = sub {
            my ($p, $dual) = @_;
            my @lifted;
            for my $ijK ($cube->squares) {
                my $im = $cube->permute($p => $ijK);
                $im = $cube->dual($im) if $dual;
                push @lifted, $cube->pack($im);
            }
            \@lifted
        };

        my @group;
        for my $dual (0, 1) {
            for my $p (permutations $N) {
                push @group, $lift->($p, $dual);
            }
        }
        \@group
    }
}

=head3 HYPEROCTAHEDRAL :Export(:DEFAULT)

    my $Tn = HYPEROCTAHEDRAL($cube);

Return a presentation of the hyperoctahedral group on the C<$cube>.

=cut

sub HYPEROCTAHEDRAL :Export(:DEFAULT) {
    my $cube = _get_cube(@_);
    my $N = $cube->set;
    $HYPEROCTAHEDRALS{[$N, []]} //= do {
        my $lift = sub {
            my ($p, $Z) = @_;
            my @lifted;
            for my $ijK ($cube->squares) {
                my $im = $cube->permute($p => $ijK);
                $im = $cube->swap($Z => $im);
                push @lifted, $cube->pack($im);
            }
            \@lifted
        };

        my @group;
        for my $Z (subsets($N)) {
            for my $p (permutations $N) {
                push @group, $lift->($p, $Z);
            }
        }
        \@group
    }
}

=head1 AUTHOR

Tobias Boege <tobs@taboege.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (C) 2020 by Tobias Boege.

This is free software; you can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

=cut

":wq"
