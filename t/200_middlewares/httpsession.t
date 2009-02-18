use strict;
use warnings;
use Test::More;

eval q{ use HTTP::Session; use MouseX::Types; };
plan skip_all => "HTTP::Session is not installed" if $@;

plan tests => 6;

use HTTP::Engine;
use HTTP::Engine::Middleware;
use HTTP::Engine::Response;
use HTTP::Request;
use HTTP::Request::Common;

MAIN: {
    my $mw = HTTP::Engine::Middleware->new({method_class => 'HTTP::Engine::Request'});
    $mw->install(
        'HTTP::Engine::Middleware::HTTPSession' => {
            state => {
                class => 'URI',
                args  => {
                    session_id_name => 'foo_sid',
                },
            },
            store => {
                class => 'Test',
                args => { },
            },
        }
    );

    my $request = HTTP::Request->new( GET => 'http://localhost/?getparam=1', );
    my $res = HTTP::Engine->new(
        interface => {
            module          => 'Test',
            request_handler => $mw->handler(
                sub { my $req = shift; $req->session; HTTP::Engine::Response->new( body => '<a href="/tmp/">foo</a>' ) }
            ),
        },
    )->run($request);
    my $out = $res->content;

    is $res->code, '200', 'response code';
    like $out, qr{<a href="/tmp/\?foo_sid=.{32}">foo</a>}, 'response content';
};

COERCE: {
    my $s = HTTP::Engine::Middleware::HTTPSession->new(
        state => HTTP::Session::State::URI->new(
            session_id_name => 'foo_sid',
        ),
        store => HTTP::Session::Store::Test->new(),
    );
    is ref($s->state), 'CODE';
    is ref($s->state->()), 'HTTP::Session::State::URI';
    is ref($s->store), 'CODE';
    is ref($s->store->()), 'HTTP::Session::Store::Test';
};
