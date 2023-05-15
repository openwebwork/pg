<h3>Sample Problems for Category: <%= $cat %></h3>
<ul>
	<% for my $link (@$links) {
		my ($name) = $link =~ m/(\w+).pg.html/;
		%>

		<li> <a href="../<%= $link %>"><%= $name %></a></li>
	<% } %>
</ul>
