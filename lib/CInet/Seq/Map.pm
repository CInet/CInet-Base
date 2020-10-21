=encoding utf8

=head1 NAME

CInet::Seq::Map - Lazy map on a Seq object

=head1 SYNOPSIS

    

=cut

# ABSTRACT: Lazy map on a Seq object
package CInet::Seq::Map;

use Modern::Perl 2018;
use Carp;

=head1 DESCRIPTION

=cut

use Role::Tiny::With;
with 'CInet::Seq';

sub new {
    my ($class, $prev, $code) = @_;
    bless { prev => $prev, code => $code }, $class
}

sub next {
    my ($prev, $code) = shift->@{'prev', 'code'};
    my $x = $prev->next;
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
