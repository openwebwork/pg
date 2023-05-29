% my $alpha = [ ['A'..'C'],['D'..'F'],['G'..'Z']];
% for (@$alpha) {
	<div class="tab-pane fade" id="<%= $_->[0] %>" role="tabpanel" aria-labelledby="<%= $_->[0] %>-tab"
		tabindex="0">
		<h2 class="fs-3">Sample Problems for Techniques: <%= $_->[0] %> .. <%= $_->[scalar(@$_)-1] %></h2>
		<ul>
			% my $b = join('',@$_);
			% my @probs = grep { substr($_, 0, 1 ) =~ qr/^[$b]/i } keys(%$techniques);
			% for (sort @probs) {
			<li><a href="<%=$techniques->{$_} =%>"><%= $_ =%></a></li>
			% }
		</ul>
	</div>
% }