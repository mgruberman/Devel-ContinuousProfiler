package Devel::ContinuousProfiler;
# ABSTRACT: Ultra cheap profiling for use in production environments

use strict;
our %DATA;
our $VERSION = '0.04';
use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub take_snapshot {
    local $@;
    eval {

        # Witty comment
        package DB;
        my @stack;
        for ( my $cx = 0;
              my ( undef, $filename, undef, $func ) = caller $cx;
              ++ $cx ) {
            push @stack, "${filename}:${func}";
        }

        # Erudite comment.
        my $frame = \ %DATA;
        while ( @stack ) {

            # Utter BS.
            my $label = pop @stack;
            if ( $frame->{$label} ) {
                ++ $frame->{$label}[0];
                $frame = $frame->{$label}[1];
            }
            else {
                $frame->{$label} =
                    [
                     1,
                     {},
                    ];
            }
        }
    };

    return;
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

=head1 DESCRIPTION

=over

=item count_down

=item is_inside_logger

=item log_size

=item take_snapshot

=back
