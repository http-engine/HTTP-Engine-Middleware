package Middleware::Zero;
use HTTP::Engine::Middleware;

before_handle {
    ::is($::i++, 1, 'Zero before');
    $_[2];
};
after_handle {
    ::is $::i++, 5, 'Zero after';
    $_[3];
};
__MIDDLEWARE__
