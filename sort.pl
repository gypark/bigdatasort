#!/usr/bin/env perl
use strict;
use warnings;
use autodie;
use FileCache;
use Time::HiRes qw/gettimeofday tv_interval/;
use Sort::External;
use Sort::Radix;

if ( not defined $ARGV[0] or not grep { $ARGV[0] == $_ } (11,12,21,22,31,32,41,42,51,52,61,62,71,72,81,82,91,92,101,102) ) {
    print <<EOF;
arg:
11 - in-memory sort. sequantial
12 - in-memory sort. random

21 - open-close in each iteration. sequatial
22 - open-close in each iteration. random

31 - open-close once. maybe die. sequantial
32 - open-close once. maybe die. random

41 - use cacheout. sequantial
42 - use cacheout. random

51 - use cacheout. sequantial
52 - use cacheout. maybe error. random

61 - use Sort::External. sequatial
62 - use Sort::External. random

71 - use Sort::External, GRT(sprintf). sequatial
72 - use Sort::External, GRT(sprintf). random

81 - use Sort::External, GRT(pack). sequatial
82 - use Sort::External, GRT(pack). random

91 - use Sort::External, GRT(sprintf). Memory size. sequatial
92 - use Sort::External, GRT(sprintf). Memory size. random
EOF
    exit 1;
}

my $input_file = ( $ARGV[0] % 10 == 1 ) ? 'input_seq.txt' : 'input_rnd.txt';
my $output_postfix = ( $ARGV[0] % 10 == 1 ) ? 'seq.txt' : 'rnd.txt';
my $method = int($ARGV[0] / 10);

if ( $method == 1 ) {       # in-memory sort
    print "method 1 - in-memory sort. [$input_file]\n";
    my $t0 = [ gettimeofday ];

    open my $in, '<', $input_file;
    my @array = <$in>;
    close $in;
    print " laptime time after loading file : ", tv_interval($t0), "\n";

    my %freq = ();
    foreach my $line ( @array ) {
        my $key = (split /\s+/, $line)[0];
        $freq{$key}++;
    }

    print " laptime time after counting : ", tv_interval($t0), "\n";

    my @sorted =
        map { $_->[1] }
        sort { $freq{$b->[0]} <=> $freq{$a->[0]} or $a->[0] <=> $b->[0] }
        map { [ (split /\s+/, $_)[0], $_ ] }
        @array;
    print " laptime time after sorting : ", tv_interval($t0), "\n";

    my $output_file = "sorted_1_$output_postfix";
    open my $out, ">", $output_file;
    foreach ( @sorted ) {
        print {$out} $_;
    }
    close $out;
    print "method 1 - save [$output_file]\n";
    print " total elapsed time : ", tv_interval($t0), "\n";
    
}
elsif ( $method == 2 ) {    # open-close in each iteration
    print "method 2 - open-close in each iteration. [$input_file]\n";
    my $t0 = [ gettimeofday ];

    my %freq = ();
    open my $in, '<', $input_file;
    while ( my $line = <$in> ) {
        my $key = (split /\s+/, $line)[0];
        $freq{$key}++;
        
        open my $tmp, '>>', $key;
        print {$tmp} $line;
        close $tmp;
    }
    close $in;
    print " laptime time after loading, counting, splitting : ", tv_interval($t0), "\n";

    my $output_file = "sorted_2_$output_postfix";
    open my $out, ">", $output_file;
    foreach my $key ( sort { $freq{$b} <=> $freq{$a} or $a <=> $b } keys %freq ) {
        open my $tmp, '<', $key;
        while ( my $line = <$tmp> ) {
            print {$out} $line;
        }
        close $tmp;
        unlink $key;
    }
    close $out;

    print "method 2 - save [$output_file]\n";
    print " total elapsed time : ", tv_interval($t0), "\n";
}
elsif ( $method == 3 ) {    # open-close once
    print "method 3 - open-close once. [$input_file]\n";
    my $t0 = [ gettimeofday ];

    my %freq = ();
    my %fh = ();
    open my $in, '<', $input_file;
    while ( my $line = <$in> ) {
        my $key = (split /\s+/, $line)[0];
        $freq{$key}++;
        
        if ( not exists $fh{$key} ) {
            open $fh{$key}, '>', $key;
        }
        print {$fh{$key}} $line;
    }
    close $in;
    close $_ foreach ( values %fh );
    print " laptime time after loading, counting, splitting : ", tv_interval($t0), "\n";

    my $output_file = "sorted_3_$output_postfix";
    open my $out, ">", $output_file;
    foreach my $key ( sort { $freq{$b} <=> $freq{$a} or $a <=> $b } keys %freq ) {
        open my $tmp, '<', $key;
        while ( my $line = <$tmp> ) {
            print {$out} $line;
        }
        close $tmp;
        unlink $key;
    }
    close $out;

    print "method 3 - save [$output_file]\n";
    print " total elapsed time : ", tv_interval($t0), "\n";
}
elsif ( $method == 4 ) {                      # cacheout
    no strict 'refs';
    print "method 4 - use cacheout. [$input_file]\n";
    my $t0 = [ gettimeofday ];

    my %freq = ();
    my %fh = ();
    open my $in, '<', $input_file;
    while ( my $line = <$in> ) {
        my $key = (split /\s+/, $line)[0];
        $freq{$key}++;

        $fh{$key} = cacheout "$key.txt";
        print {$fh{$key}} $line;
    }
    close $in;
    # 필수!
    cacheout_close $_ foreach ( values %fh );
    print " laptime time after loading, counting, splitting : ", tv_interval($t0), "\n";

    my $output_file = "sorted_4_$output_postfix";
    open my $out, ">", $output_file;
    foreach my $key ( sort { $freq{$b} <=> $freq{$a} or $a <=> $b } keys %freq ) {
        open my $tmp, '<', "$key.txt";
        while ( my $line = <$tmp> ) {
            print {$out} $line;
        }
        close $tmp;
        unlink "$key.txt";
    }
    close $out;

    print "method 4 - save [$output_file]\n";
    print " total elapsed time : ", tv_interval($t0), "\n";
}
elsif ( $method == 5 ) {
    no strict 'refs';
    no warnings 'closed';
    print "method 5 - use cacheout (maybe error with random sequence). [$input_file]\n";
    my $t0 = [ gettimeofday ];

    my %freq = ();
    my %fh = ();
    open my $in, '<', $input_file;
    while ( my $line = <$in> ) {
        my $key = (split /\s+/, $line)[0];
        $freq{$key}++;

#         if ( not defined $fh{$key} ) {
#         if ( not defined $fh{$key} or $fh{$key} ne "$key.txt"  ) {
#         if ( not defined $fh{$key} or tell($fh{$key}) == -1  ) {
        if ( not exists $fh{$key} ) {
            $fh{$key} = cacheout "$key.txt";
        }
        print {$fh{$key}} $line;
    }
    close $in;
    cacheout_close $_ foreach ( values %fh );
    print " laptime time after loading, counting, splitting : ", tv_interval($t0), "\n";

    my $output_file = "sorted_5_$output_postfix";
    open my $out, ">", $output_file;
    foreach my $key ( sort { $freq{$b} <=> $freq{$a} or $a <=> $b } keys %freq ) {
        open my $tmp, '<', "$key.txt";
        while ( my $line = <$tmp> ) {
            print {$out} $line;
        }
        close $tmp;
        unlink "$key.txt";
    }
    close $out;

    print "method 5 - save [$output_file]\n";
    print " total elapsed time : ", tv_interval($t0), "\n";
}
elsif ( $method == 6 ) {            # Sort::External;
    print "method 6 - use Sort::External. [$input_file]\n";
    my $t0 = [ gettimeofday ];

    # 일단 freq 계산을 먼저 해야 함
    my %freq = ();
    open my $in, '<', $input_file;
    while ( my $line = <$in> ) {
        my $key = (split /\s+/, $line)[0];
        $freq{$key}++;
    }
    close $in;

    print " laptime time after loading, counting : ", tv_interval($t0), "\n";

    my $sortex = Sort::External->new(
                        sortsub => sub { $freq{(split(/\s+/,$Sort::External::b))[0]}
                                         <=>
                                         $freq{(split(/\s+/,$Sort::External::a))[0]}
                                                        or
                                         (split(/\s+/,$Sort::External::a))[0]
                                         <=>
                                         (split(/\s+/,$Sort::External::b))[0]
                                                        or
                                         (split(/\s+/,$Sort::External::a))[1]
                                         <=>
                                         (split(/\s+/,$Sort::External::b))[1]
                                     }
                                 );

    # 다시 열고 feed
    open $in, '<', $input_file;
    while ( my $line = <$in> ) {
        $sortex->feed( $line );
    }
    close $in;

    print " laptime time after feeding : ", tv_interval($t0), "\n";

    $sortex->finish;
    print " laptime time after finish (sorting?) : ", tv_interval($t0), "\n";

    my $output_file = "sorted_6_$output_postfix";
    open my $out, ">", $output_file;
    while ( defined( $_ = $sortex->fetch ) ) {
        print {$out} $_;
    }

    close $out;

    print "method 6 - save [$output_file]\n";
    print " total elapsed time : ", tv_interval($t0), "\n";
}
elsif ( $method == 7 ) {            # Sort::External, GRT;
    print "method 7 - use Sort::External, GRT(sprintf) [$input_file]\n";
    my $t0 = [ gettimeofday ];

    # GRT 변환을 위해서는 일단 freq 를 알아야 함
    my %freq = ();
    open my $in, '<', $input_file;
    while ( my $line = <$in> ) {
        my $key = (split /\s+/, $line)[0];
        $freq{$key}++;
    }
    close $in;

    print " laptime time after loading, counting : ", tv_interval($t0), "\n";

    my $sortex = Sort::External->new();

    open $in, '<', $input_file;
    while ( my $line = <$in> ) {
        chomp($line);
        my ($key, $num) = split /\s+/, $line;

        # encode for GRT
        my $sortkey = (~ sprintf("%04d", $freq{$key}) ) .
                         sprintf("%05d", $key) .
                         sprintf("%04d", $num);

        $sortex->feed( $sortkey );
    }
    close $in;

    print " laptime time after feeding : ", tv_interval($t0), "\n";

    $sortex->finish;
    print " laptime time after finish (sorting?) : ", tv_interval($t0), "\n";

    my $output_file = "sorted_7_$output_postfix";
    open my $out, ">", $output_file;
    while ( defined( $_ = $sortex->fetch ) ) {
        # decode for GRT
        my $key = substr( $_, 4, 5 ) + 0;
        my $num = substr( $_, 9 ) + 0;
        print {$out} $key, "\t", $num, "\n";
    }

    close $out;

    print "method 7 - save [$output_file]\n";
    print " total elapsed time : ", tv_interval($t0), "\n";
}
elsif ( $method == 8 ) {            # Sort::External, GRT, pack;
    print "method 8 - use Sort::External, GRT(pack) [$input_file]\n";
    my $t0 = [ gettimeofday ];

    # GRT 변환을 위해서는 일단 freq 를 알아야 함
    my %freq = ();
    open my $in, '<', $input_file;
    while ( my $line = <$in> ) {
        my $key = (split /\s+/, $line)[0];
        $freq{$key}++;
    }
    close $in;

    print " laptime time after loading, counting : ", tv_interval($t0), "\n";

    my $sortex = Sort::External->new();

    open $in, '<', $input_file;
    while ( my $line = <$in> ) {
        chomp($line);
        my ($key, $num) = split /\s+/, $line;

        # encode for GRT
        my $sortkey = (~ pack('n', $freq{$key}) ) .
                         pack('n', $key) .
                         pack('n', $num);

        $sortex->feed( $sortkey );
    }
    close $in;

    print " laptime time after feeding : ", tv_interval($t0), "\n";

    $sortex->finish;
    print " laptime time after finish (sorting?) : ", tv_interval($t0), "\n";

    my $output_file = "sorted_8_$output_postfix";
    open my $out, ">", $output_file;
    while ( defined( $_ = $sortex->fetch ) ) {
        # decode for GRT
        my ( undef, $key, $num ) = unpack('n3', $_);
        print {$out} $key, "\t", $num, "\n";
    }

    close $out;

    print "method 8 - save [$output_file]\n";
    print " total elapsed time : ", tv_interval($t0), "\n";
}
elsif ( $method == 9 ) {            # Sort::External, GRT;
    my $mem = $ARGV[1] || 8;

    print "method 9 - use Sort::External, GRT(sprintf), Memory Size($mem MB) [$input_file]\n";
    my $t0 = [ gettimeofday ];

    # GRT 변환을 위해서는 일단 freq 를 알아야 함
    my %freq = ();
    open my $in, '<', $input_file;
    while ( my $line = <$in> ) {
        my $key = (split /\s+/, $line)[0];
        $freq{$key}++;
    }
    close $in;

    print " laptime time after loading, counting : ", tv_interval($t0), "\n";

    my $sortex = Sort::External->new( mem_threshold => $mem * (1024**2));

    open $in, '<', $input_file;
    while ( my $line = <$in> ) {
        chomp($line);
        my ($key, $num) = split /\s+/, $line;

        # encode for GRT
        my $sortkey = (~ sprintf("%04d", $freq{$key}) ) .
                         sprintf("%05d", $key) .
                         sprintf("%04d", $num);

        $sortex->feed( $sortkey );
    }
    close $in;

    print " laptime time after feeding : ", tv_interval($t0), "\n";

    $sortex->finish;
    print " laptime time after finish (sorting?) : ", tv_interval($t0), "\n";

    my $output_file = "sorted_9_mem_${mem}MB_$output_postfix";
    open my $out, ">", $output_file;
    while ( defined( $_ = $sortex->fetch ) ) {
        # decode for GRT
        my $key = substr( $_, 4, 5 ) + 0;
        my $num = substr( $_, 9 ) + 0;
        print {$out} $key, "\t", $num, "\n";
    }

    close $out;

    print "method 9 - save [$output_file]\n";
    print " total elapsed time : ", tv_interval($t0), "\n";
}
elsif ( $method == 10 ) {            # Sort::Radix
    print "method 10 - use Sort::External, GRT(pack) [$input_file]\n";
    my $t0 = [ gettimeofday ];

    # GRT 변환을 위해서는 일단 freq 를 알아야 함
    my %freq = ();
    open my $in, '<', $input_file;
    while ( my $line = <$in> ) {
        my $key = (split /\s+/, $line)[0];
        $freq{$key}++;
    }
    close $in;

    print " laptime time after loading, counting : ", tv_interval($t0), "\n";

    my @array = ();

    open $in, '<', $input_file;
    while ( my $line = <$in> ) {
        chomp($line);
        my ($key, $num) = split /\s+/, $line;

        # encode for GRT
        my $sortkey = (~ pack('n', $freq{$key}) ) .
                         pack('n', $key) .
                         pack('n', $num);

        push @array, $sortkey;
    }
    close $in;

    print " laptime time after creating array : ", tv_interval($t0), "\n";

    radix_sort(\@array);
    print " laptime time after sorting : ", tv_interval($t0), "\n";

    my $output_file = "sorted_10_$output_postfix";
    open my $out, ">", $output_file;
    foreach ( @array ) {
        # decode for GRT
        my ( undef, $key, $num ) = unpack('n3', $_);
        print {$out} $key, "\t", $num, "\n";
    }

    close $out;

    print "method 10 - save [$output_file]\n";
    print " total elapsed time : ", tv_interval($t0), "\n";
}

