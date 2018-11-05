# fmc-perl
Perl Module for interacting with the Cisco Firepower Management Center API.

## Features
- Connect to a Cisco FMC and obtain an authentication access token. Token gets explicitly revoked once connection is no longer needed (e.g. script terminates).
- Get a Network Group, either by group name *or* group UUID and return group name, group UUID and it's associated values.
- Update a Network Group's values and optionally merge new values with existing values instead of overwriting existing values.

## Missing Features
- Only currently supports Network Groups.
- Does not yet support deploying changes to devices.

## To Do
- Comments/documentation.
- Improved error handling (use croak?).
- Better error checking.
- Add missing features.

## Example
Included is an example that uses the FMC Perl module. It connects to the FMC and gets a Network Group called TestGroup. This returns all the current values of TestGroup. The script then resolves an FQDN using two different DNS servers and then updates, by merging the new and existing values, the TestGroup Network Group.

Here's what this looks like with the verbose option enabled: 

````
$ ./example.pl
Connecting to the FMC at FMC.pm line 42.
Connected to the FMC and got auth token: d83d35a6-b616-4ffd-aaf3-f5060a7ab48a at FMC.pm line 62.
Finding network group TestGroup by name at FMC.pm line 107.
Fetching network groups from the FMC at FMC.pm line 83.
Network group InternalNetworks was found by name at FMC.pm line 113.
Getting values of network group with ID 000C29DC-A9BB-0ed3-0000-012884904948 at FMC.pm line 130.

*** Network group before:
  34.237.177.237 [Host]
  34.237.180.238 [Host]
  34.234.106.197 [Host]
  34.237.240.4 [Host]
  34.239.202.48 [Host]
  34.239.235.103 [Host]
  34.198.159.207 [Host]
  35.173.197.210 [Host]
  18.214.112.236 [Host]
  34.204.113.110 [Host]
  34.238.4.33 [Host]
  34.195.210.219 [Host]
  34.237.173.243 [Host]
  34.200.167.73 [Host]
  34.194.191.180 [Host]

Updating values of network group 000C29DC-A9BB-0ed3-0000-012884904948 at FMC.pm line 143.
Performing a merge for group 000C29DC-A9BB-0ed3-0000-012884904948 at FMC.pm line 147.
Getting values of network group with ID 000C29DC-A9BB-0ed3-0000-012884904948 at FMC.pm line 130.
Finding network group 000C29DC-A9BB-0ed3-0000-012884904948 by id at FMC.pm line 107.
Fetching network groups from the FMC at FMC.pm line 83.
Network group 000C29DC-A9BB-0ed3-0000-012884904948 was found by id at FMC.pm line 113.
Getting values of network group with ID 000C29DC-A9BB-0ed3-0000-012884904948 at FMC.pm line 130.
Finding network group 000C29DC-A9BB-0ed3-0000-012884904948 by id at FMC.pm line 107.
Fetching network groups from the FMC at FMC.pm line 83.
Network group 000C29DC-A9BB-0ed3-0000-012884904948 was found by id at FMC.pm line 113.
Getting values of network group with ID 000C29DC-A9BB-0ed3-0000-012884904948 at FMC.pm line 130.

*** Network group after:
  34.237.177.237 [Host]
  34.237.180.238 [Host]
  34.234.106.197 [Host]
  34.237.240.4 [Host]
  34.239.202.48 [Host]
  34.239.235.103 [Host]
  34.198.159.207 [Host]
  35.173.197.210 [Host]
  18.214.112.236 [Host]
  34.204.113.110 [Host]
  34.238.4.33 [Host]
  34.195.210.219 [Host]
  34.237.173.243 [Host]
  34.200.167.73 [Host]
  34.194.191.180 [Host]
  1.1.1.1 [Host]
  1.0.0.1 [Host]

Revoking access to the FMC at FMC.pm line 29.
````

In the real world this could be useful to keep Network Groups that represent FQDNs up to date, since Cisco FTD currently lacks FQDN support.
