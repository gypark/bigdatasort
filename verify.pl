#!/usr/bin/env perl
use strict;
use warnings;
use autodie;

local $| = 1;
my %num = ();
my @sequence = ();

my $sorted_file = $ARGV[0] || 'sorted_1_rnd.txt';
open my $in, "<", $sorted_file;
while ( my $line = <$in> ) {
    my ( $key, $num ) = split(/\s+/, $line);
    $num{$key}++;

    if ( $num{$key} != $num ) {
        warn "line $. : [$key][$num{$key}] expected but [$key][$num] appeared";
    }

    if ( $num{$key} == 1 ) {
        push @sequence, $key;
    }
}
close $in;

my $last_num = 9999999;
foreach my $key ( @sequence ) {
#     print "[$key][$num{$key}]\n";

    if ( $num{$key} > $last_num ) {
        warn "sort error: key[$key] should be come eariler";
    }
}
