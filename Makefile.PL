use inc::Module::Install;

{
    no warnings 'redefine';
    *recommends_hack = $Module::Install::VERSION > 0.70 ?
        sub { recommends(@_); $_[0] } :
        \&recommends;
}

name 'HTTP-Engine-Middleware';
all_from 'lib/HTTP/Engine/Middleware.pm';

requires 'HTTP::Engine' => '0.1.3';

features(

# For Developer's

    'ModuleReload' => [
        -default => 0,
        recommends_hack('Module::Reload'),
    ],

    'DebugScreen' => [
        -default => 0,
        recommends_hack('CGI::ExceptionManager'),
        recommends_hack('Scope::Upper'),
    ],

    'DebugRequest' => [
        -default => 0,
        recommends_hack('Text::SimpleTable'),
    ],

# static file maneger ( developer ? )

    'Static' => [
        -default => 0,
        recommends_hack('MIME::Types'),
        recommends_hack('Path::Class'),
        recommends_hack('MouseX::Types::Path::Class'),
    ],

# fill in form

    'FillInForm' => [
        -default => 0,
        recommends_hack('HTML::FillInForm' => '2.00'),
    ],

# encoding

    'Encode' => [
        -default => 0,
        recommends_hack('Data::Visitor::Encode'),
    ],

# For Japanese Mobile

    'MobileAttribute' => [
        -default => 0,
        recommends_hack('HTTP::MobileAttribute'),
    ],

    'DoCoMoGUID' => [
        -default => 0,
        recommends_hack('HTML::StickyQuery'),
    ],
);

tests 't/*.t t/*/*.t t/*/*/*.t';
author_tests 'xt';
build_requires 'Test::More';
build_requires 'YAML';
use_test_base;
auto_include;
WriteAll;
