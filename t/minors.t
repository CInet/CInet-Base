use Modern::Perl 2018;

use CInet::Base;
use CInet::Data::Loader;

use Test::More;
use Test::Deep;

use Perl6::Junction qw(any all none);

# Make a nice string view of a [$minor, $face] arrayref.
sub format_minor {
    my ($m, $f) = shift->@*;
    FACE($f) .': '. $m
}

# Pick the Vamos gaussoid as an example to check the minors function in-depth.
my $V = CInet::Relation->new(5 => '01111111110111111110111111110111111011111111111011111101111101111011111111011111');
cmp_deeply [$V->minors(3)->stringify(\&format_minor)->list], set(
    '123|: 011111', '123|4: 110111', '123|5: 111101', '123|45: 111111', '124|: 011111', '124|3: 111111', '124|5: 110111', '124|35: 111110',
    '125|: 011111', '125|3: 111011', '125|4: 111111', '125|34: 111101', '134|: 101111', '134|2: 111110', '134|5: 110111', '134|25: 111111',
    '135|: 111110', '135|2: 111011', '135|4: 011111', '135|24: 111111', '145|: 101111', '145|2: 111101', '145|3: 111111', '145|23: 110111',
    '234|: 111111', '234|1: 111110', '234|5: 011111', '234|15: 111011', '235|: 101111', '235|1: 111101', '235|4: 111011', '235|14: 111111',
    '245|: 111110', '245|1: 111111', '245|3: 111011', '245|13: 101111', '345|: 111111', '345|1: 110111', '345|2: 111101', '345|12: 011111',
), '3-minors of the Vamos gaussoid';

cmp_deeply [$V->minors(4)->stringify(\&format_minor)->list], set(
    '1234|: 011111011111111111111110', '1234|5: 111111110111011111101111', '1235|: 011111111110110111111011', '1235|4: 111101111111111111011111',
    '1245|: 011111011111111111111101', '1245|3: 111111111011111011011111', '1345|: 101111011111111110111111', '1345|2: 111111111011101111110111',
    '2345|: 110111111110111111111011', '2345|1: 111111101111101101111111',
), '4-minors of the Vamos gaussoid';

cmp_deeply [$V->minors(5)->stringify(\&format_minor)->list], set(
    '12345|: 01111111110111111110111111110111111011111111111011111101111101111011111111011111',
), '5-minors of the Vamos gaussoid';

my @LUBF3  = split /\n/, data_file('LUBF3-list.txt');
my @LUBF4  = split /\n/, data_file('LUBF4-list.txt');
my @ELUBF4 = split /\n/, data_file('ELUBF4-list.txt');

# Count LUBF gaussoids extracted from ELUBF4-list.txt
my $count = 0;
for my $x (@ELUBF4) {
    my $A = CInet::Relation->new(4 => $x);
    $count++ if all($A->minors(3)->undecorate->stringify->list) eq any(@LUBF3);
}
is $count, 0+ @LUBF4, 'LUBF4 counts match';

# Same but compare with the exact lists and using a different junction.
my @res;
for my $x (@ELUBF4) {
    my $A = CInet::Relation->new(4 => $x);
    push @res, "$A" if none($A->minors(3)->undecorate->stringify->list) eq '111111';
}
cmp_deeply \@res, set(@LUBF4), 'LUBF4 lists match as sets';

done_testing;

__DATA__
@@ LUBF3-list.txt
000000
001100
000011
011111
101111
110000
111101
111110
111011
110111
@@ LUBF4-list.txt
000000000000000000000000
000011110000000000000000
000000001111000000000000
000000000000111100000000
000000001111111100000000
010111110000111100000000
000000000000000011110000
000011110000000011110000
001100001111000011110000
000000000000111111111100
010111110010111111111100
001100101111111111111100
000011111111000000001010
001111111111001011111010
010111111111111100101010
011011111111111111110110
011111111101110111111110
011111011111111111011110
000000000000111111110011
010111110001111111110011
001100011111111111110011
000011111111000000000101
001111111111000111110101
010111111111111100010101
011111101111111111100111
011111111110111011110111
011011111111111111111001
011111011111111111101101
011111111101111011111101
011111111110110111111011
011111101111111111011011
000000000000000000001111
000000000000111100111111
000000000000110011111111
000000000000111111001111
000000000000001111111111
000000111111000000001111
000100111111111100111111
001000111111111111001111
000011001111000000001111
000011111100000000001111
000011110011000000001111
010011110011110011111111
010011001111111100111111
000111110011001111111111
001011111100001111111111
111100000000000000000000
111100000000000000001111
111111110000010100000000
111111111100010101001111
111100001111000001010000
111100111111000101011111
111111001111010001011111
111111110011010100011111
111101010000111100000000
111101010100111111001111
111110100000111100000000
111110101000111111001111
101011110000111100000000
111111110000101000000000
111111111100101010001111
111110011111111110011111
101011111111111110001010
111101101111111110011111
111101011111111101010001
101011111111111101000101
111110101111111101010100
111110110111111011011111
111111100111101111011111
100011001111111111001111
110110111111111111011011
110101111111111111011110
111111011011101111011111
111101111011111011011111
111110100010111100111111
111101010001111100111111
111111110011101000101111
101111011111111101111110
101111101111111101111011
111110111101111001111111
111111101101101101111111
111110011111111101101111
111010111111111101111011
111111011110101101111111
111101111110111001111111
111101101111111101101111
111001111111111101111110
111110111101110110111111
111111101101011110111111
101111101111111110110111
101111011111111110111101
111100001111000010100000
111010111111111110110111
111101011111111110100010
111111001111100010101111
111101111110110110111111
111110101111111110101000
111100111111001010101111
111111011110011110111111
111001111111111110111101
111100000101000011110000
111100001010000011110000
110000001111000011110000
111111110101010111110001
110011111111010011110101
111111111010010111110100
101011110100111111110011
101111111011111011110111
100111111111111111110110
110001001111111111110011
111111110101101011110010
110110111111111111100111
111011111011101111110111
110111111110101111110111
111110001010110011111111
111100101010001111111111
111110110111110111101111
111100010101001111111111
110010001111111111111100
100011111100110011111111
111101000101110011111111
111111111001100111111111
101111111011110111111011
101111110111110111111110
110011111111100011111010
111101111011110111101111
111111110110100111111111
111111111001011011111111
101011111000111111111100
110111111101101111111101
110111111101011111111110
111111111010101011111000
111011111011011111111011
100111111111111111111001
110111111110011111111011
110101111111111111101101
111111011011011111101111
101111110111111011111101
111011110111101111111101
111111110110011011111111
111011110111011111111110
111111100111011111101111
@@ ELUBF4-list.txt
000000000000000000000000
000000000000000000001111
000000000000000011110000
000000000000001111111111
000000000000110011111111
000000000000111100000000
000000000000111100111111
000000000000111111001111
000000000000111111110011
000000000000111111111100
000000000000111111111111
000000001111000000000000
000000001111111100000000
000000111111000000001111
000011001111000000001111
000011110000000000000000
000011110000000011110000
000011110011000000001111
000011111100000000001111
000011111111000000000101
000011111111000000001010
000011111111000000001111
000100111111111100111111
000111110011001111111111
001000111111111111001111
001011111100001111111111
001100001111000011110000
001100011111111111110011
001100101111111111111100
001100111111001111111111
001100111111110111111111
001100111111111011111111
001100111111111111111111
001111011111001111111111
001111101111001111111111
001111111111000111110101
001111111111001011111010
001111111111001111111111
010011001111111100111111
010011110011110011111111
010111110000111100000000
010111110001111111110011
010111110010111111111100
010111110011111100111111
010111110011111111011111
010111110011111111101111
010111110011111111111111
010111111101111100111111
010111111110111100111111
010111111111111100010101
010111111111111100101010
010111111111111100111111
011011111111111111110110
011011111111111111110111
011011111111111111111001
011011111111111111111011
011011111111111111111101
011011111111111111111110
011011111111111111111111
011111001111110011111111
011111011110111111111111
011111011111111111011110
011111011111111111011111
011111011111111111101101
011111011111111111101111
011111011111111111111101
011111011111111111111110
011111011111111111111111
011111101101111111111111
011111101111111111011011
011111101111111111011111
011111101111111111100111
011111101111111111101111
011111101111111111110111
011111101111111111111011
011111101111111111111111
011111111100111111001111
011111111101110111111110
011111111101110111111111
011111111101111011111101
011111111101111011111111
011111111101111111111101
011111111101111111111110
011111111101111111111111
011111111110110111111011
011111111110110111111111
011111111110111011110111
011111111110111011111111
011111111110111111110111
011111111110111111111011
011111111110111111111111
011111111111110111101111
011111111111110111111011
011111111111110111111110
011111111111110111111111
011111111111111011011111
011111111111111011110111
011111111111111011111101
011111111111111011111111
011111111111111111011011
011111111111111111011110
011111111111111111011111
011111111111111111100111
011111111111111111101101
011111111111111111101111
011111111111111111110110
011111111111111111110111
011111111111111111111001
011111111111111111111011
011111111111111111111101
011111111111111111111110
011111111111111111111111
100011001111111111001111
100011111100110011111111
100111111111111111110110
100111111111111111110111
100111111111111111111001
100111111111111111111011
100111111111111111111101
100111111111111111111110
100111111111111111111111
101011110000111100000000
101011110100111111110011
101011110111111111001111
101011111000111111111100
101011111011111111001111
101011111100111101111111
101011111100111110111111
101011111100111111001111
101011111100111111111111
101011111111111101000101
101011111111111110001010
101011111111111111001111
101111001111110011111111
101111011011111111111111
101111011111111101111110
101111011111111101111111
101111011111111110111101
101111011111111110111111
101111011111111111111101
101111011111111111111110
101111011111111111111111
101111100111111111111111
101111101111111101111011
101111101111111101111111
101111101111111110110111
101111101111111110111111
101111101111111111110111
101111101111111111111011
101111101111111111111111
101111110011111100111111
101111110111110111111110
101111110111110111111111
101111110111111011111101
101111110111111011111111
101111110111111111111101
101111110111111111111110
101111110111111111111111
101111111011110111111011
101111111011110111111111
101111111011111011110111
101111111011111011111111
101111111011111111110111
101111111011111111111011
101111111011111111111111
101111111111110110111111
101111111111110111111011
101111111111110111111110
101111111111110111111111
101111111111111001111111
101111111111111011110111
101111111111111011111101
101111111111111011111111
101111111111111101111011
101111111111111101111110
101111111111111101111111
101111111111111110110111
101111111111111110111101
101111111111111110111111
101111111111111111110110
101111111111111111110111
101111111111111111111001
101111111111111111111011
101111111111111111111101
101111111111111111111110
101111111111111111111111
110000001111000011110000
110001001111111111110011
110001111111110011111111
110010001111111111111100
110010111111110011111111
110011001111011111111111
110011001111101111111111
110011001111110011111111
110011001111111111111111
110011111111010011110101
110011111111100011111010
110011111111110011111111
110100111111001111111111
110101111110111111111111
110101111111111111011110
110101111111111111011111
110101111111111111101101
110101111111111111101111
110101111111111111111101
110101111111111111111110
110101111111111111111111
110110111101111111111111
110110111111111111011011
110110111111111111011111
110110111111111111100111
110110111111111111101111
110110111111111111110111
110110111111111111111011
110110111111111111111111
110111111100111111001111
110111111101011111111110
110111111101011111111111
110111111101101111111101
110111111101101111111111
110111111101111111111101
110111111101111111111110
110111111101111111111111
110111111110011111111011
110111111110011111111111
110111111110101111110111
110111111110101111111111
110111111110111111110111
110111111110111111111011
110111111110111111111111
110111111111011111101111
110111111111011111111011
110111111111011111111110
110111111111011111111111
110111111111101111011111
110111111111101111110111
110111111111101111111101
110111111111101111111111
110111111111111111011011
110111111111111111011110
110111111111111111011111
110111111111111111100111
110111111111111111101101
110111111111111111101111
110111111111111111110110
110111111111111111110111
110111111111111111111001
110111111111111111111011
110111111111111111111101
110111111111111111111110
110111111111111111111111
111000111111001111111111
111001111011111111111111
111001111111111101111110
111001111111111101111111
111001111111111110111101
111001111111111110111111
111001111111111111111101
111001111111111111111110
111001111111111111111111
111010110111111111111111
111010111111111101111011
111010111111111101111111
111010111111111110110111
111010111111111110111111
111010111111111111110111
111010111111111111111011
111010111111111111111111
111011110011111100111111
111011110111011111111110
111011110111011111111111
111011110111101111111101
111011110111101111111111
111011110111111111111101
111011110111111111111110
111011110111111111111111
111011111011011111111011
111011111011011111111111
111011111011101111110111
111011111011101111111111
111011111011111111110111
111011111011111111111011
111011111011111111111111
111011111111011110111111
111011111111011111111011
111011111111011111111110
111011111111011111111111
111011111111101101111111
111011111111101111110111
111011111111101111111101
111011111111101111111111
111011111111111101111011
111011111111111101111110
111011111111111101111111
111011111111111110110111
111011111111111110111101
111011111111111110111111
111011111111111111110110
111011111111111111110111
111011111111111111111001
111011111111111111111011
111011111111111111111101
111011111111111111111110
111011111111111111111111
111100000000000000000000
111100000000000000001111
111100000101000011110000
111100001010000011110000
111100001111000001010000
111100001111000010100000
111100001111000011110000
111100010101001111111111
111100101010001111111111
111100111111000101011111
111100111111001010101111
111100111111001111111111
111101000101110011111111
111101010000111100000000
111101010001111100111111
111101010100111111001111
111101010101111111110011
111101010101111111111101
111101010101111111111110
111101010101111111111111
111101011011111111110011
111101011110111111110011
111101011111111101010001
111101011111111110100010
111101011111111111110011
111101101111111101101111
111101101111111101111111
111101101111111110011111
111101101111111110111111
111101101111111111011111
111101101111111111101111
111101101111111111111111
111101111010111111111100
111101111011110111101111
111101111011110111111111
111101111011111011011111
111101111011111011111111
111101111011111111011111
111101111011111111101111
111101111011111111111111
111101111110110110111111
111101111110110111111111
111101111110111001111111
111101111110111011111111
111101111110111101111111
111101111110111110111111
111101111110111111111111
111101111111110110111111
111101111111110111101111
111101111111110111111110
111101111111110111111111
111101111111111001111111
111101111111111011011111
111101111111111011111101
111101111111111011111111
111101111111111101101111
111101111111111101111110
111101111111111101111111
111101111111111110011111
111101111111111110111101
111101111111111110111111
111101111111111111011110
111101111111111111011111
111101111111111111101101
111101111111111111101111
111101111111111111111101
111101111111111111111110
111101111111111111111111
111110001010110011111111
111110011111111101101111
111110011111111101111111
111110011111111110011111
111110011111111110111111
111110011111111111011111
111110011111111111101111
111110011111111111111111
111110100000111100000000
111110100010111100111111
111110100111111111111100
111110101000111111001111
111110101010111111110111
111110101010111111111011
111110101010111111111100
111110101010111111111111
111110101101111111111100
111110101111111101010100
111110101111111110101000
111110101111111111111100
111110110101111111110011
111110110111110111101111
111110110111110111111111
111110110111111011011111
111110110111111011111111
111110110111111111011111
111110110111111111101111
111110110111111111111111
111110111101110110111111
111110111101110111111111
111110111101111001111111
111110111101111011111111
111110111101111101111111
111110111101111110111111
111110111101111111111111
111110111111110110111111
111110111111110111101111
111110111111110111111011
111110111111110111111111
111110111111111001111111
111110111111111011011111
111110111111111011110111
111110111111111011111111
111110111111111101101111
111110111111111101111011
111110111111111101111111
111110111111111110011111
111110111111111110110111
111110111111111110111111
111110111111111111011011
111110111111111111011111
111110111111111111100111
111110111111111111101111
111110111111111111110111
111110111111111111111011
111110111111111111111111
111111001111010001011111
111111001111100010101111
111111001111110011111111
111111011010111111111100
111111011011011111101111
111111011011011111111111
111111011011101111011111
111111011011101111111111
111111011011111111011111
111111011011111111101111
111111011011111111111111
111111011110011110111111
111111011110011111111111
111111011110101101111111
111111011110101111111111
111111011110111101111111
111111011110111110111111
111111011110111111111111
111111011111011110111111
111111011111011111101111
111111011111011111111110
111111011111011111111111
111111011111101101111111
111111011111101111011111
111111011111101111111101
111111011111101111111111
111111011111111101101111
111111011111111101111110
111111011111111101111111
111111011111111110011111
111111011111111110111101
111111011111111110111111
111111011111111111011110
111111011111111111011111
111111011111111111101101
111111011111111111101111
111111011111111111111101
111111011111111111111110
111111011111111111111111
111111100101111111110011
111111100111011111101111
111111100111011111111111
111111100111101111011111
111111100111101111111111
111111100111111111011111
111111100111111111101111
111111100111111111111111
111111101101011110111111
111111101101011111111111
111111101101101101111111
111111101101101111111111
111111101101111101111111
111111101101111110111111
111111101101111111111111
111111101111011110111111
111111101111011111101111
111111101111011111111011
111111101111011111111111
111111101111101101111111
111111101111101111011111
111111101111101111110111
111111101111101111111111
111111101111111101101111
111111101111111101111011
111111101111111101111111
111111101111111110011111
111111101111111110110111
111111101111111110111111
111111101111111111011011
111111101111111111011111
111111101111111111100111
111111101111111111101111
111111101111111111110111
111111101111111111111011
111111101111111111111111
111111110000010100000000
111111110000101000000000
111111110000111100000000
111111110011010100011111
111111110011101000101111
111111110011111100111111
111111110101010111110001
111111110101101011110010
111111110101111111110011
111111110110011011111111
111111110110011111111111
111111110110100111111111
111111110110101111111111
111111110110110111111111
111111110110111011111111
111111110110111111111111
111111110111011011111111
111111110111011111101111
111111110111011111111110
111111110111011111111111
111111110111100111111111
111111110111101111011111
111111110111101111111101
111111110111101111111111
111111110111110111101111
111111110111110111111110
111111110111110111111111
111111110111111011011111
111111110111111011111101
111111110111111011111111
111111110111111111011110
111111110111111111011111
111111110111111111101101
111111110111111111101111
111111110111111111111101
111111110111111111111110
111111110111111111111111
111111111001011011111111
111111111001011111111111
111111111001100111111111
111111111001101111111111
111111111001110111111111
111111111001111011111111
111111111001111111111111
111111111010010111110100
111111111010101011111000
111111111010111111111100
111111111011011011111111
111111111011011111101111
111111111011011111111011
111111111011011111111111
111111111011100111111111
111111111011101111011111
111111111011101111110111
111111111011101111111111
111111111011110111101111
111111111011110111111011
111111111011110111111111
111111111011111011011111
111111111011111011110111
111111111011111011111111
111111111011111111011011
111111111011111111011111
111111111011111111100111
111111111011111111101111
111111111011111111110111
111111111011111111111011
111111111011111111111111
111111111100010101001111
111111111100101010001111
111111111100111111001111
111111111101011011111111
111111111101011110111111
111111111101011111111110
111111111101011111111111
111111111101100111111111
111111111101101101111111
111111111101101111111101
111111111101101111111111
111111111101110110111111
111111111101110111111110
111111111101110111111111
111111111101111001111111
111111111101111011111101
111111111101111011111111
111111111101111101111110
111111111101111101111111
111111111101111110111101
111111111101111110111111
111111111101111111111101
111111111101111111111110
111111111101111111111111
111111111110011011111111
111111111110011110111111
111111111110011111111011
111111111110011111111111
111111111110100111111111
111111111110101101111111
111111111110101111110111
111111111110101111111111
111111111110110110111111
111111111110110111111011
111111111110110111111111
111111111110111001111111
111111111110111011110111
111111111110111011111111
111111111110111101111011
111111111110111101111111
111111111110111110110111
111111111110111110111111
111111111110111111110111
111111111110111111111011
111111111110111111111111
111111111111010101010101
111111111111010101011011
111111111111010101011110
111111111111010101011111
111111111111010110110101
111111111111010111100101
111111111111010111110101
111111111111011011111111
111111111111011110101010
111111111111011110111111
111111111111011111101111
111111111111011111111011
111111111111011111111110
111111111111011111111111
111111111111100111111111
111111111111101001111010
111111111111101010100111
111111111111101010101010
111111111111101010101101
111111111111101010101111
111111111111101011011010
111111111111101011111010
111111111111101101010101
111111111111101101111111
111111111111101111011111
111111111111101111110111
111111111111101111111101
111111111111101111111111
111111111111110110101010
111111111111110110111111
111111111111110111101111
111111111111110111111011
111111111111110111111110
111111111111110111111111
111111111111111001010101
111111111111111001111111
111111111111111011011111
111111111111111011110111
111111111111111011111101
111111111111111011111111
111111111111111101010101
111111111111111101101111
111111111111111101111011
111111111111111101111110
111111111111111101111111
111111111111111110011111
111111111111111110101010
111111111111111110110111
111111111111111110111101
111111111111111110111111
111111111111111111011011
111111111111111111011110
111111111111111111011111
111111111111111111100111
111111111111111111101101
111111111111111111101111
111111111111111111110110
111111111111111111110111
111111111111111111111001
111111111111111111111011
111111111111111111111101
111111111111111111111110
111111111111111111111111
