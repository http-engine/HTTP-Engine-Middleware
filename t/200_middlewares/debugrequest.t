use strict;
use warnings;
use Test::More;

eval q{ use HTTP::Request::Common };
plan skip_all => "HTTP::Request::Common is not installed" if $@;
eval q{ use Text::SimpleTable };
plan skip_all => "Text::SimpleTable is not installed" if $@;

plan tests => 9;

use HTTP::Engine;
use HTTP::Engine::Middleware;
use HTTP::Engine::Response;
use HTTP::Request;

# TODO: added TEST

GET_PARAMETERS: {
    my $mw = HTTP::Engine::Middleware->new;
    $mw->install(
        'HTTP::Engine::Middleware::DebugRequest',
        {   logger => sub {
                my ( $message ) = @_;
                ::like $message, qr/getparam/, 'match get param'
                    unless $message =~ m/Path/;
                }
        }
    );

    my $request
        = HTTP::Request->new( GET => 'http://localhost/?getparam=1', );
    my $res = HTTP::Engine->new(
        interface => {
            module          => 'Test',
            request_handler => $mw->handler(
                sub { HTTP::Engine::Response->new( body => 'ok' ) }
            ),
        },
    )->run($request);
    my $out = $res->content;

    is $res->code, '200', 'response code';
    is $out, 'ok', 'response content';
}

POST_PARAMETERS: {
    my $mw = HTTP::Engine::Middleware->new;
    $mw->install(
        'HTTP::Engine::Middleware::DebugRequest',
        {   logger => sub {
                my ( $message ) = @_;
                ::like $message, qr/postparam/, 'match post param'
                    unless $message =~ m/Path/;
            },
        }
    );
    my $request = HTTP::Request::Common::POST( 'http://localhost/',
        [ postparam => 1 ] );
    my $res = HTTP::Engine->new(
        interface => {
            module          => 'Test',
            request_handler => $mw->handler(
                sub { HTTP::Engine::Response->new( body => 'ok' ) }
            ),
        },
    )->run($request);
    my $out = $res->content;

    is $res->code, '200', 'response code';
    is $out, 'ok', 'response content';
}

NO_PARAMETERS: {
    my $mw = HTTP::Engine::Middleware->new;
    $mw->install(
        'HTTP::Engine::Middleware::DebugRequest',
        {   logger => sub {
                my ( $message ) = @_;
                ::like $message, qr/GET/, 'GET request'
                    unless $message =~ m/Parameter/;
            },
        }
    );
    my $res = HTTP::Engine->new(
        interface => {
            module          => 'Test',
            request_handler => $mw->handler(
                sub { HTTP::Engine::Response->new( body => 'ok' ) }
            ),
        },
    )->run( HTTP::Request->new( GET => 'http://localhost/' ) );
    my $out = $res->content;

    is $res->code, '200', 'response code';
    is $out, 'ok', 'response content';
}
