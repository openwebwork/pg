<html>
<head>
<style>
 body { padding: 25px;}
 </style>
 </head>
<div class="container">
  <div class="row">
    <div class="col">
			<h3>Categories</h3>
    <ul>
      <% for my $cat (sort(keys %$categories)) {
        my $link = $cat =~ s/\s/_/rg;
        %>

      <li> <a href="<%=$link%>.html"><%= $cat %></a> </li>
		<% } %>
		</ul>
    </div>
    <div class="col">
      <%= $content %>
    </div>
	</div>
</div>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-KK94CHFLLe+nY2dmCWGMq91rCGa5gtU4mk92HdvYe+M/SXH301p5ILy+dN9+nJOZ" crossorigin="anonymous">
</html>
