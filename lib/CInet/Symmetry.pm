# ABSTRACT: Symmetry groups
package CInet::Symmetry;

use utf8;
use Modern::Perl 2018;
use Export::Attrs;
use Carp;

use CInet::Cube;
use Algorithm::Combinatorics qw(subsets permutations);

# Keep the groups around once computed.
tie my %SYMMETRICS, 'CInet::Hash::FaceKey';
tie my %TWISTEDS, 'CInet::Hash::FaceKey';
tie my %HYPEROCTAHEDRALS, 'CInet::Hash::FaceKey';

sub SYMMETRIC :Export(:DEFAULT) {
    my $cube = $_[0]->isa('CInet::Cube') ? shift : CUBE(@_);
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

sub TWISTED :Export(:DEFAULT) {
    my $cube = $_[0]->isa('CInet::Cube') ? shift : CUBE(@_);
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

sub HYPEROCTAHEDRAL :Export(:DEFAULT) {
    my $cube = $_[0]->isa('CInet::Cube') ? shift : CUBE(@_);
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

":wq"
