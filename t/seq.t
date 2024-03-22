use Modern::Perl 2018;

use CInet::Base;
use Test::More;
use Test::Deep;

use Algorithm::Combinatorics qw(subsets);

my $seq = CInet::Seq::Wrapper->new(scalar subsets([1,2,3,4,5,6], 2));
is $seq->count, 15, 'count on coderef';
is $seq->count, 0, 'sequence becomes exhausted';

$seq = CInet::Seq::Wrapper->new(scalar subsets([1,2,3,4], 2));
cmp_deeply [$seq->list], [[1,2],[1,3],[1,4],[2,3],[2,4],[3,4]], 'listing';

done_testing;
