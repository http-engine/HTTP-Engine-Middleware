package HTTP::Engine::Middleware::ReverseProxy;
use HTTP::Engine::Middleware;
use Any::Moose '::Util::TypeConstraints';

subtype 'HTTP::Engine::Middleware::ReverseProxy::Regexp'
    => as 'Regexp';
coerce 'HTTP::Engine::Middleware::ReverseProxy::Regexp'
    => from 'Str' => via {
        qr/\A$_[0]\z/;
    };

has 'allowed_remote' => (
    is      => 'rw',
    isa     => 'HTTP::Engine::Middleware::ReverseProxy::Regexp',
    default => '127\.0\.0\.1',
    coerce  => 1,
);


before_handle {
    my ( $c, $self, $req ) = @_;
    return $req unless $req->address =~ $self->allowed_remote;

    my $env = $req->_connection->{env} || {};

    # in apache httpd.conf (RequestHeader set X-Forwarded-HTTPS %{HTTPS}s)
    $env->{HTTPS} = $req->headers->{'x-forwarded-https'}
        if $req->headers->{'x-forwarded-https'};
    $env->{HTTPS} = 'ON' if $req->headers->{'x-forwarded-proto'};    # Pound
    my $secure = 0;
    if ( my $https = $env->{HTTPS} ) {
        $secure = 1 if $https =~ /\AON\z/i;
    }
    $req->secure($secure);
    my $default_port = $req->secure ? 443 : 80;

    # If we are running as a backend server, the user will always appear
    # as 127.0.0.1. Select the most recent upstream IP (last in the list)
    if ( $req->headers->{'x-forwarded-for'} ) {
        my ( $ip, ) = $req->headers->{'x-forwarded-for'} =~ /([^,\s]+)$/;
        $req->address($ip);
    }

    if ( $req->headers->{'x-forwarded-host'} ) {
        my ( $host, ) = $req->headers->{'x-forwarded-host'} =~ /([^,\s]+)$/;
        if ( $host =~ /^(.+):(\d+)$/ ) {
            $host = $1;
            $env->{SERVER_PORT} = $2;
        } elsif ( $req->headers->{'x-forwarded-port'} ) {
            # in apache httpd.conf (RequestHeader set X-Forwarded-Port 8443)
            $env->{SERVER_PORT} = $req->headers->{'x-forwarded-port'};
        } else {
            $env->{SERVER_PORT} = $default_port;
        }
        $env->{HTTP_HOST} = $host;

        $req->headers->header( 'Host' => $env->{HTTP_HOST} );
    } elsif ($req->headers->{'host'}) {
        my $host = $req->headers->{'host'};
        if ($host =~ /^(.+):(\d+)$/ ) {
            $env->{HTTP_HOST}   = $1;
            $env->{SERVER_PORT} = $2;
        } elsif ($host =~ /^(.+)$/ ) {
            $env->{HTTP_HOST}   = $1;
            $env->{SERVER_PORT} = $default_port;
        }
    } else {
        $env->{HTTP_HOST}   = $req->uri->host;
        $env->{SERVER_PORT} = $req->uri->port || $default_port;
    }
    $req->_connection->{env} = $env;

    for my $attr (qw/uri base/) {
        my $scheme = $secure ? 'https' : 'http';
        my $host = $env->{HTTP_HOST} || $env->{SERVER_NAME};
        my $port = $env->{SERVER_PORT} || undef;
        # my $path_info = $env->{PATH_INFO} || '/';

        $req->$attr->scheme($scheme);
        $req->$attr->host($host);
        if (($port || '') eq $default_port) {
            $req->$attr->port(undef);
        } else {
            $req->$attr->port($port);
        }

        # $req->$attr->path($path_info);
        # $req->$attr( $req->$attr->canonical );
    }
    $req;
};

__MIDDLEWARE__

__END__

=head1 NAME

HTTP::Engine::Middleware::ReverseProxy - reverse-proxy support

=head1 SYNOPSIS

    # default proxy server is 127.0.0.1
    my $mw = HTTP::Engine::Middleware->new;
    $mw->install(qw/ HTTP::Engine::Middleware::ReverseProxy /);
    HTTP::Engine->new(
        interface => {
            module => 'YourFavoriteInterfaceHere',
            request_handler => $mw->handler( \&handler ),
        }
    )->run();

    # allowd proxy server is 192.168.0.0/24
    my $mw = HTTP::Engine::Middleware->new;
    $mw->install( 'HTTP::Engine::Middleware::ReverseProxy', { allowed_remote => qr/\A192\.168\.0\.\d+\z/ } );
    # or $mw->install( 'HTTP::Engine::Middleware::ReverseProxy', { allowed_remote => '192\.168\.0\.\d+' } );
    HTTP::Engine->new(
        interface => {
            module => 'YourFavoriteInterfaceHere',
            request_handler => $mw->handler( \&handler ),
        }
    )->run();

=head1 DESCRIPTION

This module resets some HTTP headers, which changed by reverse-proxy.

=head1 AUTHORS

yappo

=cut
