use Modern::Perl 2018;

use CInet::Base;
use Test::More;

my $A = CInet::Relation->new(Cube(4) => '0000_1111_00++_0-0-_000*_*111');
is $A->permute([1,2,3,4])->str, '0000111100++0-0-000**111';
is $A->permute([2,1,3,4])->str, '00000-0-000*111100++*111';
is $A->permute([2,1,4,3])->str, '0000000*0-0-00++1111*111';
is $A->permute([2,3,4,1])->str, '00++000**1110000111100--';
is $A->permute([2,3,1,4])->str, '11110-0-*11100000+0+000*';
is $A->dual->str, '00001111++00-0-0*000111*';

done_testing;
