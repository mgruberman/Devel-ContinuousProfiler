use Test::More tests => 3;
require File::Temp;

my $file = File::Temp::tmpnam();
END { unlink $file };

my @cmd = (
    $^X,
        '-Mblib',
        '-MDevel::ContinuousProfiler',
        '-MData::Dumper',
        '-e' => '1 for 1..1_000_000;open(STDOUT,">","' . $file . '")||die$!;print Dumper(\%Devel::ContinuousProfiler::DATA)'
);
system @cmd;
is( $?, 0, "@cmd" );

SKIP: {
    skip "Can't open $file: $!", 2 unless open my $fh, '<', $file;

    local $/ = undef;
    my $data = readline $fh;
    unlink $file;
    diag( $data );
    ok( $data, "Got something" );
    ok( eval($data), "It compiles );
}
