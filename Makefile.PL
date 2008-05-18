use inc::Module::Install;

{
    no warnings 'redefine';
    *recommends_hack = $Module::Install::VERSION > 0.70 ?
        sub { recommends(@_); $_[0] } :
        \&recommends;
}

name 'HTTP-Engine-Middleware';
all_from 'lib/HTTP/Engine/Middleware.pm';

requires 'HTTP::Engine' => '0.0.6';

features(
    'ModuleReload' => [
        -default => 0,
        recommends_hack('Module::Reload'),
    ],

    'DebugScreen' => [
        -default => 0,
        recommends_hack('Carp::Always'),
    ],

    'DoCoMoGUID' => [
        -default => 0,
        recommends_hack('HTML::StickyQuery::DoCoMoGUID'),
    ],
);

tests 't/*.t t/*/*.t t/*/*/*.t';
build_requires 'Test::More';
build_requires 'YAML';
use_test_base;
auto_include;
WriteAll;
