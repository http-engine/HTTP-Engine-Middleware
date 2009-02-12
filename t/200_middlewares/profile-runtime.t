use strict;
use warnings;
use Test::More;

eval q{ use Time::HiRes };
plan skip_all => "Time::HiRes is not installed: $@" if $@;

plan tests => 6;

use HTTP::Engine;
use HTTP::Engine::Middleware;
use HTTP::Engine::Response;
use HTTP::Request;

my $mw = HTTP::Engine::Middleware->new;
$mw->install( 'HTTP::Engine::Middleware::Profile',{
    logger  => sub {
        my $re = qr/Request handling execution time: (.+) secs/;
        ::is  $_[0], 'debug', 'log level';
        ::like $_[1], $re, 'log msg';
        $_[1] =~ $re;
        ::ok looks_like_number($1), 'time is number';
    },
    config  => +{
        send_header => 1,
        log_level   => 'debug',
    },
});
my $res = HTTP::Engine->new(
    interface => {
        module          => 'Test',
        request_handler => $mw->handler(
            sub { HTTP::Engine::Response->new( body => 'ok' ) }
        ),
    },
)->run( HTTP::Request->new( GET => 'http://localhost/') );
my $out = $res->content;

is $res->code, '200', 'response code';
is $out, 'ok', 'response content';
like $res->header('X-Runtime'), qr/^\d+\.\d+$/, 'X-Runtime header';


# copied from Scalar::Util
sub looks_like_number {
  local $_ = shift;

  # checks from perlfaq4
  return 0 if !defined($_) or ref($_);
  return 1 if (/^[+-]?\d+$/); # is a +/- integer
  return 1 if (/^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/); # a C float
  return 1 if ($] >= 5.008 and /^(Inf(inity)?|NaN)$/i) or ($] >= 5.006001 and /^Inf$/i);

  0;
}
