package Catalyst::Plugin::Breadcrumbs;
use warnings;
use strict;

our $VERSION = 3;

=head1 NAME

Catalyst::Plugin::Breadcrumbs - Breadcrumb information for your templates.

=head1 SYNOPSIS

use Catalyst qw/-Debug Breadcrumbs/;

__PACKAGE__->config(

    ....

    breadcrumbs => {
        hide_index => 1,
        hide_home  => 1,
        labels     => {
            '/'       => 'Home label',
            '/foobar' => 'FooBar label',
            ....
        },
    },

    ....

)

=head1 DESCRIPTION

This plugin provides the ability to use c.breadcrumbs from your
template to get a nice loop of the breadcrumb information.

There are some very basic configuration options for you to use as
you can see above. By default both hide_index and hide_home are
off.

Set hide_home to a true value if you don't want to see the root
location '/' to be interpreted as part of your breadcrumbs.

Set hide_index to a true value if you don't want to see 'Index'
as the last piece of your breadcrumb when you hit a path such as
'/foo/', which in Catalyst, implies an 'index' action. You will
almost always want to be setting this value. So much so that in
future versions it may be on by default, so I suggest not
relying on it being on by default, turn it on of you want it.

Use the labels hash if you aren't happy with the default types
of labels. Which is pretty much ucfirst($path), but underscores
will also be replaced with spaces by default. /foo_bar would
default to 'Foo Bar'.

=head1 METHODS

=over 4

=item breadcrumbs

This method will return an array ref that you can iterate
through in your template. It will be an array of hashrefs,
each having a "path" and a "label" field.

E.g.

 <div id="breadcrumbs">
    [% FOREACH item IN c.breadcrumbs %]
        <!-- We don't want to have a link or divider for the
             last breadcrumb -->
        [% IF loop.last %]
            [% item.label %]
        [% ELSE %]
            <a href="[% c.uri_for(item.path) %]">
                item.label
            </a>
            &gt;&gt;
        [% END %]
    [% END %]
 </div>

Will print breadcrumbs like:

Home >> Admin >> Edit

If you are like me, you will move all that into a breadcrumbs.tt
and include it on every page that you want breadcrumbs on. I
also have something like this after my breadcrumbs:

[% IF object %] &gt;&gt; [% object.title %][% END %]

So that your breadcrumbs are more like
"Home >> Admin >> Edit >> $title". The breadcrumbs method
doesn't take care of this, it is left up to the template.

=back

=cut

sub breadcrumbs {
    my $c = shift;

    my @breadcrumbs;
    my @paths = split('/', $c->req->action);

    while (my $label = pop @paths) {
        next if $label eq 'index' and $c->config->{breadcrumbs}->{hide_index};
        my $path = join('/', @paths, $label);
        $path = "/$path" unless $path =~ m#^/#;
        $label = _label_for($c, $path, $label);
        push @breadcrumbs, {
            path  => $path,
            label => $label,
        };
    }

    unless (
        $c->config->{breadcrumbs}->{hide_home}
        or $c->req->path eq 'index'
    ) {
        my $label = _label_for($c, '/', 'home');
        push @breadcrumbs, { path => '/', label => $label };
    }

    return [ reverse @breadcrumbs ];
}

=head1 AUTHOR

Danial Pearce <cpan@tigris.id.au>

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

sub _label_for {
    my ($c, $path, $label) = @_;

    # I considered returning undef here if {labels} existed but there was
    # no label for the current path... Then I came to my senses and thought
    # this would make it easy if you mostly wanted default labels except in
    # 1 or 2 circumstances. I know i'm autovivifying, and i don't care.
    return $c->config->{breadcrumbs}->{labels}->{$path}
        if exists $c->config->{breadcrumbs}->{labels}->{$path};

    $label =~ s/_(.)/' ' . uc($1)/eg;
    return !$c->config->{breadcrumbs}->{lowercase}
        ? ucfirst($label)
        : lc($label);
}

1;

__END__
