use Modern::Perl 2018;

use CInet::Base;
use Test::More;

sub to_id {
    my ($n, $str) = @_;
    CInet::Relation->new(Cube($n) => $str)->ID
}

is to_id(3 => '0011_00'), '30';
is to_id(4 => '0000_0010_0110_0111_1100_1000'), '0267c8';
is to_id(5 => '0000_0001_0010_0011_0100_0101_0110_0111_1000_1001_1010_1011_1100_1101_1110_1111_1010_1111_1111_1110'), '0123456789abcdefaffe';

done_testing;
