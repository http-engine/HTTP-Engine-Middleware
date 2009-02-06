package Foo::Middleware::Baz;
use HTTP::Engine::Middleware;

middleware_method 'foo' => sub { 'foo' };
middleware_method 'HTTP::Engine::Request::darts' => sub { 'darts' };

__MIDDLEWARE__
