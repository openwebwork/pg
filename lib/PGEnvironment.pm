

use strict;
use warnings;

package PGEnvironment;

my $ce;
my $pg_dir;

use Data::Dump qw/dd/;
use YAML::XS qw/LoadFile/;


BEGIN {
	eval {
			require WeBWorK::CourseEnvironment;
			# WeBWorK::CourseEnvironment->import();
			$ce = WeBWorK::CourseEnvironment->new({webwork_dir=>$ENV{WEBWORK_ROOT}});
			1;
	} or do {
		my $error = $@;

		$pg_dir = $ENV{PG_ROOT};
		die "The environmental variable PG_ROOT must be a directory" unless -d $pg_dir;

		# Module load failed. You could recover, try loading
		# an alternate module, die with $error...
		# whatever's appropriate
	};
}

sub new {
	my ($invocant, @rest) = @_;
	my $class = ref($invocant) || $invocant;

	my $self = {
	};

	if (defined($ce)){
		$self->{webworkDirs} = $ce->{webworkDirs};
		$self->{externalPrograms} = $ce->{externalPrograms};
		$self->{pg_dir} = $ce->{pg_dir};
	} else {
		## load from an conf file;
		$self->{pg_dir} = $ENV{PG_ROOT};

		dd LoadFile($self->{pg_dir} . "/conf/pg_defaults.yml");

	}

	bless $self, $class;

	return $self;
}


1;