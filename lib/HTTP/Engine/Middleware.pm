package HTTP::Engine::Middleware;
use Mouse;
our $VERSION = '0.01';

use Carp ();

has 'middlewares' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { +[] },
);

has '_instance_of' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { +{} },
);

sub init_class {
    my $klass = shift;
    my $meta  = Mouse::Meta::Class->initialize($klass);
    $meta->superclasses('Mouse::Object')
        unless $meta->superclasses;

    no strict 'refs';
    no warnings 'redefine';
    *{ $klass . '::meta' } = sub { $meta };
}

sub import {
    my($class, ) = @_;
    my $caller = caller;

    return unless $caller =~ /(?:\:)?Middleware\:\:.+/;

    strict->import;
    warnings->import;

    init_class($caller);

    Mouse->export_to_level(1);    

    no strict 'refs';
    *{"$caller\::__MIDDLEWARE__"} = sub {
        use strict;
        my $caller = caller(0);
        __MIDDLEWARE__($caller);
    };

    *{"$caller\::before_handle"} = sub (&) { goto \&before_handle; };
    *{"$caller\::after_handle"}  = sub (&) { goto \&after_handle; }
}

sub __MIDDLEWARE__ {
    my ( $caller, ) = @_;

    Mouse::unimport;
    Mouse::Util::apply_all_roles( $caller, 'HTTP::Engine::Middleware::Role' );
    $caller->meta->make_immutable( inline_destructor => 1 );
    "MIDDLEWARE";
}

sub before_handle {
    Carp::croak "Can't call before_handle function outside Middleware's load phase";
}

sub after_handle {
    Carp::croak "Can't call after_handle function outside Middleware's load phase";
}

sub install {
    my($self, @middlewares) = @_;

    my %config;
    for my $middleware (@middlewares) {
        if (ref($middleware) eq 'HASH') {
            $config{$self->middlewares->[-1]} = $middleware;
            next;
        }

        $config{$middleware} = {};
        push @{ $self->middlewares }, $middleware;
    }

    # load and create instance
    while (my($name, $config) = each %config) {
        my @before_handles;
        my @after_handles;
        {
            no warnings 'redefine';
            local *before_handle = sub { push @before_handles, @_ };
            local *after_handle  = sub { push @after_handles, @_ };
            local $@;
            Mouse::load_class($name);
            $@ and die $@;
        }
        my $instance = $name->new($config);
        @{ $instance->before_handles } = @before_handles;
        @{ $instance->after_handles }  = @after_handles;

        $self->_instance_of->{$name} = $instance;
    }
}

sub instance_of {
    my($self, $name) = @_;
    $self->_instance_of->{$name};
}

sub handler {
    my($self, $handle) = @_;

    sub {
        my $req = shift;

        for my $middleware (@{ $self->middlewares }) {
            my $instance = $self->_instance_of->{$middleware};
            for my $code (@{ $instance->before_handles }) {
                $req = $code->($instance, $req);
            }
        }
        my $res = $handle->($req);
        for my $middleware (@{ $self->middlewares }) {
            my $instance = $self->_instance_of->{$middleware};
            for my $code (reverse @{ $instance->after_handles }) {
                $res = $code->($instance, $req, $res);
            }
        }

        $res;
    };
}

1;
__END__

=for stopwords Daisuke Maki dann hidek marcus nyarla API middlewares

=encoding utf8

=head1 NAME

HTTP::Engine::Middleware - middlewares distribution

=head1 WARNING! WARNING!

THIS MODULE IS IN ITS ALPHA QUALITY. THE API MAY CHANGE IN THE FUTURE

=head1 DESCRIPTION

HTTP::Engine::Middleware is official middlewares distribution of HTTP::Engine.

=head1 TODO

no plan :-)

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

Daisuke Maki

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

nyarla

marcus

hidek

dann

=head1 SEE ALSO

L<HTTP::Engine>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
