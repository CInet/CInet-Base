=encoding utf8

=head1 NAME

CInet::Seq::Map - Lazy map on a Seq object

=head1 SYNOPSIS

    # Can use $_ or @_ in sub
    my $mapped = $seq->map(sub{ … });

=cut

# ABSTRACT: Lazy map on a Seq object
package CInet::Seq::Map;

use Modern::Perl 2018;
use Carp;

=head1 DESCRIPTION

This class adapts a given L<CInet::Seq> object by mapping its elements.
Each element from the source Seq is passed through a coderef and the
return value is returned instead of the original data.

This class implements the L<CInet::Seq> role.

=cut

use Role::Tiny::With;
with 'CInet::Seq';

=head2 Methods

=head3 new

    my $map = CInet::Seq::Map->new($source, $code);

Constructs a CInet::Seq::Map object which pulls its elements from the
C<$source> Seq and transforms them through the C<$code> coderef.

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

Pull one element from the source Seq. If the source is exhausted, return
C<undef> immediately. Otherwise transform the pulled element and return it.

=cut

sub next {
    my ($src, $code) = shift->@{'src', 'code'};
    my $x = $src->next;
    return undef if not defined $x;
    local $_ = $x;
    $code->($x)
}

=head1 AUTHOR

Tobias Boege <tobs@taboege.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (C) 2020 by Tobias Boege.

This is free software; you can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

=cut

":wq"
