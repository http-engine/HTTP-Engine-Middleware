package HTTP::Engine::Middleware::UploadTemp;
use HTTP::Engine::Middleware;

use File::Temp 'tempdir';
use File::Path 'rmtree';

has 'keepalive' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

has 'lazy' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has 'cleanup' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has 'tmpdir' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has 'base_dir' => (
    is => 'ro',
    isa => 'Str',
);

has 'template' => (
    is => 'ro',
    isa => 'Str',
);

{
    my $TMPDIR;
    sub _make_tempdir {
        return $TMPDIR if $TMPDIR;
        my $self = shift;

        my %option = (
            CLEANUP => ($self->cleanup && $self->keepalive),
            TMPDIR  => $self->tmpdir,
        );
        $option{DIR} = $self->base_dir if $self->base_dir;

        if ($self->template) {
            $TMPDIR = tempdir($self->template, %option);
        } else {
            $TMPDIR = tempdir(%option);
        }

        return $TMPDIR;
    }

    my $HAS_UPLOAD_TMP = 0;
    before_handle {
        return $_[2] if $HAS_UPLOAD_TMP;
        my(undef, $self, $req) = @_;

        if ($self->lazy) {
            $req->request_builder->upload_tmp(
            bless { context => $self }, 'HTTP::Engine::Middleware::UploadTemp::LazyObject'
        );
        } else {
            $req->request_builder->upload_tmp( $self->_make_tempdir );
        }

        $HAS_UPLOAD_TMP = 1;
        return $req;
    };

    after_handle {
        return $_[3] if $_[1]->keepalive;
        my(undef, $self, $req, $res) = @_;
    
        $req->request_builder->upload_tmp(undef);
        $HAS_UPLOAD_TMP = 0;

        return $res unless $TMPDIR;

        delete $req->{http_body} if exists $req->{http_body}; # HTTP::Body object is delete first                                                                
        rmtree $TMPDIR;
        undef $TMPDIR;

        return $res;
    };
}

{   
    package
        HTTP::Engine::Middleware::UploadTemp::LazyObject;
    use overload 
        'bool' => sub { 1 },
        q{""} => sub {
            $_[0]->{tempdir} = exists $_[0]->{tempdir} ? $_[0]->{tempdir} : $_[0]->{context}->_make_tempdir
        };
    sub tempdir { $_[0]->{tempdir} }
}

__MIDDLEWARE__


__END__

=head1 NAME

HTTP::Engine::Middleware::HTTPSession - session support at middleware layer

=head1 SYNOPSIS

    my $mw = HTTP::Engine::Middleware->new;
    $mw->install( 'HTTP::Engine::Middleware::UploadTemp' => {
        keepalive => 0,          # generate temporary directory to 1 request only
        cleanup   => 1,          # CLEANUP option for File::Temp::tempdir
        tmpdir    => 1,          # TMPDIR option for File::Temp::tempdir
        base_dir  => '/tmp',     # DIR option for File::Temp::tempdir
        template  => 'FOO_XXXX', # template option for File::Temp::tempdir
        lazy      => 1,          # lazy generate for temporary directory
    });
    HTTP::Engine->new(
        interface => {
            module => 'YourFavoriteInterfaceHere',
            request_handler => $mw->handler( \&handler ),
        }
    )->run();

=head1 DESCRIPTION

This middleware add the management of temporary directory for upload files.

Another reason is that L<HTTP::Body::MultiPart> does not clean up to temporary files.

=head1 AUTHOR

Kazuhiro Osawa

=head1 SEE ALSO

L<HTTP::Engine::Middleware>, L<HTTP::Engine::Request>, L<HTTP::Engine::Request::Upload>

