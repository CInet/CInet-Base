package CInet::Relation;

use Modern::Perl 2018;
use Carp;

use CInet::Cube;
use Array::Set qw(set_union set_symdiff set_diff);

use parent 'Clone';

sub new {
    my ($class, $cube, $A) = @_;
    my $self = bless [ $cube ], $class;

    $A //= '0' x $cube->squares;
    $self->@[1 .. $cube->squares] = split(//, $A);

    $self
}

sub cube {
    shift->[0]
}

sub ci {
    my ($self, $ijK) = @_;
    $self->[ $self->[0]->pack($ijK) ] == 0
}

sub permute {
    my ($self, $p) = @_;
    my $new = $self->clone;
    my $cube = $new->[0];
    for my $ijK ($cube->squares) {
        my ($ij, $K) = @$ijK;
        my $i = $cube->pack($ijK);
        my $j = $cube->pack([
            [ $p->@[@$ij] ],
            [ $p->@[@$K]  ],
        ]);
        $new->[$j] = $self->[$i];
    }
    $new
}

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

sub swap {
    my ($self, $Z) = @_;
    my $new = $self->clone;
    my $cube = $new->[0];
    for my $ijK ($cube->squares) {
        my ($ij, $K) = @$ijK;
        my $i = $cube->pack($ijK);
        my $j = $cube->pack([ $ij,
            set_symdiff($K, set_diff($Z, $ij))
        ]);
        $new->[$j] = $self->[$i];
    }
    $new
}

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

sub minors {
    my ($self, $k) = @_;
    my $cube = $self->[0];
    my @res;
    for my $IK ($cube->faces($k)) {
        push @res, [ $IK => $self->minor($IK) ];
    }
    @res
}

sub str {
    my $self = shift;
    join '', $self->@[1 .. $self->$#*]
}

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

":wq"
