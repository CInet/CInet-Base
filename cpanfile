requires 'Modern::Perl', '>= 1.20180000';
requires 'Carp';
requires 'Clone';
requires 'List::Util';

requires 'Scalar::Util';
requires 'List::SomeUtils';
requires 'Export::Attrs';
requires 'Sub::Identify';
requires 'Import::Into';
requires 'Role::Tiny';

requires 'Sort::Key::Natural';
requires 'Algorithm::Combinatorics';
requires 'Array::Set';
requires 'Perl6::Junction';

on 'test' => sub {
    requires 'ntheory';
    requires 'Test::More';
    requires 'Test::Deep';
};