BEGIN {
	be_strict();
}

package Chromatic;

our $webwork_directory = $WeBWorK::Constants::WEBWORK_DIRECTORY; #'/opt/webwork/webwork2';
our $seed_ce = new WeBWorK::CourseEnvironment({ webwork_dir => $webwork_directory });
die "Can't create seed course environment for webwork in $webwork_directory" unless ref($seed_ce);
our $PGdirectory = $seed_ce->{pg_dir};
our $command = "$PGdirectory/lib/chromatic/color";
our $compileCommand = "/usr/bin/gcc -O3 -o $PGdirectory/lib/chromatic/color $PGdirectory/lib/chromatic/color.c";
unless (-x $command) {
	if (-w "$PGdirectory/lib/chromatic" and -r "$PGdirectory/lib/chromatic/color.c" and -x "/usr/bin/gcc") {
    # compile color if it is not there
     system $compileCommand;
  	} else {
    	warn "ERROR: Unable to compile $PGdirectory/lib/chromatic/color.c.";
    	warn "The command $compileCommand failed";
    	warn "Chromatic.pm and a compiled version of color.c are required for this problem";
    	warn "The file color.c will need to be compiled by a systems administrator.";
    	warn "Can't find compiler at /usr/bin/gcc" unless -x '/usr/bin/gcc';
    	warn "Can't write into directory $PGdirectory/lib/chromatic" unless  -w "$PGdirectory/lib/chromatic";
    	warn "Can't read C file $PGdirectory/lib/chromatic/color.c" unless -r "$PGdirectory/lib/chromatic/color.c";
    }
}
our $tempDirectory = $seed_ce->{webworkDirs}->{DATA};
use UUID::Tiny  ':std';

sub matrix_graph {
    my ($graph) = @_;
    $graph =~ s/\A\s*//;
    $graph =~ s/;\s*\Z//;

    my (@m, $size, $i, $j, @r, @matrix);
    @m=split /\s*[;]\s*/ , $graph;
    $size=scalar @m;
    @matrix=();
    for ($i=0; $i<$size ; $i++) {
      @r=split /\s+/, $m[$i];
      for ($j=0; $j<$size;$j++) {
        $matrix[$i][$j]=$r[$j];
      }
    }
    @matrix;
}
sub ChromNum {
  my ($graph) = @_;
  my ($i, $j, @adj, $val, $size, $count, @edges,  $ctime, $fh, $fname);
  my $unique_id_seed = time;
  my $unique_id_stub = create_uuid_as_string(UUID_V3, UUID_NS_URL, $unique_id_seed);
  my $fileout = "$tempDirectory/$unique_id_stub";
	unless (-x $command) {
	
		die "Can't execute $command to calculate chromatic color";
	} 

  @adj = matrix_graph($graph);
  $count = 0;
  $size = scalar @adj;

  for ($i = 0; $i < $size; $i++){
    for ($j = $i + 1; $j < $size; $j++){
      if ($adj[$i][$j] != 0){
        $count++;
        push @edges, $i + 1, $j + 1;
      }
    }
  }

# This is not quite good enough to avoid race conditions but it'll do.
  while (-e "$fileout") {
    sleep 1;
  }
  open OUT , ">$fileout";
  print OUT "$size $count\n";

  for ($i = 0; $i < scalar @edges; $i+=2){
    print OUT "$edges[$i] $edges[$i+1]\n";
  }
  close (OUT);

# This does not work, don't know why. It's probably unsecure anyway.
#  unless (-e '/opt/webwork/pg/lib/chromatic/color') {
#    `cd /opt/webwork/pg/lib/chromatic; gcc color.c -o color`;
#  }

  $val = qx[$command $fileout];

  $val =~  /value (\d+)/g;
  qx[rm $fileout];
  $1;
}

sub chn{
"Blah";
}
1;
