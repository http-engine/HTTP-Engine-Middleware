use strict;
use warnings;
use Test::More;

if (Any::Moose::is_moose_loaded()) {
    plan skip_all => 'this test case is doesnt work by use to Class::MOP::is_class_loaded method (by XS code)';
}

plan tests => 22;

use HTTP::Engine;
use HTTP::Engine::Middleware;
use HTTP::Engine::Response;
use HTTP::Request;

{
    package t::Status::Test;
    use Any::Moose;
    extends 'HTTP::Engine::Middleware::Status::Base';

    has '+name' => (
        default => 'Test',
    );

    has 'test' => (
        is => 'rw',
    );

    sub render {
        my $self = shift;
        $self->render_header . '<h3>' . $self->test . '</h3>';
    }
}

sub run_tests {
    my($engine, $uri, @likes) = @_;

    my $res = $engine->run(HTTP::Request->new(
        GET => $uri
    ));

    is $res->code, '200', "status code of $uri";
    if (@likes) {
        for my $re (@likes) {
            like $res->content, $re, "status body: $re";
        }
    } else {
        is $res->content, 'dynamic', 'not status body';
    }
}


do {
    my $mw = HTTP::Engine::Middleware->new;
    $mw->install(
        'HTTP::Engine::Middleware::Status',
    );

    my $engine = HTTP::Engine->new(
        interface => {
            module          => 'Test',
            request_handler => $mw->handler( sub { HTTP::Engine::Response->new( body => 'dynamic' ) } ),
        },
    );

    run_tests($engine, 'http://example.com/');
    run_tests($engine, 'http://example.com/httpengine-status', qr{<h1>HTTP::Engine Status</h1>});
    run_tests($engine, 'http://example.com/httpengine');
};

do {
    my $mw = HTTP::Engine::Middleware->new;
    $mw->install(
        'HTTP::Engine::Middleware::Status' => {
            plugins => [
                {
                    module => '+t::Status::Test',
                    config => {
                        test => 'test',
                    },
                },
            ],
        },
    );

    my $engine = HTTP::Engine->new(
        interface => {
            module          => 'Test',
            request_handler => $mw->handler( sub { HTTP::Engine::Response->new( body => 'dynamic' ) } ),
        },
    );

    run_tests($engine, 'http://example.com/');
    run_tests($engine, 'http://example.com/httpengine-status', qr{<h1>HTTP::Engine Status</h1>}, qr{<h2>Test</h2>}, qr{<h3>test</h3>});
    run_tests($engine, 'http://example.com/httpengine');
};


do {
    my $mw = HTTP::Engine::Middleware->new;
    $mw->install(
        'HTTP::Engine::Middleware::Status' => {
            launch_at => '/stat',
            plugins => [
                t::Status::Test->new( test => 'object' ),
            ],
        },
    );

    my $engine = HTTP::Engine->new(
        interface => {
            module          => 'Test',
            request_handler => $mw->handler( sub { HTTP::Engine::Response->new( body => 'dynamic' ) } ),
        },
    );

    run_tests($engine, 'http://example.com/');
    run_tests($engine, 'http://example.com/stat', qr{<h1>HTTP::Engine Status</h1>}, qr{<h2>Test</h2>}, qr{<h3>object</h3>});
    run_tests($engine, 'http://example.com/httpengine-status');
};
