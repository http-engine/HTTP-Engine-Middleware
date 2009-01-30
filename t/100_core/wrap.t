use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 2;

use HTTP::Engine;
use HTTP::Engine::Response;
use HTTP::Engine::Middleware;
use HTTP::Request;

my $mw = HTTP::Engine::Middleware->new;
$mw->install(
    'Foo::Middleware::Bar' => { key => 'yappo' },
);

my $res = HTTP::Engine->new(
    interface => {
        module => 'Test',
        request_handler => $mw->handler( \&handler ),
    }
)->run( HTTP::Request->new( GET => 'http://localhost/') );
is $res->content, 'header=yappo, key=yappo', 'after_handle';

sub handler {
    my $req = shift;
    is $req->header('X-Key'), 'yappo', 'before_handle';
    HTTP::Engine::Response->new( body => 'header=' . $req->header('X-Key') );
}
