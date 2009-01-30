use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 2;

use HTTP::Engine;
use HTTP::Engine::Response;
use HTTP::Engine::Middleware;
use HTTP::Request;

my $mw = HTTP::Engine::Middleware->new({ method_class => 'MethodInject' });
$mw->install(
    'Foo::Middleware::Baz',
);

my $res = HTTP::Engine->new(
    interface => {
        module => 'Test',
        request_handler => $mw->handler( \&handler ),
    }
)->run( HTTP::Request->new( GET => 'http://localhost/') );
is $res->content, 'ok', 'end of request';

sub handler {
    my $req = shift;
    is MethodInject->foo, 'foo', 'inject method';
    HTTP::Engine::Response->new( body => 'ok' );
}

{
    package MethodInject;
}
