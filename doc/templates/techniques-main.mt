% for (['A' .. 'C'], ['D' .. 'F'], ['G' .. 'Z']) {
	<div class="tab-pane fade" id="<%= $_->[0] %>" role="tabpanel" aria-labelledby="<%= $_->[0] %>-tab" tabindex="0">
		<h1 class="fs-3">Sample Problems for Techniques: <%= $_->[0] %> .. <%= $_->[-1] %></h1>
		<ul>
			% my $b = join('', @$_);
			% for (sort grep { substr($_, 0, 1 ) =~ qr/^[$b]/i } keys(%$techniques)) {
				<li><a href="<%= $techniques->{$_} =%>"><%= $_ =%></a></li>
			% }
		</ul>
	</div>
% }
