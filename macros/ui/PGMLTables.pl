sub _PGMLTables_init {
	main::PG_restricted_eval('sub PGMLTable { PGMLTables::PGMLTable(@_) }');
}

loadMacros('PGML.pl');

package PGMLTables;

sub wrapTeX { return '[`' . shift . '`]' }

sub arrayString {
	my $array = shift;
	for (@$array) {s/'/\\'/g}
	return "['" . join("','", @$array) . "']";
}

sub PGMLopts {
	my $opts = shift;
	for (keys %$opts) {
		if (ref($opts->{$_}) eq 'ARRAY') {
			$opts->{$_} = arrayString($opts->{$_});
		} else {
			$opts->{$_} =~ s/'/\\'/g;
			$opts->{$_} = "'$opts->{$_}'";
		}
	}
	return '{' . join(', ', map {"$_ => $opts->{$_}"} keys %$opts) . '}';
}

sub wrapCell {
	my $cell = shift;
	my $opts;
	if (ref $cell eq 'ARRAY') {
		my $data = shift @$cell;
		$opts = {@$cell};
		$cell = $data;
	}
	my $string = "[.$cell.]";
	$string .= PGMLopts($opts) if $opts;
	return $string;
}

sub convertRow {
	my $row = shift;
	return join('', map { wrapCell($_) } @$row) . '* ';
}

sub PGMLTable {
	my $rows  = shift;
	my %opts  = @_;
	my $table = '[#' . join(' ', map { convertRow($_) } @$rows) . '#]';
	if ($opts{layout}) {
		$table .= '*';
		delete $opts{layout};
	}
	$table .= PGMLopts(\%opts) if %opts;
	return $table;
}

