use Modern::Perl 2018;

use CInet::Base;
use Test::More;
use Test::Deep;

cmp_deeply Cube(4)->set, [1, 2, 3, 4], 'cardinal argument to Cube';
is Cube([4, 3, 2, 1]), Cube(4), 'ordering does not matter and caching works';
cmp_deeply Cube(['a', 'b', 'c', 'd'])->set, ['a', 'b', 'c', 'd'], 'letters in ground set';
my $cube = Cube(['a', 'b', 'c', 'd']);
is $cube->pack([ ['a','b'], ['c','d'] ]), 4, 'letters in ground set work with pack';
cmp_deeply $cube->permute(['c', 'd', 'a', 'b'] => [ ['a','b'], ['c','d'] ]), [ ['c', 'd'], ['a','b']],
    'letters in ground set with work permute';

tie my %faces, 'CInet::Hash::FaceKey';
$faces{[[2,1],[5,3,4]]}++;
cmp_deeply [keys %faces], [[[1,2],[3,4,5]]], 'FaceKey packs and unpacks with set semantics';

done_testing;
