package PGloadfiles;

use strict;
use warnings;
use utf8;

use Encode qw(decode);

use WeBWorK::PG::Translator;

our $debugON = 0;

sub new {
	my ($class, $envir) = @_;
	die 'PGloadmacros must be called with an environment' unless ref($envir) eq 'HASH';

	my $pwd = $envir->{probFileName} =~ s!/[^/]*$!!r;
	$pwd = $envir->{templateDirectory} . $pwd unless substr($pwd, 0, 1) eq '/';

	# FIXME: This shouldn't be here.  See the note in PGalias.pm in the initialize subroutine.
	$pwd =~ s!/tmpEdit/!/!;

	return bless {
		envir         => $envir,
		macroFileList => {},                     # List of compiled macros.
		macrosPath    => $envir->{macrosPath},
		pwd           => $pwd,                   # Directory containing the current problem.
	}, $class;
}

sub loadMacros {
	my ($self, @files) = @_;

	my $macrosPath = $self->{envir}{macrosPath};

	while (@files) {
		my $fileName = shift @files;

		next if $fileName =~ /^PG\.pl$/;         # The PG.pl macro package is already loaded.

		# Only parse files with macro extensions.
		unless ($fileName =~ /\.(pl|pg)$/) {
			warn "Can't load file |$fileName|. Can't load a macro file unless it has a .pl or .pg extension";
			next;
		}

		# Remove the extension. Sometimes the extension is .pg
		my $macro_file_name = $fileName =~ s/\.p[lg]//r;

		my $init_subroutine_name = "_${macro_file_name}_init";
		$init_subroutine_name =~ s![^a-zA-Z0-9_]!_!g;    # Remove dangerous characters.

		my $init_subroutine = eval { \&{ 'main::' . $init_subroutine_name } };

		my $macro_file_loaded = defined $init_subroutine && defined &$init_subroutine;
		warn "PGloadfiles: macro init $init_subroutine_name defined |$init_subroutine| |$macro_file_loaded|"
			if $debugON;

		unless ($macro_file_loaded) {
			warn "loadMacros: loading macro file $fileName" if $debugON;
			my $filePath = $self->findMacroFile($fileName);
			warn "loadMacros: look for $fileName at |$filePath|" if $debugON;

			if ($filePath) {
				$self->compile_file($filePath);
				warn "loadMacros is compiling $filePath" if $debugON;
			} else {
				warn qq{Can't locate macro file "$fileName" via path: "}
					. join(qq{",\n"},
					map { $_ =~ s|^$self->{envir}{templateDirectory}|[TMPL]/|r }
					map { $_ =~ s|^$self->{envir}{pgMacrosDir}|[PG]/macros|r } @$macrosPath) . qq{"\n};
			}

			$init_subroutine = eval { \&{ 'main::' . $init_subroutine_name } };

			$macro_file_loaded = defined $init_subroutine && defined &$init_subroutine;
			warn "PGloadfiles: macro init $init_subroutine_name defined |$init_subroutine| |$macro_file_loaded|"
				if $debugON;

			if ($macro_file_loaded) {
				warn "PGloadfiles:  $macro_file_name loaded, initializing $macro_file_name\n" if $debugON;
				$init_subroutine->();
			}
		}
	}

	return;
}

sub findMacroFile {
	my ($self, $macroFileName) = @_;
	for my $dir (@{ $self->{envir}{macrosPath} }) {
		my $macroFilePath = "$dir/$macroFileName" =~ s!^\.\.?/!$self->{pwd}/!r;
		return $macroFilePath if -r $macroFilePath;
	}
	return 0;
}

sub compile_file {
	my ($self, $filePath) = @_;

	# Only allow compilation of files that are in the macros path.
	my @allowedDirs = map { $_ eq '.' ? $WeBWorK::PG::IO::pwd : $_ } @{ $WeBWorK::PG::IO::macrosPath // [] };
	die "Refusing to compile $filePath as it is not located in an allowed location.\n"
		unless grep { WeBWorK::PG::IO::path_is_subdir($filePath, $_) } @allowedDirs;

	warn "loading $filePath" if $debugON;

	local $/ = undef;
	open(my $MACROFILE, "<:raw", $filePath) or die "Cannot open file: $filePath";
	my $contents = <$MACROFILE>;
	close $MACROFILE;
	$contents = decode('UTF-8', $contents);

	my ($result, $error, $fullerror) = WeBWorK::PG::Translator::PG_macro_file_eval($contents, $filePath);

	if ($error) {
		# The $fullerror report has formatting and is never empty when there is an error.
		# The die message is handled by PG_errorMessage in the PG translator.
		die "Error detected while loading $filePath:\n$fullerror";
	}

	$self->{macroFileList}{$filePath} = 1;

	return;
}

1;

=head1 NAME

PGloadfiles.pm - Load and compile macro files.

=head2 new

Usage: C<< PGloadfiles->new($envir) >>

The C<PGloadfiles> constructor. The C<$envir> hash containing the problem
environment is required.

One C<PGloadfiles> object is created for each C<PGcore> object (which is unique
for each problem).  This object is used to load macros for a problem.

=head2 loadMacros

Usage: C<< $pgLoadfiles->loadMacros(@macroFiles) >>

This method takes a list of file names C<@macroFiles> and evaluates the contents
of each file.  This is used to load macros which define and augment the PG
language. The macro files are searched for in the directories specified by the
array referenced by C<< $envir->{macrosPath} >>, which by default includes the
directory containing the current problem file, followed by the course's macros
directory and all of WeBWorK's pg/macros directories.

Note that a problem should call the C<loadMacros> method defined in L<PG.pl>
which calls this method via the unique C<PGloadfiles> object of the unique
C<PGcore> object for the problem.

=head3 Overloading macro files

An individual course can modify the PG language, for that course only, by
duplicating one of the macro files in the system-wide macros directory and
placing this file in the macros directory for the course. The new file in the
course's macros directory will now be used instead of the file in the
system-wide macros directory.

The new file in the course macros directory can by modified by adding macros or
modifying existing macros.

=head3 Modifying existing macros

I<Modifying macros is for users with some experience.>

Modifying existing macros might break other standard macros or problems which
depend on the unmodified behavior of these macros so do this with great caution.
In addition problems which use new macros defined in these files or which depend
on the modified behavior of existing macros will not work in other courses
unless the macros are also transferred to the new course.  It helps to document
the problems by indicating any special macros which the problems require.

There is no facility for modifying or overloading a single macro. The entire
file containing the macro must be overloaded.

Modifications to files in the course macros directory affect only that course,
they will not interfere with the normal behavior of WeBWorK in other courses.

=head2 findMacroFile

Usage: C<< $pgLoadfiles->findMacroFile($fileName) >>

Searches for the C<$fileName> in the directories listed in the array referenced
by C<< $envir->{macrosPath} >>. It returns the full file path of the file in the
first directory in that list that it is found in.

=head2 compile_file

Usage C<< $pgLoadfiles->compile_file($filePath) >>

Reads the file C<$filePath> and compiles it. Note that this is an internal
method, and should never be called outside of this file.

=cut
