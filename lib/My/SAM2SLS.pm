package My::SAM2SLS;
use warnings;
use strict;
use v5.10.0;
use utf8;

#------------------------------------------------------------------------------
# serverless.yml reference:
# https://www.serverless.com/framework/docs/providers/aws/guide/serverless.yml/

#------------------------------------------------------------------------------
use File::Basename qw(basename);
our $PROGNAME = basename($0);

#------------------------------------------------------------------------------
use YAML qw();
use Tie::IxHash;

#------------------------------------------------------------------------------
use FindBin;
use lib "$FindBin::Bin/../../lib"; #shut up a warning in emacs
use My::SAM2SLS::Util;

our $DEFAULT_SERVICE_NAME;
our $DEFAULT_STAGE;
our $DEFAULT_REGION;
our $DEFAULT_PROFILE;

BEGIN {
    $DEFAULT_SERVICE_NAME = 'SERVICENAME';
    $DEFAULT_STAGE        = 'dev';
    $DEFAULT_REGION       = 'us-east-1';
    $DEFAULT_PROFILE      = 'default';
}

use Moo;
has 'serviceName' => (is => 'rw', default => $DEFAULT_SERVICE_NAME);
has 'stage'       => (is => 'rw', default => $DEFAULT_STAGE);
has 'region'      => (is => 'rw', default => $DEFAULT_REGION);
has 'profile'     => (is => 'rw', default => $DEFAULT_PROFILE);

sub sam2sls {
    my ($self, $sam) = @_;

    my @resourceNames = keys %{$sam->{Resources}};
    if (scalar @resourceNames < 1) {
        die("$PROGNAME: no Resources found\n");
    } elsif (scalar @resourceNames != 1) {
        die("$PROGNAME: more than one Resources entry not supported\n");
    }
    my ($resourceName) = @resourceNames;
    my $samResource = $sam->{Resources}->{$resourceName};

    my @outputNames = keys %{$sam->{Outputs}};
    if (scalar @outputNames < 1) {
        # do nothing --- this is fine
    } elsif (scalar @outputNames > 1) {
        die("$PROGNAME: more than one Outputs entry not supported\n");
    }
    my ($outputName) = @outputNames;
    my $samOutput = $sam->{Outputs}->{$outputName};

    if (defined $outputName && defined $resourceName && $outputName ne $resourceName) {
        die("$PROGNAME: resource name '$resourceName' and output name '$outputName' are not equal\n");
    }

    my $runtime             = eval { delete $samResource->{Properties}->{Runtime} };
    my $memorySize          = eval { delete $samResource->{Properties}->{MemorySize} };
    my $timeout             = eval { delete $samResource->{Properties}->{Timeout} };
    my $description         = eval { delete $sam->{Description} };
    my $endpointType        = eval { delete $sam->{Globals}->{Api}->{EndpointConfiguration} };
    my $codeUri             = eval { delete $samResource->{Properties}->{CodeUri} };
    my $handler             = eval { delete $samResource->{Properties}->{Handler} };
    my $resourceRole        = eval { delete $samResource->{Properties}->{Role} };
    my $resourceDescription = eval { delete $samResource->{Properties}->{Description} };

    if (defined $codeUri && $codeUri ne '.') {
        die("$PROGNAME: unsupported codeUri: $codeUri\n");
    }

    my $sls = My::SAM2SLS::Util::newHash();
    $sls->{service} = $self->serviceName;
    $sls->{provider} = My::SAM2SLS::Util::newHash();
    $sls->{provider}->{name} = 'aws';
    $sls->{provider}->{runtime}    = $runtime if defined $runtime;
    $sls->{provider}->{memorySize} = $memorySize if defined $memorySize;
    $sls->{provider}->{timeout}    = $timeout    if defined $timeout;
    $sls->{provider}->{stage}      = sprintf('${opt:stage, \'%s\'}', $self->stage);
    $sls->{provider}->{region}     = sprintf('${opt:region, \'%s\'}', $self->region);
    $sls->{provider}->{profile}    = sprintf('${opt:profile, "%s"}', $self->profile);
    $sls->{provider}->{endpointType} = $endpointType if defined $endpointType;
    $sls->{provider}->{role}         = $resourceRole if defined $resourceRole;
    $sls->{provider}->{description}  = $resourceDescription if defined $resourceDescription;
    $sls->{resources} = My::SAM2SLS::Util::newHash();
    $sls->{resources}->{Description} = $description if defined $description;
    $sls->{package} = My::SAM2SLS::Util::newHash();
    $sls->{package}->{individually} = 'true';
    $sls->{functions} = My::SAM2SLS::Util::newHash();

    $sls->{functions}->{$resourceName} = My::SAM2SLS::Util::newHash();
    $sls->{functions}->{$resourceName}->{package} = My::SAM2SLS::Util::newHash();
    $sls->{functions}->{$resourceName}->{handler} = $handler if defined $handler;

    my @eventNames = eval { keys %{$samResource->{Properties}->{Events}} };
    if (scalar @eventNames < 1) {
        die("$PROGNAME: no events listed\n");
    } elsif (scalar @eventNames > 1) {
        die("$PROGNAME: more than one event listed, not supported yet\n");
    }
    my ($eventName) = @eventNames;
    my $samEvent = $samResource->{Properties}->{Events}->{$eventName};

    my $method = eval { delete $samEvent->{Properties}->{Method} };
    my $path = eval { delete $samEvent->{Properties}->{Path} };

    my $event = My::SAM2SLS::Util::newHash();
    $sls->{functions}->{$resourceName}->{events} = [$event];
    $event->{http} = My::SAM2SLS::Util::newHash();
    if (defined $method || defined $path) {
        $event->{http}->{path} = $path if defined $path;
        $event->{http}->{method} = uc $method if defined $method;
    } else {
        $event->{http}->{path} = '/{proxy+}';
        $event->{http}->{method} = 'ANY';
    }

    my $getResourceType       = eval { delete $samEvent->{Type} };
    my $transform             = eval { delete $sam->{Transform} };
    my $templateFormatVersion = eval { delete $sam->{AWSTemplateFormatVersion} };
    my $outputDescription     = eval { delete $samOutput->{Description} };
    my $exportName            = eval { delete $samOutput->{Export}->{Name} };
    my $policies              = eval { delete $samResource->{Properties}->{Policies} };
    my $resourceType          = eval { delete $samResource->{Type} };
    my $outputValue           = eval { delete $samOutput->{Value} };

    if (defined $getResourceType && $getResourceType ne 'Api') {
        die("$PROGNAME: unsupported GetResource Type: $getResourceType\n");
    }
    if (defined $transform && $transform ne 'AWS::Serverless-2016-10-31') {
        die("$PROGNAME: unsupported transform: $transform\n");
    }
    if (defined $templateFormatVersion && $templateFormatVersion ne '2010-09-09') {
        die("$PROGNAME: unsupported template format version: $templateFormatVersion\n");
    }
    if (defined $resourceType && $resourceType ne 'AWS::Serverless::Function') {
        die("$PROGNAME: unsupported resource type: $resourceType\n");
    }
    if (defined $policies && $policies ne 'AWSLambdaBasicExecutionRole') {
        die("$PROGNAME: unsupported policies: $policies\n");
    }

    return $sls;
}

1;
