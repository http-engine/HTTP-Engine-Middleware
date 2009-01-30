package Foo::Middleware::Baz;
use HTTP::Engine::Middleware;

middleware_method 'foo' => sub { 'foo' };

__MIDDLEWARE__
