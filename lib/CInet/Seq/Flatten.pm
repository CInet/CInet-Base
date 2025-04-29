=encoding utf8

=head1 NAME

CInet::Seq::Flatten - Flatten a Seq of Seqs into one sequence

=head1 SYNOPSIS

    # $seqs is a Seq which produces more Seqs.
    # Use $flat to peel off one layer.
    my $flat = CInet::Seq::Flatten->($seqs);

=cut

# ABSTRACT: Flatten a Seq of Seqs into one sequence
package CInet::Seq::Flatten;

use Modern::Perl 2018;
use Scalar::Util qw(blessed);

=head1 DESCRIPTION

This class wraps a sequence whose values are again C<CInet::Seq> objects and
returns a flattened version of this sequence of sequences. This is similar to
turning a nested array structure C<< [ [1,2], [2,3] ] >> into the array
C<< [ 1, 2, 2, 3 ] >>.

It can peel off either one level of nested sequences or recursively flatten.
If the return value is not a sequence, it is returned as-is.

=cut

use Role::Tiny::With;
with 'CInet::Seq';

=head2 Methods

=head3 new

    my $flat = CInet::Seq::Flatten->new($orig, %opts);

Constructs a CInet::Seq::Flatten object for the given sequence.
Pass C<< deep => 1 >> in C<< %opts >> to unpack nested sequences
recursively.

=cut

sub new {
    my ($class, $orig, %opts) = @_;
    bless { orig => $orig, %opts, cur => undef, level => 0 }, $class
}

=head2 Implementation of CInet::Seq

=head3 next

    my $elt = $flat->next;
    last if not defined $elt;

Pull one element from the wrapped sequence C<$orig> given to the constructor.
If it is a C<CInet::Seq>, . Otherwise return it as-is.

=cut

sub next {
    my $self = shift;
    # If we have a current sequence, try to see if it has more values.
    if (defined(my $cur = $self->{cur})) {
        my $val = $cur->next;
        return $val if defined $val;
        # Tidy up cur and fall through if current sequence is exhausted.
        $self->{cur} = undef;
        $self->{level}--;
    }
    # Otherwise pull the next object from the original sequence.
    my $val = $self->{orig}->next;
    if (blessed($val) and $val->does('CInet::Seq')) {
        # Recurse into $val sequence if depth setting allows.
        if ($self->{level} == 0 or $self->{deep}) {
            $self->{cur} = $val;
            $self->{level}++;
            return $self->next;
        }
    }
    $val
}

=head1 AUTHOR

Tobias Boege <tobs@taboege.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (C) 2025 by Tobias Boege.

This is free software; you can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

=cut

":wq"
