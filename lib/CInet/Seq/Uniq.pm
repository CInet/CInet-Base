=encoding utf8

=head1 NAME

CInet::Seq::Uniq - Lazy stringy uniq on a Seq object

=head1 SYNOPSIS

    # Can use $_ or @_ in sub
    my $uniq = $seq->uniq;

    # Default stringification:
    my $uniq = $seq->uniq(sub{ "". $_ });

=cut

# ABSTRACT: Lazy stringy uniq on a Seq object
package CInet::Seq::Uniq;

use Modern::Perl 2018;
use Carp;

=head1 DESCRIPTION

This class adapts a given L<CInet::Seq> object by filtering its elements
for uniqness. It returns only the first element with a given stringification.
The stringification by default is C<< "". $_ >> but can be overridden.
The implementation uses a hash to keep track of which strings were seen.
This cache is cleared immediately after the sequence is exhausted, before
the final C<undef> is returned.

This class implements the L<CInet::Seq> role.

=cut

use Role::Tiny::With;
with 'CInet::Seq';

=head3 new

    my $uniq = CInet::Seq::Uniq->new($source, $stringify);

Constructs a CInet::Seq::Uniq object which pulls its elements from
the C<$source> Seq and only forwards the first element with a given
stringification to the consumer.

The stringification is given by the C<$stringify> coderef but defaults
to C<< "". $_ >>.

The coderef can refer to its argument as either C<$_> or via C<@_>.

=cut

sub new {
    my ($class, $src, $code) = @_;
    $code //= sub { "". $_ };
    bless { src => $src, code => $code, seen => { } }, $class
}

=head2 Implementation of CInet::Seq

=head3 next

    my $elt = $seq->next;
    last if not defined $elt;

Pull elements from the source Seq until the first time one of them
has a hitherto unknown stringification. Return either that element
or C<undef> if the source is exhausted in the process.

The cache of seen strings is cleared immediately after the source
is exhausted.

=cut

sub next {
    my ($src, $code, $seen) = shift->@{'src', 'code', 'seen'};
    while (defined(my $x = $src->next)) {
        local $_ = $x;
        my $str = $code->($x);
        return $x if not $seen->{$str}++;
    }
    # Clean up cache
    undef($seen->%*);
    undef
}

=head1 AUTHOR

Tobias Boege <tobs@taboege.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (C) 2020 by Tobias Boege.

This is free software; you can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

=cut

":wq"
