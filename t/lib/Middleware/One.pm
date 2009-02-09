package Middleware::One;
use HTTP::Engine::Middleware;

before_handle {
    ::is $::i++, 2, 'One before';
    $_[2];
};
after_handle {
    ::is $::i++, 4, 'One after';
    $_[3];
};
__MIDDLEWARE__


