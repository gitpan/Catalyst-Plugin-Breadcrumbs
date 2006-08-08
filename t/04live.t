#! perl

package TestApp;
use strict;
use warnings;
use Catalyst qw/Breadcrumbs/;
__PACKAGE__->config(name => 'Test App');
__PACKAGE__->setup;

sub auto : Global {
    my ($self, $c) = @_;
    $c->config->{breadcrumbs} = {};
}

sub index : Global {
    my ($self, $c) = @_;
    $c->config->{breadcrumbs}->{hide_index} = $c->req->param('hide_index');
    $c->config->{breadcrumbs}->{hide_home}  = $c->req->param('hide_home');
}

sub label_test : Global {
    my ($self, $c) = @_;
    $c->config->{breadcrumbs}->{labels} = {
        '/'                 => 'Home',
        '/label_test'       => 'Label_t3st',
        '/a'                => 'A',
        '/a/label_test'     => 'B'
    };
}

sub end : Private {
    my ($self, $c) = @_;
    $c->res->output(
        join("\n", map { "$_->{path} = $_->{label}" } @{$c->breadcrumbs})
    );
}

1;

package TestApp::Controller::Root;
use base 'Catalyst::Controller';
1;

package TestApp::Controller::A;
use base 'Catalyst::Controller';
1;

package TestApp::Controller::A::B;
use base 'Catalyst::Controller';
1;

package main;
use strict;
use warnings;

use Test::More tests => 10;
use Catalyst::Test 'TestApp';

# test hide_home
{
    my $url      = '/index?hide_home=1';
    my $expected = '/index = Index';
    my $content  = get($url) || '';
    ok($content, "Got content for $url");
    $content =~ s#^http://localhost(?::\d+)?##g;
    is($content, $expected, 'config option hide_home OK');
}

# test labels (root)
{
    my $url      = "/label_test";
    my $expected = join(
        "\n",
        '/ = Home',
        '/label_test = Label_t3st',
    );
    my $content  = get($url) || '';
    ok($content, "Got content for $url");
    $content =~ s#^http://localhost(?::\d+)?##g;
    is($content, $expected, 'config option labels (root) OK');
}

# test deep breadcrumb
{
    my $url      = '/a/b/index';
    my $expected = join(
        "\n",
        '/ = Home',
        '/a = A',
        '/a/b = B',
        '/a/b/index = Index',
    );
    my $content  = get($url) || '';
    SKIP: {
        skip 'I dunno how to fetch abitrary paths from Catalyst::Test', 2
            if $content =~ /please come back later/ism;
        ok($content, "Got content for $url");
        $content =~ s#^http://localhost(?::\d+)?##g;
        is($content, $expected, 'config option hide_home OK');
    }
}

# test hide_index
{
    my $url      = '/a?hide_index=1';
    my $expected = join(
        "\n",
        '/ = Home',
        '/a = A',
    );
    my $content  = get($url) || '';
    SKIP: {
        skip 'I dunno how to fetch abitrary paths from Catalyst::Test', 2
            if $content =~ /please come back later/ism;
        ok($content, "Got content for $url");
        $content =~ s#^http://localhost(?::\d+)?##g;
        is($content, $expected, 'config option hide_index OK');
    }
}

# test labels (deep)
{
    my $url      = "/a/label_test";
    my $expected = join(
        "\n",
        '/ = Home',
        '/a = A',
        '/a/label_test = B',
    );
    my $content  = get($url) || '';
    SKIP: {
        skip 'I dunno how to fetch abitrary paths from Catalyst::Test', 2
            if $content =~ /please come back later/ism;
        ok($content, "Got content for $url");
        $content =~ s#^http://localhost(?::\d+)?##g;
        is($content, $expected, 'config option labels (deep) OK');
    }
}
