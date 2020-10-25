=encoding utf8

=head1 NAME

CInet::Seq::Grep - Lazy grep on a Seq object

=head1 SYNOPSIS

    # Can use $_ or @_ in sub
    my $filtered = $seq->grep(sub{ … });

=cut

# ABSTRACT: Lazy grep on a Seq object
package CInet::Seq::Grep;

use Modern::Perl 2018;
use Carp;

=head1 DESCRIPTION

This class adapts a given L<CInet::Seq> object by filtering its elements.
It returns only elements for which the provided coderef is truthy.

This class implements the L<CInet::Seq> role.

=cut

use Role::Tiny::With;
with 'CInet::Seq';

=head2 Methods

=head3 new

    my $grep = CInet::Seq::Grep->new($source, $code);

Constructs a CInet::Seq::Grep object which pulls its elements from the
C<$source> Seq and filters them through the C<$code> coderef.

The coderef can refer to its argument as either C<$_> or via C<@_>.

=cut

sub new {
    my ($class, $src, $code) = @_;
    bless { src => $src, code => $code }, $class
}

=head2 Implementation of CInet::Seq

=head3 next

    my $elt = $seq->next;
    last if not defined $elt;

Pull elements from the source Seq until the first time one of them
passes the condition supplied on construction. Return either that
element or C<undef> if the source is exhausted in the process.

=cut

sub next {
    my ($src, $code) = shift->@{'src', 'code'};
    while (1) {
        my $x = $src->next;
        return undef if not defined $x;
        local $_ = $x;
        return $x if $code->($x);
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
