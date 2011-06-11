use 5.008_000;
use ExtUtils::MakeMaker;
WriteMakefile(
  ABSTRACT_FROM => 'lib/Devel/ContinuousProfiler.pm',
  AUTHOR => 'Josh Jore <jjore@cpan.org>',
  LICENSE => 'perl',
  NAME => 'Devel::ContinuousProfiler',
  VERSION_FROM => 'lib/Devel/ContinuousProfiler.pm',
  OPTIMIZE => '-g',
);
