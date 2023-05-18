% for (sort(keys %$subjects)) {
	% my $id = $_ =~ s/\s/_/gr;
	<div class="tab-pane fade" id="<%= $id %>" role="tabpanel" aria-labelledby="<%= $id %>-tab"
		tabindex="0">
		<h1 class="fs-3">Sample Problems for Subject Area: <%= $_ %></h1>
		<ul>
			% for my $link (sort (keys %{$subjects->{$_}})) {
				<li><a href="<%= $subjects->{$_}{$link} =%>"><%= $link %></a></li>
			% }
		</ul>
	</div>
% }
