#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use lib 't/lib';

use Test::More tests => 14;
use Test::Mojo;
use Mojolicious::Lite;
use Encode;

plugin Passphrase => { encoder => 'Reversed' };

get '/bc' => sub {
	my $self = shift;
	my ($p) = $self->param('p');
	$self->render(text => $self->hash_password( $p ));
};

get '/bv' => sub {
	my $self = shift;
	my ( $p, $c ) = map { $self->param($_) } qw/p c/;
	my $ok = $self->bcrypt_validate($p, $c);
	$self->render(text => ($ok ? 'Pass' : 'Fail'));
};

my $t = Test::Mojo->new();
my @data = (
	[ '$reversed$', ''],
	[ '$reversed$drowssap', 'password'],
	[ '$reversed$0', '0'],
	[ encode('utf-8', '$reversed$арогаз-авон'), 'нова-загора'],
);

for my $row (@data) {
	my ($hash, $password) = @{$row};
	$t->get_ok("/bc?p=$password")->content_is(decode('utf-8', $hash));
	$t->get_ok("/bv?p=$password&c=$hash", "Password $hash");
}

my $password = 'big secret';
my $bcrypted = app->hash_password($password);
ok( app->verify_password( $password, $bcrypted ), 'accept ok' );
ok( !app->verify_password( 'meow!', $bcrypted ), 'deny ok' );

__DATA__
