#!/usr/bin/env perl
use strict;
use warnings;
use autodie;

use Math::Random qw/random_exponential/;


# 평균이 1000이고 지수분포를 따르는 랜덤한 수 3백만 개의 배열
my @array = random_exponential( 3000000, 1000 );

# 소숫점은 잘라내고 1의 자리 단위로 빈도수 카운트
my %freq;
$freq{ int($_) }++ foreach ( @array );

print "size : ", scalar @array, "\n";


# 값이 작은 순으로 배치한 순차 파일
open my $f_seq, ">", "input_seq.txt";
foreach my $key ( sort {$a<=>$b} keys %freq ) {
    foreach my $count ( 1 .. $freq{$key} ) {
        print {$f_seq} "$key\t$count\n";
    }
}
close $f_seq;

# @array에 나타난 순서로 배치한 랜덤 파일
open my $f_rnd, ">", "input_rnd.txt";
my %count = ();
foreach my $num ( @array ) {
    my $key = int($num);
    $count{$key}++;
    print {$f_rnd} "$key\t$count{$key}\n";
}
close $f_rnd;

# 검증을 위해 따로 데이타에 대한 정보를 남겨둠
open my $f_log, ">", "input_log.txt";
my ( $max_n, $max_f ) = (0, -1);
print {$f_log} "------- freq --------\n";
foreach ( sort {$a<=>$b} keys %freq ) {
    print {$f_log} "[$_][$freq{$_}]\n";
    if ( $max_f < $freq{$_} ) {
        $max_n = $_;
        $max_f = $freq{$_};
    }
}
print {$f_log} "\n";

print {$f_log} "------- sorted freq --------\n";
foreach ( sort {$freq{$b}<=>$freq{$a}} keys %freq ) {
    print {$f_log} "[$_][$freq{$_}]\n";
}
print {$f_log} "\n";

print {$f_log} "max: [$max_n][$max_f]\n";
print {$f_log} "# of keys: ", scalar (keys %freq), "\n";
print {$f_log} "# of nums: ", scalar (@array), "\n";
close $f_log;

