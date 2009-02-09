package HTTP::Engine::Middleware::MobileAttribute;
use HTTP::Engine::Middleware;

middleware_method 'mobile_attribute' => sub {
    my $self = shift;
    $self->{mobile_attribute} ||= HTTP::MobileAttribute->new( $self->headers );
};

__MIDDLEWARE__

__END__

=head1 NAME

HTTP::Engine::Middleware::MobileAttribute - documentation is TODO

=cut
