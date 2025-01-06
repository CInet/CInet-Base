use Modern::Perl 2018;

use CInet::Base;
use Test::More;

my $A = CIR(3, '101111');
is $A->cival([[1,2],[3]]), 0, 'cival with elementary statement';
is $A->cival([[1],[2],[3]]), 0, 'same elementary statement';
is $A->cival([[1,2],[3],[]]), 1, 'non-elementary statement';

$A->cival([[1,2],[3],[]]) = 0;
is "$A", '100000', 'after mutation of non-elementary statement';

$A = CIR(4, [[1,2],[3,4],[]], [[1,2,3],[4],[]], [[1],[2,3],[4]]);
is $A, CIR(4, '1100_0000_0000_0000_0000_0000'), 'constructor using global statements';

done_testing;
