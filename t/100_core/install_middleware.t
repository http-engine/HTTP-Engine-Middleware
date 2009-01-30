use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 3;

use HTTP::Engine::Middleware;

my $mw = HTTP::Engine::Middleware->new;
$mw->install(
    'Foo::Middleware::Bar' => { key => 'value' },
    'Foo::Middleware::Baz'
);

is $mw->middlewares->[0], 'Foo::Middleware::Bar', 'installed middleware is Foo::Middleware::Bar';
is $mw->middlewares->[1], 'Foo::Middleware::Baz', 'installed middleware is Foo::Middleware::Baz';

is $mw->instance_of('Foo::Middleware::Bar')->key, 'value', 'config';
