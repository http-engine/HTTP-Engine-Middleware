package HTTP::Engine::Middleware::Static;
use HTTP::Engine::Middleware;
use HTTP::Engine::Response;

use MIME::Types;
use Path::Class;

has 'path' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { +{} },
);

has 'pattern' => (
    is         => 'ro',
    isa        => 'Str|Undef',
);

has 'mime_types' => (
    is  => 'ro',
    isa => 'MIME::Types',
);

sub BUILDARGS {
    my($class, $args) = @_;

    my @path;
    my %path;
    while (my($path, $conf) = splice @{ $args->{path} || [] }, 0, 2) {
        push @path, $path;
        $path{$path} = $conf;
    }
    $args->{pattern} = join '|', @path;
    $args->{path}    = \%path;

    my $mime_types = MIME::Types->new(only_complete => 1);
    $mime_types->create_type_index;
    $args->{mime_types} = $mime_types;

    $args;
}

before_handle {
    my ( $c, $self, $req ) = @_;

    my $re   = $self->pattern;
    my $uri_path = $req->uri->path;
    return $req unless $uri_path && $re && $uri_path =~ /^($re)(.*)$/;

    my($key, $file)  = ($1, $2);
    my $conf = $self->path->{$key} or return $req;
    my $base_path = $conf;

    $file .= 'index.html' if $uri_path =~ m!/$!;
    my @path = split '/', $file;
    my $file_path;
    if ($key =~ m!/$!) {
        $file_path = $base_path->file(@path);
    } else {
        $file_path = Path::Class::File->new( $base_path . shift(@path), @path );
    }

    return HTTP::Engine::Response->new( status => '404', body => 'not found' ) unless -e $file_path;

    my $content_type = 'text/plain';
    if ($file_path =~ /.*\.(\S{1,})$/xms ) {
        $content_type = $self->mime_types->mimeTypeOf($1);
    }

    my $fh = $file_path->openr;
    die "Unable to open $file_path for reading : $!" unless $fh;
    binmode $fh;

    my $res = HTTP::Engine::Response->new( body => $fh, content_type => $content_type );
    my $stat = $file_path->stat;
    $res->header( 'Content-Length' => $stat->size );
    $res->header( 'Last-Modified'  => $stat->mtime );
    $res;
};


__MIDDLEWARE__

__END__

=head1 NAME

HTTP::Engine::Middleware::Profile - handler for static files

=head1 SYNOPSIS

    my $mw = HTTP::Engine::Middleware->new;
    $mw->install( 'HTTP::Engine::Middleware::Static' => {
        path => [
            '/static/' => '/foo/bar',
            '/bl'      => '/baz',
        ],
    });
    HTTP::Engine->new(
        interface => {
            module => 'YourFavoriteInterfaceHere',
            request_handler => $mw->handler( \&handler ),
        }
    )->run();

    # $ GET http//localhost/static/baz.txt
    # to get the /foo/bar/baz.txt 

    # $ GET http//localhost/static/bzz.txt
    # to get the /foo/bar/bzz.txt 

    # $ GET http//localhost/bla.txt
    # to get the /baz/a.txt 

    # $ GET http//localhost/blb.txt
    # to get the /baz/b.txt 

=cut