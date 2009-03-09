package HTTP::Engine::Middleware::Status::Base;
use Any::Moose;

has 'name' => (
    is      =>'ro',
    default => 'Default Status Name',
);

sub render {}
sub render_header {
    my $self = shift;
    '<h2>' . $self->name . '</h2>';
}

1;
