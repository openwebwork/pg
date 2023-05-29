% for (sort(keys %$categories)) {
	% my $id = $_ =~ s/\s/_/gr;
	<div class="tab-pane fade" id="<%= $id %>" role="tabpanel" aria-labelledby="<%= $id %>-tab"
		tabindex="0">
		<h2 class="fs-3">Sample Problems for Category: <%= $_ %></h2>
		<ul>
			% for my $link (sort (keys %{$categories->{$_}})) {
				<li><a href="<%= $categories->{$_}{$link} =%>"><%= $link %></a></li>
			% }
		</ul>
	</div>
% }