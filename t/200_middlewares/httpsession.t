use strict;
use warnings;
use Test::More;
use IO::Scalar;

eval q{ use HTTP::Session; };
plan skip_all => "HTTP::Session is not installed" if $@;
eval q{ use HTTP::Session::State::URI; };
plan skip_all => "HTTP::Session::State::URI is not loaded: $@" if $@;
eval q( { package foo; use Any::Moose;use Any::Moose 'X::Types' } );
plan skip_all => "Mo[ou]seX::Types is not installed" if $@;

plan tests => 10;

use HTTP::Engine;
use HTTP::Engine::Middleware;
use HTTP::Engine::Response;
use HTTP::Request;
use HTTP::Request::Common;

sub run_engine (&) {
    my $code = shift;

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
            request_handler => $mw->handler( $code ),
        },
    )->run($request);

    tie *STDERR, 'IO::Scalar', \my $err;
    my $response = HTTP::Engine->new(
        interface => {
            module          => 'Test',
            request_handler => $mw->handler(sub {}),
        },
    )->run( HTTP::Request->new( GET => '/' ) );
    untie *STDERR;
    like $err, qr/You should return instance of HTTP::Engine::Response./, 'You should return instance of HTTP::Engine::Response.';

    return $res;
}

MAIN: {

    my $res = run_engine {
        my $req = shift;
        $req->session;
        HTTP::Engine::Response->new( body => '<a href="/tmp/">foo</a>' );
    };

    my $out = $res->content;
    is $res->code, '200', 'response code';
    like $out, qr{<a href="/tmp/\?foo_sid=.{32}">foo</a>}, 'response content';


    $res = run_engine {
        my $req = shift;
        HTTP::Engine::Response->new( body => '<a href="/tmp/">foo</a>' );
    };

    $out = $res->content;
    is $res->code, '200', 'response code';
    like $out, qr{<a href="/tmp/">foo</a>}, 'response content';
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
