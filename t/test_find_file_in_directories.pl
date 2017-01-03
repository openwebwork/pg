#!/Volumes/WW_test/opt/local/bin/perl -w


use strict;


BEGIN {
        die "WEBWORK_ROOT not found in environment. \n
             WEBWORK_ROOT can be defined in your .cshrc or .bashrc file\n
             It should be set to the webwork2 directory (e.g. /opt/webwork/webwork2)"
                unless exists $ENV{WEBWORK_ROOT};
	# Unused variable, but define it twice to avoid an error message.
	$WeBWorK::Constants::WEBWORK_DIRECTORY = $ENV{WEBWORK_ROOT};
	
	# Define MP2 -- this would normally be done in webwork.apache2.4-config
	$ENV{MOD_PERL_API_VERSION}=2;
	print "Webwork root directory is $WeBWorK::Constants::WEBWORK_DIRECTORY\n\n";


	$WebworkBase::courseName = "gage_test";
	my $topDir = $WeBWorK::Constants::WEBWORK_DIRECTORY;
	$topDir =~ s|webwork2?$||;   # remove webwork2 link
	$WebworkBase::RootWebwork2Dir = "$topDir/webwork2";
	$WebworkBase::RootPGDir = "$topDir/pg";
	$WebworkBase::RootCourseDir = "${topDir}courses";

	eval "use lib '$WebworkBase::RootWebwork2Dir/lib'"; die $@ if $@;
	eval "use lib '$WebworkBase::RootPGDir/lib'"; die $@ if $@;
}	
	use PGalias;
	
	my $file = "prob14.html";
	my @directories = (
		"$WebworkBase::RootCourseDir/$WebworkBase::courseName/templates/setaliasCheck/htmlAliasCheck",
		"$WebworkBase::RootCourseDir/$WebworkBase::courseName/html",
		"$WebworkBase::RootWebwork2Dir/htdocs",
	);
	my $file_path = PGalias->find_file_in_directories($file, \@directories)//'not found';
	print "File found at: $file_path\n";



1;