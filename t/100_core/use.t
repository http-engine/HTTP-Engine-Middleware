use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 3;

use_ok 'HTTP::Engine::Middleware';

eval { before_handle(sub {}) };
ok($@, 'before_handle is not export');

eval { after_handle( sub {} ) };
ok($@, 'after_handle is not export');
