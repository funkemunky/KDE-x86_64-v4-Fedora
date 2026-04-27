#!/usr/bin/perl

# A simple nameserver that responds only to queries for "A" records of
# "mister.edward.hyde". This program is an almost verbatim copy of the
# Net::DNS::Nameserver example at:
# http://search.cpan.org/dist/Net-DNS/lib/Net/DNS/Nameserver.pm#EXAMPLE

use strict;
use warnings;
use Net::DNS::Nameserver;

sub reply_handler
{
  my ($qname, $qclass, $qtype, $peerhost, $query, $conn) = @_;
  my ($rcode, @ans, @auth, @add);

  print "Received query from $peerhost to " . $conn->{sockhost} . "\n";
  $query->print;

  my $ttl   = 0;
  my $rdata = "";

  $rcode = "NOERROR";

  if ($qtype eq "A")
  {
    if ($qname eq "foo.red.hat")        { $rdata = "127.126.125.124" }
    elsif ($qname eq "bar.foo.red.hat") { $rdata = "127.126.125.124" }
    elsif ($qname eq "red.hat")         { $rdata = "127.126.125.124" }
    else                                { $rcode = "NXDOMAIN" }
  }
  elsif ($qtype eq "AAAA")
  {
    if ($qname eq "foo.red.hat")        { $rdata = "::1" }
    elsif ($qname eq "bar.foo.red.hat") { $rdata = "::1" }
    elsif ($qname eq "red.hat")         { $rdata = "::1" }
    else                                { $rcode = "NXDOMAIN" }
  }
  else
  {
    $rcode = "NXDOMAIN";
  }

  if ($rcode == "NOERROR")
  {
    my $rr = new Net::DNS::RR("$qname $ttl $qclass $qtype $rdata");
    push @ans, $rr;
  }

  # mark the answer as authoritive (by setting the 'aa' flag
  return ($rcode, \@ans, \@auth, \@add, {aa => 1});
}

my $ns = new Net::DNS::Nameserver(
                                  LocalPort    => 53,
                                  ReplyHandler => \&reply_handler,
                                  Verbose      => 1
                                 )
  || die "couldn't create nameserver object\n";

if ($ns->can('start_server')) {
    $ns->start_server;
} else {
    $ns->main_loop;
}

print "ns.pl PID: $$\n";
