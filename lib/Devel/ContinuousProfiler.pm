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
our $VERSION = '0.06';

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

        ++ $DATA{join ',', @stack};

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

    my $report = report_string();

    if ($OUTPUT_HANDLE && $OUTPUT_SEEKABLE) {
        $OUTPUT_SEEKABLE = seek $OUTPUT_HANDLE, 0, 0;
        truncate $OUTPUT_HANDLE, 0;
        syswrite $OUTPUT_HANDLE, $report;
    } elsif ( $OUTPUT_HANDLE ) {
        syswrite $OUTPUT_HANDLE, $report;
    }

    return;
}

sub report_string {
    my $max_length = 0;
    for ( values %DATA ) {
        $max_length = length if length() > $max_length;
    }

    my $format = "=$$= %${max_length}d %s\n";
    return
        join '',
            "=$$= " . __PACKAGE__ . " profiling stats.\n",
            map { sprintf $format, $DATA{$_}, $_ }
            sort { $DATA{$b} <=> $DATA{$a} || $a cmp $b }
            keys %DATA;
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

-head1 NAME

Devel::ContinuousProfiler - Ultra cheap profiling for use in production

=head1 SYNOPSIS

    use Devel::ContinuousProfiler;
    ...
    # Automatic, periodic printing of profiling stats:

=head1 DESCRIPTION

This module automatically writes profiling snapshots to a file,
STDERR, or other destinations. By default, this writes to STDERR.



=head1 INTERNAL API

=over

=item count_down

=item is_inside_logger

=item log_size

=item take_snapshot

=item report

=item report_string

=back
