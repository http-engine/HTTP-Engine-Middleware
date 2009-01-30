package HTTP::Engine::Middleware::ReverseProxy;
use HTTP::Engine::Middleware;

before_handle {
    my ( $c, $self, $req ) = @_;
    my $env = $req->_connection->{env} || {};

    # in apache httpd.conf (RequestHeader set X-Forwarded-HTTPS %{HTTPS}s)
    $env->{HTTPS} = $req->headers->{'x-forwarded-https'}
        if $req->headers->{'x-forwarded-https'};
    $env->{HTTPS} = 'ON' if $req->headers->{'x-forwarded-proto'};    # Pound
    $req->secure(1) if $env->{HTTPS} && uc $env->{HTTPS} eq 'ON';

    # If we are running as a backend server, the user will always appear
    # as 127.0.0.1. Select the most recent upstream IP (last in the list)
    if ( $req->headers->{'x-forwarded-for'} ) {
        my ( $ip, ) = $req->headers->{'x-forwarded-for'} =~ /([^,\s]+)$/;
        $req->address($ip);
    }

    if ( $req->headers->{'x-forwarded-host'} ) {
        my $host = $req->headers->{'x-forwarded-host'};
        if ( $host =~ /^(.+):(\d+)$/ ) {
            $host = $1;
            $env->{SERVER_PORT} = $2;
        }
        elsif ( $req->headers->{'x-forwarded-port'} ) {

            # in apache httpd.conf (RequestHeader set X-Forwarded-Port 8443)
            $env->{SERVER_PORT} = $req->headers->{'x-forwarded-port'};
        }
        $env->{HTTP_HOST} = $host;

        $req->headers->header( 'Host' => $env->{HTTP_HOST} );
    }
    $req->_connection->{env} = $env;

    for my $attr (qw/uri base/) {
        my $scheme = $req->secure ? 'https' : 'http';
        my $host = $env->{HTTP_HOST} || $env->{SERVER_NAME};
        my $port = $env->{SERVER_PORT} || ( $req->secure ? 443 : 80 );

        # my $path_info = $env->{PATH_INFO} || '/';

        $req->$attr->scheme($scheme);
        $req->$attr->host($host);
        $req->$attr->port($port);

        # $req->$attr->path($path_info);
        # $req->$attr( $req->$attr->canonical );
    }
    $req;
};

__MIDDLEWARE__

__END__

