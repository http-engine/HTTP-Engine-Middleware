use strict;
use warnings;
use Test::Base;
use IO::Scalar;

eval q{ use HTML::FillInForm 2.00 };
plan skip_all => "HTML::FillInForm 2.00 required is FillInForm" if $@;

plan tests => 2 * blocks;

use HTTP::Engine;
use HTTP::Engine::Middleware;
use HTTP::Request;

filters {
    middleware_args => [qw/eval/],
};

run {
    my $block = shift;

    my $mw = HTTP::Engine::Middleware->new;
    $mw->install( 'HTTP::Engine::Middleware::FillInForm', ($block->middleware_args || {}) );
    my $method = $block->method || 'POST';
    my $req = HTTP::Request->new( $method => 'http://localhost/', [], 'foo=bar');
    $req->content_length(length $req->content);
    $req->content_type('application/x-www-form-urlencoded');
    my $res = HTTP::Engine->new(
        interface => {
            module          => 'Test',
            request_handler => $mw->handler(
                sub {
                    my $res = HTTP::Engine::Response->new(
                        body => $block->input,
                    );
                    eval $block->exec;
                    die $@ if $@;
                    $res;
                }
            ),
        },
    )->run($req);
    is $res->content, $block->expected;

    tie *STDERR, 'IO::Scalar', \my $err;
    my $response = HTTP::Engine->new(
        interface => {
            module          => 'Test',
            request_handler => $mw->handler(sub {}),
        },
    )->run( HTTP::Request->new( GET => '/' ) );
    untie *STDERR;
    like $err, qr/You should return instance of HTTP::Engine::Response./, 'You should return instance of HTTP::Engine::Response.';
};

__END__

===
--- input: <form><input type="text" name="foo" /></form>
--- exec: $res->fillin_form()
--- expected: <form><input value="bar" name="foo" type="text" /></form>

===
--- input: <form><input type="text" name="foo" /></form>
--- exec: $res->fillin_form({'foo' => 'woz'})
--- expected: <form><input value="woz" name="foo" type="text" /></form>

===
--- middleware_args: {autorun_on_post => 1}
--- method: POST
--- input: <form><input type="text" name="foo" /></form>
--- exec: ''
--- expected: <form><input value="bar" name="foo" type="text" /></form>

===
--- middleware_args: {autorun_on_post => 1}
--- method: GET
--- input: <form><input type="text" name="foo" /></form>
--- exec: ''
--- expected: <form><input type="text" name="foo" /></form>

