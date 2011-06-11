package Devel::ContinuousProfiler;
# ABSTRACT: Ultra cheap profiling for use in production environments

use strict;
use XSLoader;
use constant _COUNT  => 0;
use constant _DEEPER => 1;

our %DATA;
our $LAST_TIME_REPORT = 0;
our $OUTPUT_HANDLE;
our $OUTPUT_SEEKABLE;
our $VERSION = '0.07';

XSLoader::load(__PACKAGE__, $VERSION);

if ($ENV{PROFILER}) {
    my %args = map { split '=', $_, 2 } split ',', $ENV{PROFILER};
    if ($args{file}) {
        open $OUTPUT_HANDLE, '>', $args{file};
        $OUTPUT_SEEKABLE = 1;
    }
}
$OUTPUT_HANDLE ||= \ *STDERR;

END { report() }

sub take_snapshot {
    local $@;
    eval {

        # Witty comment
        package DB;
        my @stack;
        for ( my $cx = 0;
              my ( undef, undef, undef, $func ) = caller $cx;
              ++ $cx ) {
            unshift @stack, $func;
        }

        my $t = time;
        my $s = join ',', @stack;
        if (my $h = $DATA{$s}) {
            ++ $h->[0];
            $h->[1] = $t;
        }
        else {
            $DATA{$s} = [
                1,
                $t,
                $t,
            ];
        }

        report();
    };

    return;
}

#sub _take_tree_snapshot {
#    # Erudite comment.
#    my $frame = \ %TREE_DATA;
#    for ( my $i = 0;
#          $i < $#{$_[0]} / 2;
#          $i += 2 ) {
#
#        # "filename:function"
#        my $label =
#            $_[0][$i]
#            . ':'
#            . $_[0][$i+1];
#
#        # Utter BS.
#        if ( my $f = $frame->{$label} ) {
#            ++ $f->[_COUNT];
#            $frame = $f->[_DEEPER];
#        }
#        else {
#            $frame->{$label} =
#                [
#                 1,  # _COUNT
#                 {}, # _DEEPER
#                ];
#        }
#    }
#
#    return;
#}

#sub _take_basic_snapshot {
#    my @frames;
#    # Irony.
#    for ( my $i = 0;
#          $i < $#{$_[0]} / 2;
#          $i += 2 ) {
#        push @frames, "$_[0][$i]:$_[0][$i+1]";
#    }
#    ++$BASIC_DATA{join ',', @frames};
#
#    return;
#}

sub report {
    # At most once per second.
    return if $LAST_TIME_REPORT == time;
    $LAST_TIME_REPORT = time;

    my $report = report_strings();

    if ($OUTPUT_HANDLE && $OUTPUT_SEEKABLE) {
        $OUTPUT_SEEKABLE = seek $OUTPUT_HANDLE, 0, 0;
        truncate $OUTPUT_HANDLE, 0;
        syswrite $OUTPUT_HANDLE, $_ for @$report;
    } elsif ( $OUTPUT_HANDLE ) {
        syswrite $OUTPUT_HANDLE, $_ for @$report;
    }

    return;
}

sub report_strings {
    my $max_length = 0;
    for ( values %DATA ) {
        $max_length = length $_->[0] if length($_->[0]) > $max_length;
    }

    my $format = "=$$= %${max_length}d %s\n";
    return [
        "=$$= $0 profiling stats.\n",
        map { sprintf $format, $DATA{$_}[0], $_ }
        sort { $DATA{$b}[0] <=> $DATA{$a}[0] || $DATA{$b}[1] <=> $DATA{$a}[1] }
        keys %DATA
    ];
}

'I am an anarchist
An antichrist
An asterix
I am an anorak
An acolyte
An accidental
I am eleven feet
Ok, eight...
Six foot three...
I fought the British and I won
I have a rocket ship
A jetfighter
A paper airplane';

__END__

=head1 NAME

Devel::ContinuousProfiler - Ultra cheap profiling for use in production

=head1 SYNOPSIS

    use Devel::ContinuousProfiler;
    ...
    # Automatic, periodic printing of profiling stats:

=head1 DESCRIPTION

This module automatically takes periodic snapshots of the callstack
and prints reports of the hottest code. The CPU cost of doing the
profiling work is automatically guestimated to be about 1/1024th your
total.

The report format:

  =E<lt>pidE<gt>= E<lt>process nameE<gt> profiling stats.
  =E<lt>pidE<gt>= E<lt>countE<gt> E<lt>frameE<gt>,E<lt>frameE<gt>,E<lt>frameE<gt>,...
  =E<lt>pidE<gt>= E<lt>countE<gt> E<lt>frameE<gt>,E<lt>frameE<gt>,E<lt>frameE<gt>,...
  =E<lt>pidE<gt>= E<lt>countE<gt> E<lt>frameE<gt>,E<lt>frameE<gt>,...
  ...

An example of some output gleaned from a very short script:

  =14365= t/load.t profiling stats.
  =14365= 1 Test::More::pass,Test::Builder::ok,Test::Builder::_unoverload_str,Test::Builder::_unoverload,Test::Builder::_try,(eval),Test::Builder::__ANON__,(eval),(eval),overload::BEGIN,Devel::ContinuousProfiler::take_snapshot,(eval)

=head1 CAVEATS

=over

=item *

This module's public API is under active development and
experimentation.

=item *

CPAN testers is showing segfaults. Not sure what's going on there yet.

=back

=head1 INTERNAL API

I'm only mentioning these 

=over

=item count_down

=item is_inside_logger

=item log_size

=item take_snapshot

=item report

=item report_strings

=back
