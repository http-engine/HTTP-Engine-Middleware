use strict;
use warnings;
use lib '.';
use Test::Base;
plan tests => 3*blocks;

eval q{ use HTTP::Engine middlewares => ['+HTTP::Engine::Middleware::Encode'] };
plan skip_all => "HTTP::Engine is not installed." if $@;

use Encode;
use utf8;
use URI;

run {
    my $block = shift;

    my $uri = URI->new('http://localhost/');
    $uri->query_form( foo => encode($block->encoding, $block->param) );

    my $response = HTTP::Engine->new(
        interface => {
            module => 'Test',
            request_handler => sub {
                my $c = shift;
                ok utf8::is_utf8($c->req->param('foo'));
                is $c->req->param('foo'), $block->param, $block->name;
                $c->res->body('OK!');
            },
        },
    )->run(HTTP::Request->new( GET => $uri->as_string, ['Content-Type' => $block->content_type] ));

    is $response->content, 'OK!';
};

__END__
=== utf-8 encoding
--- encoding: utf-8
--- content_type
text/plain; charset=utf-8
--- param
ﾂ､ﾂ｢ﾂ､ﾂ､ﾂ､ﾂｦﾂ､ﾂｨﾂ､ﾂｪ
=== ascii only
--- encoding: utf-8
--- content_type
text/plain;
--- param
abcdef
=== euc encoding
--- encoding: euc-jp
--- content_type
text/plain; charset=euc-jp
--- param
ﾂ､ﾂ｢ﾂ､ﾂ､ﾂ､ﾂｦﾂ､ﾂｨﾂ､ﾂｪ
