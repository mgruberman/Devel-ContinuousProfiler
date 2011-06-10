use ExtUtils::MakeMaker;
use 5.010_000;
WriteMakefile(
  ABSTRACT_FROM => 'lib/Devel/ContinuousProfiler.pm',
  AUTHOR => 'Josh Jore <jjore@cpan.org>',
  LICENSE => 'perl',
  NAME => 'Devel::ContinuousProfiler',
  VERSION_FROM => 'lib/Devel/ContinuousProfiler.pm',
  OPTIMIZE => '-g',
);
