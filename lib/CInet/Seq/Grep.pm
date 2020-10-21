=encoding utf8

=head1 NAME

CInet::Seq::Grep - Lazy grep on a Seq object

=head1 SYNOPSIS

    

=cut

# ABSTRACT: Lazy grep on a Seq object
package CInet::Seq::Grep;

use Modern::Perl 2018;
use Carp;

=head1 DESCRIPTION

=cut

use Role::Tiny::With;
with 'CInet::Seq';

=head2 Methods

=head3 new

    ...

=cut

sub new {
    my ($class, $prev, $code) = @_;
    bless { prev => $prev, code => $code }, $class
}

=head2 Implementation of CInet::Seq

=head3 next

    my $elt = $seq->next;
    last if not defined $elt;

Pull elements from the parent Seq until the first time one of them passes
the condition supplied on construction. Return either that element or
C<undef> if the parent Seq is exhausted in the process.

=cut

sub next {
    my ($prev, $code) = shift->@{'prev', 'code'};
    while (1) {
        my $x = $prev->next;
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
