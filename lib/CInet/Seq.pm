=encoding utf8

=head1 NAME

CInet::Seq - Role for lazy sequences of objects

=head1 SYNOPSIS

    # Implement the role
    package My::Seq {
        use Role::Tiny::With;
        with 'CInet::Seq';

        sub next { … }
    }

    # More methods provided
    say My::Seq->new(…)->grep(…)->count;

=cut

# ABSTRACT: Role for lazy sequences of objects
package CInet::Seq;

use Modern::Perl 2018;
use Carp;

use Role::Tiny;

=head1 DESCRIPTION

unidirectional iterator.
once exhausted, you can't go back.

=cut

=head2 Required method

=head3 next

    my $elt = $seq->next;
    last if not defined $elt;

Return the next element from sequence. This method should block of while
lazily producing the next element. If the sequence is exhausted, it must
return C<undef>.

=cut

requires qw(next);

=head2 Provided methods

The following methods are provided with a default implementation.

=cut

=head3 Basic data processing

=head4 inhabited

    my $empty = not $seq->inhabited;

Returns whether the sequence was inhabited. This is the opposite of
"exhausted". It has the side effect of pulling one element out of the
sequence to test for definedness.

=cut

sub inhabited {
    defined shift->next
}

=head4 list

    my @elts  = $seq->list;
    my $count = $seq->list;

Iterate the entire sequence and return a list of all captured elements
in list context. In scalar context, only the number of elements is
returned. The objects themselves are thrown away immediately to not
occupy memory needlessly.

=cut

sub list {
    my $self = shift;
    my (@list, $count);
    while (defined(my $x = $self->next)) {
        push @list, $x if wantarray;
        $count++;
    }
    wantarray ? @list : $count // 0
}

=head4 count

    my $count = $seq->count;

Return the number of elements in the sequence. The default implementation
of this method exhausts the sequence to accumulate the count. It does so
in a memory-friendly way, however.

=cut

sub count {
    scalar shift->list
}

=head4 first

    my $truthy = $seq->first;
    my $elt = $seq->first(\&code);

Return the first element of the sequence for which the coderef evaluates
to a truthy value, or C<undef> if the sequence is exhausted while looking
for such an element. This is implemented via C<< ->grep(\&code)->next >>.
See L<#grep> for details about the coderef.

If the coderef is not given, C<< sub{ 1 } >> is used, effectively returning
the B<first> unconsumed element of the sequence. As a special case of
L<#grep>, this is a relatively costly way of writing C<< ->next >>.

=cut

sub first {
    my ($self, $code) = @_;
    $code //= sub { 1 };
    $self->grep($code)->next
}

=head3 Functional primitives

Seq objects support the following basic functional methods:

=head4 map

    my $map = $seq->map(\&code);

Returns an instance of L<CInet::Seq::Map> wrapping the invocant to provide
a transformed sequence. The given coderef is expected to be unary and map
the elements of the invocant one at a time. It can refer to the current
element either via its first argument or the dynamically scoped C<$_>.

=cut

sub map {
    CInet::Seq::Map->new(@_)
}

=head4 grep

    my $grep = $seq->grep(\&code);

Returns an instance of L<CInet::Seq::Grep> wrapping the invocant to provide
a filtered sequence. The given coderef is expected to be unary and filter
the elements of the invocant one at a time. It can refer to the current
element either via its first argument or the dynamically scoped C<$_>.

=cut

sub grep {
    CInet::Seq::Grep->new(@_)
}

=head4 uniq

    my $uniq = $seq->uniq;
    my $uniq = $seq->uniq(\&stringifier);

Returns an instance of L<CInet::Seq::Uniq> wrapping the invocant to provide
a filtered sequence where only the first object with a given stringification
is forwarded to the consumer. An optional coderef can be given to specify
how to stringify a given element of the source sequence. It can refer to the
element either via its first argument or the dynamically scoped C<$_>.

The stringifications of elements are used as keys into a hash. This makes
it possible to return the next unique element as soon as it is pulled out
of the source sequence, at the expense of using potentially much memory.
The cache is freed immediately when the source sequence is exhausted.

The default stringification is C<< sub{ "". $_ } >>.

=cut

sub uniq {
    CInet::Seq::Uniq->new(@_)
}

=head4 reduce

    my $product = $seq->reduce(\&code, $id);

Iterates the entire sequence, applying the coderef to the return value of
the last application (initially the identity element C<$id>) and the next
element from the sequence. The last return value of the coderef is the
value returned by this method. The sequence is completely exhausted.
This operation is also called I<folding>.

The coderef is assumed to be binary, taking the previously produced
value as the first argument and the next sequence element as the second.
Alternatively, it can refer to the dynamically scoped special package
globals C<$a> and C<$b> like a C<sort> function would.

If not specified, the identity element C<$id> is initialized by pulling
the first element from the sequence before reducing. If the sequence is
not inhabited, C<undef> is returned immediately.

=cut

sub reduce {
    no strict 'refs';
    use Sub::Identify qw(stash_name);

    my ($self, $code, $id) = @_;
    my $a = $id // $self->next;
    return undef if not defined $a;

    # This code setting special globals $a and $b for the call to the
    # reducer is is borrowed from List::Util::PP but using Sub::Identify
    # because we can't rely on $code using globals from caller's package.
    my $pkg = stash_name($code);
    local *{"${pkg}::a"} = \$a;
    my $glob_b = \*{"${pkg}::b"};
    while (defined(my $b = $self->next)) {
        local *$glob_b = \$b;
        $a = $code->($a, $b);
    }
    $a
}

=head4 stringify

    my $strseq = $seq->stringify;
    my $strseq = $seq->stringify(\&stringifier);

This is a L<#map> which by default uses C<< "". $_ >> to convert all
incoming elements to strings.

=cut

sub stringify {
    my ($src, $code) = @_;
    $src->map($code // sub { "". $_ })
}

=head3 Junctions

The following methods collapse the entire sequence into a Boolean value,
depending on a junctive mode. They may short-circuit but in the worst case
they iterate the whole sequence:

=head4 any

    my $satisfiable = $seq->any(\&code);

Return whether the coderef evaluates to a truthy value for B<any> of
the sequence elements. This calls L<#first> internally, so refer to
its documentation as well.

This method stops the iteration over C<$seq> when the first witness
making the coderef truthy is found.

=cut

sub any {
    my $self = shift;
    defined $self->first(@_)
}

=head4 none

    my $unsatisfiable = $seq->none(\&code);

Return whether the coderef evaluates to a truthy value for B<none> of
the sequence elements. This calls L<#first> internally, so refer to
its documentation as well.

This method stops the iteration over C<$seq> when the first witness
making the coderef truthy is found.

=cut

sub none {
    my $self = shift;
    not defined $self->first(@_)
}

=head4 all

    my $tautology = $seq->all(\&code);

Return whether the coderef evaluates to a truthy value for B<all> of
the sequence elements. This calls L<#first> internally, so refer to
its documentation as well.

This method stops the iteration over C<$seq> when the first witness
making the coderef falsy is found.

=cut

sub all {
    my ($self, $code) = @_;
    $code //= sub { 1 };
    not defined $self->first(sub{ not $code->($_) })
}

=head3 Utilities

=head4 sort

    my $list = $seq->sort(with => sub{ $a <=> $b });
    my $list = $seq->sort(by => sub{ "". $_ }); # the default

Returns a sequence object for iterating the elements of C<$seq> in ascending
order. The sorting is performed in one of two ways:

=over

=item *

If the C<with> argument is specified, it is assumed to be a binary function
that can be used with C<sort>. It is passed two elements of the sequence to
compare. It can alternatively use the dynamically scoped special package
globals C<$a> and C<$b> in the familiar fashion.

=item *

Otherwise the elements are stringified and then sorted according to
L<Sort::Key::Natural>'s C<natkeysort>. The stringification method can
be overridden by passing a coderef as a C<by> named argument. This
coderef can use either its first argument or the dynamically scoped
topic C<$_>.

=back

WARNING: This method decays the sequence into a reified L<CInet::Seq::List>
because sorting algorithms, without a priori knowledge of the sequence, need
to see all the elements before they can be certain to return the smallest one.

=cut

sub sort {
    no strict 'refs';
    use Sub::Identify qw(stash_name);
    use Sort::Key::Natural;

    my $self = shift;
    my %arg = @_;

    my @list = $self->list;
    if (exists $arg{with}) {
        my $code = $arg{with};
        my $pkg = stash_name($code);
        @list = sort {
            # Make $a and $b available to $code's package
            local *{"${pkg}::a"} = \$a;
            local *{"${pkg}::b"} = \$b;
            $code->($a, $b)
        } @list;
    }
    else {
        my $code = $arg{by} // sub { shift };
        @list = natkeysort { $code->($_) } @list;
    }
    CInet::Seq::List->new(@list)
}

=head4 decorate

    my $decorated = $seq->decorate(\&decorator);

Returns another sequence which returns for every incoming element C<$elt>
the value C<< [$elt, &code($elt)] >>, that is an arrayref of the original
value and whatever is added by the coderef.

This method aids in Schwartzian transforms of a sequence.
Its opposite is L<#undecorate>.

=cut

sub decorate {
    my ($self, $code) = @_;
    $self->map(sub{ [ $_, $code->($_) ] })
}


=head4 undecorate

    my $tidied = $seq->undecorate;
    my $tidied = $seq->undecorate(\&tidier);

This method aids in Schwartzian transforms of a sequence.
Its opposite is L<#decorate>.

It is just a L<#map> with a default coderef of C<< sub { shift->[0] } >>
assuming that it undecorates a sequence formatted by L<#decorate>.
If the incoming elements are decorated value compounds of a different
format, pass your own coderef. It can either refer to its first argument
or the dynamically scoped topic C<$_>.

=cut

sub undecorate {
    my ($self, $code) = @_;
    $code //= sub { shift->[0] };
    $self->map($code)
}

=head3 Symmetry reduction

=head4 modulo

    my $mod = $seq->modulo(\@group);

Returns an instance of L<CInet::Seq::Modulo> wrapping the invocant to provide
a filtered sequence where only the first representative of each group orbit
is forwarded to the consumer. The C<\@group> arrayref is typically one returned
by the L<CInet::Symmetry> subs and contains a permutation representation of
the group action. The elements of the sequence must implement an C<act> method
which applies such permutations.

All consumed elements and their images under the group are stringified and used
as hash keys. This makes it possible to return the next new representative
element as soon as it is pulled out of the source sequence, at the expense of
using potentially much memory. The cache is freed immediately when the source
sequence is exhausted.

=cut

# TODO: Add something that does not reduce modulo a group
# but inflates each element to its entire orbit, but returns
# each orbit just once.

sub modulo {
    CInet::Seq::Modulo->new(@_)
}

=head1 AUTHOR

Tobias Boege <tobs@taboege.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (C) 2020 by Tobias Boege.

This is free software; you can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

=cut

":wq"
