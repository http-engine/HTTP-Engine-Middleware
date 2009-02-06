use strict;
use warnings;
use lib '.';
use Test::Base;
eval q{ use Data::Visitor::Encode };
plan skip_all => "Data::Visitor::Encode is not installed" if $@;
eval q{ use HTTP::Request };
plan skip_all => "HTTP::Request is not installed" if $@;
eval q{ use HTTP::Engine };
plan skip_all => "HTTP::Engine is not installed: $@" if $@;

eval q{ use HTTP::Engine::Middleware };

plan tests => 4 * blocks;

use Encode;
use utf8;
use URI;

filters { params => [qw/eval/], };

run {
    my $block = shift;

    my $mw = HTTP::Engine::Middleware->new;
    $mw->install( 'HTTP::Engine::Middleware::Unicode', );

    my $request = HTTP::Request->new(
        GET => $block->uri,
        [ 'Content-Type' => $block->content_type ]
    );

    my $do_test = sub {
        my $req = shift;
        ok utf8::is_utf8( $req->params->{'nite'} ) , 'utf8';
        is_deeply $req->params, $block->params, $block->name;
        HTTP::Engine::Response->new( body => "日本" );
    };

    my $response = HTTP::Engine->new(
        interface => {
            module          => 'Test',
            request_handler => $mw->handler($do_test),
        },
    )->run($request);

    my $content = $response->content;

    ok !utf8::is_utf8( $content ), 'not utf8';
    utf8::decode($content);
    ok utf8::is_utf8($content), 'now its utf8';

};

__END__

=== ascii
--- uri: http://localhost/?nite=nipotan
--- content_type: text/plain;charset=ascii
--- params : {nite => 'nipotan'}

=== utf-8
--- uri: http://localhost/?nite=%E3%81%97%E3%83%BC%E3%81%88%E3%81%99%E3%81%88%E3%81%99
--- content_type : text/plain; charset=utf-8
--- params: { nite => "\x{3057}\x{30fc}\x{3048}\x{3059}\x{3048}\x{3059}" }

