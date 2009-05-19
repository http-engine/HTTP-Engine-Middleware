use strict;
use warnings;
use Test::Base;
use IO::Scalar;

eval q{ use Data::Visitor::Encode };
plan skip_all => "Data::Visitor::Encode is not installed" if $@;

plan tests => 5 * blocks;

use HTTP::Engine;
use HTTP::Engine::Middleware;
use HTTP::Request;

use Encode;

filters { params => [qw/eval/], config => [qw/eval/] };

run {
    my $block = shift;
    my $config = $block->config || +{};
    my $mw = HTTP::Engine::Middleware->new;
    $mw->install( 'HTTP::Engine::Middleware::Encode' => $config );

    my $request = HTTP::Request->new(
        GET => $block->uri,
        [ 'Content-Type' => $block->content_type ]
    );

    my $do_test = sub {
        my $req = shift;
        ok Encode::is_utf8( $req->params->{'nite'} ), 'params is utf8';
        is_deeply $req->params, $block->params, $block->name . ' params';
        my $res = HTTP::Engine::Response->new( body => decode('utf8', 'OKです!') );
        $res->content_type( $block->send_content_type ) if $block->send_content_type;
        $res;
    };

    my $response = HTTP::Engine->new(
        interface => {
            module          => 'Test',
            request_handler => $mw->handler($do_test),
        },
    )->run($request);

    my $content = $response->content;
    ok !Encode::is_utf8( $content ), 'not utf8';
    $content = encode('utf8', decode($config->{encode}, $content)) if $config->{encode};
    is $content, 'OKです!', 'content';

    tie *STDERR, 'IO::Scalar', \my $err;
    $response = HTTP::Engine->new(
        interface => {
            module          => 'Test',
            request_handler => $mw->handler(sub {}),
        },
    )->run( HTTP::Request->new( GET => '/' ) );
    untie *STDERR;
    like $err, qr/You should return instance of HTTP::Engine::Response./, 'You should return instance of HTTP::Engine::Response.';
};

__END__

=== default
--- uri: http://localhost/?nite=%E3%81%97%E3%83%BC%E3%81%88%E3%81%99%E3%81%88%E3%81%99
--- content_type : text/plain
--- params: { nite => "\x{3057}\x{30fc}\x{3048}\x{3059}\x{3048}\x{3059}" }
--- response_content_type: text/html; charset=utf-8

=== header utf-8
--- uri: http://localhost/?nite=%E3%81%97%E3%83%BC%E3%81%88%E3%81%99%E3%81%88%E3%81%99
--- content_type : text/plain; charset=utf-8
--- params: { nite => "\x{3057}\x{30fc}\x{3048}\x{3059}\x{3048}\x{3059}" }
--- config: { detected_decode_by_header => 1 }
--- response_content_type: text/html; charset=utf-8

=== header ascii
--- uri: http://localhost/?nite=nipotan
--- content_type: text/plain; charset=ascii
--- params : {nite => 'nipotan'}
--- config: { detected_decode_by_header => 1 }
--- response_content_type: text/html; charset=utf-8

=== header euc-jp
--- uri: http://localhost/?nite=%A4%B7%A1%BC%A4%A8%A4%B9%A4%A8%A4%B9
--- content_type: text/plain; charset=euc-jp
--- params: { nite => "\x{3057}\x{30fc}\x{3048}\x{3059}\x{3048}\x{3059}" }
--- config: { detected_decode_by_header => 1 }
--- response_content_type: text/html; charset=utf-8

=== config utf-8
--- uri: http://localhost/?nite=%E3%81%97%E3%83%BC%E3%81%88%E3%81%99%E3%81%88%E3%81%99
--- content_type : text/plain
--- params: { nite => "\x{3057}\x{30fc}\x{3048}\x{3059}\x{3048}\x{3059}" }
--- config: { decode => 'utf-8' }
--- response_content_type: text/html; charset=utf-8

=== config ascii
--- uri: http://localhost/?nite=nipotan
--- content_type: text/plain
--- params : {nite => 'nipotan'}
--- config: { decode => 'ascii' }
--- response_content_type: text/html; charset=utf-8

=== config euc-jp
--- uri: http://localhost/?nite=%A4%B7%A1%BC%A4%A8%A4%B9%A4%A8%A4%B9
--- content_type: text/plain
--- params: { nite => "\x{3057}\x{30fc}\x{3048}\x{3059}\x{3048}\x{3059}" }
--- config: { decode => 'euc-jp' }
--- response_content_type: text/html; charset=utf-8

=== encode utf-8
--- uri: http://localhost/?nite=%E3%81%97%E3%83%BC%E3%81%88%E3%81%99%E3%81%88%E3%81%99
--- content_type : text/plain
--- params: { nite => "\x{3057}\x{30fc}\x{3048}\x{3059}\x{3048}\x{3059}" }
--- config: { encode => 'utf-8' }
--- response_content_type: text/html; charset=utf-8

=== encode ascii
--- uri: http://localhost/?nite=nipotan
--- content_type: text/plain
--- params : {nite => 'nipotan'}
--- config: { encode => 'cp932', content_type_charset => 'Shift-JIS' }
--- response_content_type: text/html; charset=Shift-JIS

=== encode euc-jp
--- uri: http://localhost/?nite=%E3%81%97%E3%83%BC%E3%81%88%E3%81%99%E3%81%88%E3%81%99
--- content_type : text/plain
--- params: { nite => "\x{3057}\x{30fc}\x{3048}\x{3059}\x{3048}\x{3059}" }
--- config: { encode => 'euc-jp' }
--- response_content_type: text/html; charset=euc-jp

=== text plain
--- uri: http://localhost/?nite=nipotan
--- content_type: text/plain; charset=ascii
--- params : {nite => 'nipotan'}
--- send_content_type: text/plain
--- response_content_type: text/plain; charset=utf-8

=== text plain charset overwrite
--- uri: http://localhost/?nite=nipotan
--- content_type: text/plain; charset=ascii
--- params : {nite => 'nipotan'}
--- send_content_type: text/plain; charset=ascii
--- response_content_type: text/plain; charset=utf-8

=== application/x-http-engine
--- uri: http://localhost/?nite=nipotan
--- content_type: text/plain; charset=ascii
--- params : {nite => 'nipotan'}
--- send_content_type: application/x-http-engine
--- response_content_type: application/x-http-engine
