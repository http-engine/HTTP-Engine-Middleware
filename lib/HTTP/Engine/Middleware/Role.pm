package HTTP::Engine::Middleware::Role;
use Mouse::Role;

has 'before_handles' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { +[] },
);

has 'after_handles' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { +[] },
);

1;

