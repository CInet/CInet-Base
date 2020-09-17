package CInet::Cube;

use utf8;
use Modern::Perl 2018;
use Export::Attrs;
use Carp;

use Scalar::Util qw(reftype);
use List::Util qw(uniq);
use Algorithm::Combinatorics qw(subsets);
use Array::Set qw(set_union set_intersect set_diff set_symdiff);

use CInet::Hash::FaceKey;
use CInet::Imset;

# The CUBE sub keeps one instance per ground set around.
tie my %CUBES, 'CInet::Hash::FaceKey';

sub CUBE :Export(:DEFAULT) {
    my $N = _make_set(@_);
    $CUBES{[$N, []]} //= __PACKAGE__->new(@_)
}

sub _make_set {
    my $argref = reftype($_[0]);
    my $N = $argref && $argref eq 'ARRAY' ? $_[0] : [1 .. $_[0]];
}

sub new {
    my $class = shift;
    my $N = _make_set(@_);
    bless { set => $N, dim => 0+ @$N }, $class
}

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

sub dim {
    shift->{dim}
}

sub set {
    shift->{set}
}

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

sub vertices {
    shift->faces(0)
}

sub edges {
    shift->faces(1)
}

sub squares {
    shift->faces(2)
}

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

sub unpack {
    my ($self, $d, $v) = @_;
    $self->_make_faces($d) unless defined $self->{faces}->[$d];
    $self->{faces}->[$d]->[$v] //
        confess "lookup failed on $d/$v";
}

# Convert a list of ground set elements to their 0-based indices into
# the ground set.
sub _index {
    use List::MoreUtils qw(firstidx any);
    my $self = shift;
    my @indices = map {
        my $x = $_;
        firstidx { $x == $_ } $self->{set}->@*
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

sub dual {
    my ($self, $IK) = @_;
    my ($I, $K) = $IK->@*;
    my $N = $self->{set};
    [ $I, set_diff($N, set_union($I, $K)) ]
}

sub swap {
    my ($self, $Z, $IK) = @_;
    my ($I, $K) = $IK->@*;
    [ $I, set_symdiff($K, set_diff($Z, $I)) ]
}

sub h {
    my $self = shift;
    CInet::Imset->new($self => [uniq shift->@*])
}

sub δ {
    my $self = shift;
    my ($i, $j, @K) = shift->@*;
    $self->h([$i,@K]) + $self->h([$j,@K]) - $self->h([$i,$j,@K]) - $self->h([@K])
}

sub Δ {
    my $self = shift;
    my ($I, $J) = @_;
    $self->h($I) + $self->h($J) - $self->h(set_union($I, $J)) - $self->h(set_intersect($I, $J))
}

":wq"
