use strict;
use warnings;
use HTTP::Engine::Middleware;
use HTTP::Request;
use HTTP::Engine;
use Test::Base;

plan skip_all => "HTML::FillInForm is not installed" unless eval "use HTML::FillInForm;1;";
plan tests => 1*blocks;

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

