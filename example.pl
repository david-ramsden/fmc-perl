#!/usr/bin/perl -w

use strict;
use warnings;

use FMC;
use Net::DNS::Resolver;

my $fmc = FMC->new();
# Connect to the FMC.
$fmc->connect(url         => 'https://172.29.0.43',
	      credentials => 'api:Api123321',
	      verbose	  => 1);

# Get network group called "InternalNetworks".
# This will return a hash containing name, ID and values (as an array).
my $group = $fmc->get_networkgroup("TestGroup");

# Show values before any changes.
print "\n*** Network group before:\n";
foreach my $value (@{$group->{values}})
{
	print "\t$value->{value} [$value->{type}]\n";
}
print "\n";

# Resolve FQDN using the two DNS servers specified.
# DNS servers could get different replies because of GeoDNS.
my %ips = get_ips_from_fqdn("dev-prod05.conferdeploy.net", ('192.168.228.27','172.16.68.53'));
#my %ips = get_ips_from_fqdn("one.one.one.one", ('192.168.228.27','172.16.68.53'));

my @new = ();
foreach my $ip (keys %ips)
{
	push @new, {type => 'Host', value => $ips{$ip}};
}

# Update the network group with the values prepared above.
# This will perform a merge, e.g. take existing values and add in any new values.
$fmc->update_networkgroup($group->{id}, \@new, 1);

# Get network group values again (post-update).
$group = $fmc->get_networkgroup($group->{id});

# Show the new values of the network group.
print "\n*** Network group after:\n";
foreach my $value (@{$group->{values}})
{
	print "\t$value->{value} [$value->{type}]\n";
}
print "\n";



# Parse in an FQDN and n number of DNS servers.
# Returns unified list of A records for FQDN from the DNS servers.
sub get_ips_from_fqdn
{
        my $fqdn       = shift;
        my @dnsservers = @_;

        my $resolver = Net::DNS::Resolver->new(udp_timeout => 3);
        my %ips;

        foreach my $dnsserver (@dnsservers)
	{
                $resolver->nameservers($dnsserver);
                my $packet = $resolver->query($fqdn, 'A');

                if (defined($packet))
		{
                        foreach my $ip (map { $_->address } grep { $_->type eq 'A' } $packet->answer)
			{
                                $ips{$ip} = $ip;
                        }
                }
        }

        return %ips;
}
