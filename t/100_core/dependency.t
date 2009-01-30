use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 7;

use HTTP::Engine;
use HTTP::Engine::Response;
use HTTP::Engine::Middleware;
use HTTP::Request;

eval {
    my $mw = HTTP::Engine::Middleware->new({ method_class => 'main' });
    $mw->install(
        'Foo::Middleware::Inner',
        'Foo::Middleware::Middle',
    );
    my $handler = $mw->handler( sub {} );
};
like $@, qr/'Foo::Middleware::Middle' need to 'Foo::Middleware::Outer'/, 'dependency error';

my $mw = HTTP::Engine::Middleware->new({ method_class => 'main' });
$mw->install(
    'Foo::Middleware::Middle',
    'Foo::Middleware::Inner',
    'Foo::Middleware::Outer'
);

is $mw->middlewares->[0], 'Foo::Middleware::Outer', 'outer';
is $mw->middlewares->[1], 'Foo::Middleware::Middle', 'middle';
is $mw->middlewares->[2], 'Foo::Middleware::Inner', 'inner';

my $res = HTTP::Engine->new(
    interface => {
        module => 'Test',
        request_handler => $mw->handler( \&handler ),
    }
)->run( HTTP::Request->new( GET => 'http://localhost/?param=yappo') );
is $res->content, 'from inner (ok)';

sub handler {
    my $req = shift;
    is(main->before, 'yappo', 'before_method');
    is $req->header('X-Middle'), 'yappo', 'middle set data';
    HTTP::Engine::Response->new( body => 'ng' );
}
