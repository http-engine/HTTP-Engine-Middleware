package HTTP::Engine::Middleware::Status;
use HTTP::Engine::Middleware;
use HTTP::Engine::Response;

use Any::Moose '::Util::TypeConstraints';

subtype 'HTTP::Engine::Middleware::Status::Plugin'
    => as 'Object'
    => where { $_->isa('HTTP::Engine::Middleware::Status::Base') };

subtype 'HTTP::Engine::Middleware::Status::Plugins'
    => as 'ArrayRef[HTTP::Engine::Middleware::Status::Plugin]';
coerce 'HTTP::Engine::Middleware::Status::Plugins'
    => from 'ArrayRef[HashRef]' => via {
        my $build = [];
        for my $plugin (@{ $_ }) {
            my $module = $plugin->{module};
            my $config = $plugin->{config} || +{};
            $module = __PACKAGE__ . "::$module" unless $module =~ s/^\+//;
            Any::Moose::load_class($module);
            push @{ $build }, $module->new(%{ $config });
        }
        $build;
    };
coerce 'HTTP::Engine::Middleware::Status::Plugins'
    => from 'ArrayRef[Str]' => via {
        my $build = [];
        for my $module (@{ $_ }) {
            $module = __PACKAGE__ . "::$module" unless $module =~ s/^\+//;
            Any::Moose::load_class($module);
            push @{ $build }, $module->new;
        }
        $build;
    };

has 'launch_at' => (
    is      => 'rw',
    isa     => 'Str',
    default => '/httpengine-status',
);

has 'plugins' => (
    is      => 'rw',
    isa     => 'HTTP::Engine::Middleware::Status::Plugins',
    default => sub { [] },
    coerce => 1,
);

sub run_hook {
    my($self, $hook, %args) = @_;
    my @rets;
    if ($hook eq 'render') {
        for my $plugin (@{ $self->plugins }) {
            push @rets, $plugin->render_header(%args), $plugin->render(%args);
        }
    } else {
        for my $plugin (@{ $self->plugins }) {
            push @rets, $plugin->$hook(%args);
        }
    }
    @rets;
}

before_handle {
    my ( $c, $self, $req ) = @_;

    my $launch_at = $self->launch_at;
    unless ($launch_at && $req->uri->path =~ /^$launch_at/) {
        # $self->run_hook('before');
        return $req;
    }

    my $plugin_htmls = join '', $self->run_hook('render', req => $req);

    my $html =<<HTML;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
    "http://www.w3.org/TR/html4/loose.dtd">
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
        <meta http-equiv="Content-Script-Type" content="text/javascript">
        <meta http-equiv="Content-Style-Type" content="text/css">
        <title>HTTP::Engine Status</title>
    </head>
    <body>
        <h1>HTTP::Engine Status</h1>

$plugin_htmls

    </body>
</html>
HTML

    HTTP::Engine::Response->new( body => $html );;
};


#after_handle {
#    my($c, $self, $req, $res) = @_;
#    $self->run_hook('after');
#};

__MIDDLEWARE__
