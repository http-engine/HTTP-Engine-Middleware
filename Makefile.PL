use inc::Module::Install;

{
    no warnings 'redefine';
    *recommends_hack = $Module::Install::VERSION > 0.70 ?
        sub { recommends(@_); $_[0] } :
        \&recommends;
}

name 'HTTP-Engine-Middleware';
all_from 'lib/HTTP/Engine/Middleware.pm';

requires 'HTTP::Engine' => '0.1.2';

features(
    'ModuleReload' => [
        -default => 0,
        recommends_hack('Module::Reload'),
    ],

    'DebugScreen' => [
        -default => 0,
        recommends_hack('CGI::ExceptionManager'),
        recommends_hack('Scope::Upper'),
    ],

    'Static' => [
        -default => 0,
        recommends_hack('MIME::Types'),
        recommends_hack('Path::Class'),
    ],

    'FillInForm' => [
        -default => 0,
        recommends_hack('HTML::FillInForm' => '2.00'),
    ],

    'DoCoMoGUID' => [
        -default => 0,
        recommends_hack('HTML::StickyQuery'),
    ],

    'Encode' => [
        -default => 0,
        recommends_hack('Data::Visitor::Encode'),
    ],

    'MobileAttribute' => [
        -default => 0,
        recommends_hack('HTTP::MobileAttribute'),
    ],

    'Unicode' => [
        -default => 0,
        recommends_hack('Data::Visitor::Encode'),
    ],

    'DebugRequest' => [
        -default => 0,
        recommends_hack('Text::SimpleTable'),
    ],
);

tests 't/*.t t/*/*.t t/*/*/*.t';
author_tests 'xt';
build_requires 'Test::More';
build_requires 'YAML';
use_test_base;
auto_include;
WriteAll;
