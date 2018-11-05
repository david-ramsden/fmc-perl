package FMC;

use strict;
use warnings;
use Exporter;
use REST::Client;
use JSON;
use MIME::Base64;
use Data::Dumper;

our @ISA       = qw(Exporter);
our @EXPORT    = qw();
our @EXPORT_OK = qw();
our $VERSION   = 0.01;

my ($client, $domain, $verbose) = undef;

sub new
{
	my ($class, %args) = @_;

	return bless \%args, $class;
}

sub DESTROY
{
	if (defined $client)
	{
		warn "Revoking access to the FMC" if $verbose;

		$client->POST('/api/fmc_platform/v1/auth/revokeaccess');
	}
}

sub connect
{
	my ($self, %config) = @_;

	$config{ssl_verify} = $config{ssl_verify} || 0;
	$verbose = $config{verbose};

	warn "Connecting to the FMC" if $verbose;

	$client = REST::Client->new();
	$client->getUseragent()->ssl_opts(SSL_verify_mode => $config{ssl_verify},
					  verify_hostname => $config{ssl_verify});
	$client->setHost($config{url});
	$client->addHeader('Authorization', "Basic " . encode_base64($config{credentials}));
	$client->addHeader('Content-type', 'application/json');

	$client->POST('/api/fmc_platform/v1/auth/generatetoken');

	$domain = $client->responseHeader('DOMAIN_UUID') ||
		  $client->responseHeader('domain_uuid') ||
		  $client->responseHeader('Global');
	die "Unable to obtain domain from the FMC (" . $self->get_error . ")" unless defined $domain;

	my $auth_token = $client->responseHeader('X-auth-access-token');
	die "Unable to obtain auth token from the FMC (" . $self->get_error . ")" unless defined $auth_token;
	$client->addHeader('X-auth-access-token', $auth_token);

	warn "Connected to the FMC and got auth token: $auth_token" if $verbose;
}

sub get_error
{
	my ($self) = @_;

	my $response = undef;
	eval
	{
		$response = decode_json($client->responseContent)->{error}->{messages}[0]->{description};
	};
	$response = $client->responseContent unless defined $response;

	return $client->responseCode . ": " . $response;
}

sub get_networkgroups
{
	my ($self) = @_;

	warn "Fetching network groups from the FMC" if $verbose;

	$client->GET("/api/fmc_config/v1/domain/$domain/object/networkgroups?limit=999999999");
	die "Unable to get network groups from the FMC (" . $self->get_error . ")" unless $client->responseCode == 200;

	return decode_json($client->responseContent)->{items};
}

sub get_networkgroup
{
	my ($self, $find) = @_;

	my $findby = undef;
	my %hash;

	if ($find =~ m/^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$/)
	{
		$findby = 'id';
	}
	else
	{
		$findby = 'name';
	}

	warn "Finding network group $find by $findby" if $verbose;

	foreach my $group (@{$self->get_networkgroups})
	{
		if ($group->{$findby} =~ m/^$find$/i)
		{
			warn "Network group $find was found by $findby" if $verbose;
			$hash{name}   = $group->{name};
			$hash{id}     = $group->{id};
			$hash{values} = $self->__get_networkgroup_values($group->{id});
			return \%hash;
		}
	}

	warn "Network group $find was NOT found by $findby" if $verbose;

	return undef;
}

sub __get_networkgroup_values
{
	my ($self, $id) = @_;

	warn "Getting values of network group with ID $id" if $verbose;

	$client->GET("/api/fmc_config/v1/domain/$domain/object/networkgroups/$id");
	die "Unable to get network group from the FMC (" . $self->get_error . ")" unless $client->responseCode == 200;

	return decode_json($client->responseContent)->{literals};
}

sub update_networkgroup
{
	my ($self, $id, $valuesref, $merge) = @_;
	my @values = @{$valuesref};
	
	warn "Updating values of network group $id" if $verbose;

	if (defined $merge)
	{
		warn "Performing a merge for group $id" if $verbose;

		my @current = $self->__get_networkgroup_values($id);

		foreach (@values)
		{
			$current[0][(keys $current[0])] = $_;
		}

		@values = @{$current[0]};
	}

	my %data = ('id' => $id,
		    'name' => $self->get_networkgroup($id)->{name},
		    'type' => 'NetworkGroup',
		    'literals' => \@values);

	$client->PUT("/api/fmc_config/v1/domain/$domain/object/networkgroups/$id", encode_json(\%data));
	die "Unable to update group on the FMC (" . $self->get_error . ")" unless $client->responseCode == 200;
}

1;
