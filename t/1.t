# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'
# vim:syntax=perl

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 34;
#use Test::More 'no_plan';
BEGIN { use_ok('Net::Vypress::Chat') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $vyc = Net::Vypress::Chat->new(
	'localip' => '127.0.0.1',
	'debug' => 0
);
ok(defined $vyc, '$vyc is an object');
ok($vyc->isa('Net::Vypress::Chat'), "and it's the right class");

# Startup stuff
$vyc->startup;
ok(defined $vyc->{'send'}, "send socket ok.");
ok(defined $vyc->{'listen'}, "listen socket ok.");
ok($vyc->{'init'} eq '1', "module was initialized.");

# Testing functions
sub get_type_ok { # {{{
	my $oktype = shift;
	my ($buffer, $msgok);
	my $time = time;
	until ($msgok) {
		last if (time - $time >= 5) && !$msgok;
		$vyc->{'listen'}->recv($buffer, 1024);
		my @return = $vyc->recognise($buffer);
		my $type = shift @return;
		$msgok = 1 if ($type eq $oktype);
	}
	return $msgok;
} # }}}
use Data::Dumper;

ok($vyc->num2status(0) eq "Available", "num2status avail. ok");
ok($vyc->num2status(1) eq "DND", "num2status DND ok");
ok($vyc->num2status(2) eq "Away", "num2status away ok");
ok($vyc->num2status(3) eq "Offline", "num2status offline ok");

ok($vyc->num2active(0) eq "Inactive", "num2active inactive ok");
ok($vyc->num2active(1) eq "Active", "num2active active ok");
ok($vyc->num2active(2) eq "Unknown", "num2active unknown ok");

$vyc->nick('anothernick');
ok($vyc->{'nick'} eq 'anothernick', "local nick change.");
#ok(get_type_ok('nick'), "remote nick change.");

$vyc->who();
ok(get_type_ok('who'), "got who.");

$vyc->remote_exec($vyc->{'nick'}, '', '');
ok(get_type_ok('remote_exec'), "got remote execution.");

$vyc->remote_exec_ack($vyc->{'nick'}, '');
ok(get_type_ok('remote_exec_ack'), "got remote execution ack.");

$vyc->sound_req("#Main", '');
ok(get_type_ok('sound_req'), "got sound req.");

$vyc->me("#Main", '');
ok(get_type_ok('me'), "got /me.");

$vyc->chat("#Main", '');
ok(get_type_ok('chat'), "got chat line.");

ok($vyc->on_chan("#bullies") == 0, "on_chan ok 0.");
ok($vyc->on_chan("#Main") == 1, "on_chan ok 1.");

$vyc->join("#test");
ok(get_type_ok('join'), "got join line.");
ok($vyc->on_chan("#test") == 1, "join succeded.");

$vyc->part("#test");
ok(get_type_ok('part'), "got part line.");
ok($vyc->on_chan("#test") == 0, "part succeded.");

$vyc->msg($vyc->{'nick'}, "");
ok(get_type_ok('msg'), "got msg.");

$vyc->topic("#Main", 'Test topic.');
ok(get_type_ok('topic'), "got topic line.");

$vyc->status(0, "");
ok(get_type_ok('status'), "got status change.");

$vyc->active(1);
ok(get_type_ok('active'), "got active change.");

$vyc->beep($vyc->{nick});
#ok(get_type_ok('beep'), "got beep.");

$vyc->info($vyc->{nick});
ok(get_type_ok('info'), "got info req.");

# Shutting down
$vyc->shutdown;
ok(!defined $vyc->{'send'}, "send socket shut down.");
ok(!defined $vyc->{'listen'}, "listen socket shut down.");
ok($vyc->{'init'} eq '0', "module was uninitialized.");
