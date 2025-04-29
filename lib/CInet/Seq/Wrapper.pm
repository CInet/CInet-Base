=encoding utf8

=head1 NAME

CInet::Seq::Wrapper - Wrap an iterator in a sequence

=head1 SYNOPSIS

    # $gen is a coderef or an iterator with a C<next> method
    # which generates data if it is called repeatedly.
    my $seq = CInet::Seq::Wrapper->($gen);

=cut

# ABSTRACT: Wrap an iterator in a sequence
package CInet::Seq::Wrapper;

use Modern::Perl 2018;
use Scalar::Util qw(blessed reftype);

=head1 DESCRIPTION

This class wraps a given coderef or a blessed iterator with C<next> method
which generates data if it is called repeatedly in the L<CInet::Seq> interface.

=cut

use Role::Tiny::With;
with 'CInet::Seq';

=head2 Methods

=head3 new

    my $wrap = CInet::Seq::Wrapper->new($gen);

Constructs a CInet::Seq::Wrapper object for the given iterator.

=cut

sub new {
    my ($class, $gen) = @_;
    my $wrap = do {
        if (blessed($gen) and $gen->can('next')) {
            sub { $gen->next }
        }
        elsif (reftype($gen) eq 'CODE') {
            sub { $gen->() }
        }
        else {
            die 'iterator does not support the calling convention';
        }
    };
    bless { gen => $wrap }, $class
}

=head2 Implementation of CInet::Seq

=head3 next

    my $elt = $seq->next;
    last if not defined $elt;

Pull one element from the iterator C<$gen> given to the constructor.
If C<$gen> is a blessed reference with a C<next> method, that method
is called. Otherwise, C<$gen> must be a coderef and then itself is
called. No arguments are given.

=cut

sub next {
    shift->{gen}->()
}

=head1 AUTHOR

Tobias Boege <tobs@taboege.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (C) 2024 by Tobias Boege.

This is free software; you can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

=cut

":wq"
