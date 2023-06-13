% for (sort(keys %$list)) {
	% my $id = $_ =~ s/\s/_/gr;
	<div class="tab-pane fade" id="<%= $id %>" role="tabpanel" aria-labelledby="<%= $id %>-tab"
		tabindex="0">
		<h1 class="fs-3">Sample Problems for <%=$label=%>: <%= $_ %></h1>
		<ul>
			% for my $link (sort (keys %{$list->{$_}})) {
				<li><a href="<%= $list->{$_}{$link} =%>"><%= $link %></a></li>
			% }
		</ul>
	</div>
% }
