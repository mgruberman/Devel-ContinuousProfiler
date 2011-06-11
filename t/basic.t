use Test::More tests => 2;
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
open my $fh, '<', $file or warn "Can't open $file: $!";
$/ = undef;
my $data = readline $fh;
unlink $file;

diag( $data );
ok( eval $data );
