<!DOCTYPE html>
<html lang="en">

<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title>PG Sample Problems</title>
	<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha3/dist/css/bootstrap.min.css" rel="stylesheet">
	<style>
		.navbar {
			height: 70px;
		}
		body {
			margin-top: 70px;
		}
		#categories {
			--bs-offcanvas-width: 250px;
		}
		@media only screen and (min-width: 768px) {
			#categories {
				height: calc(100vh - 70px);
			}
		}
	</style>
	<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha3/dist/js/bootstrap.min.js" defer></script>
</head>

<body>
	<nav class="navbar fixed-top bg-primary border-bottom border-dark" data-bs-theme="dark">
		<div class="container-fluid">
			<h1 class="navbar-brand fs-3 m-0 p-0">PG Sample Problems</h1>
			<button class="navbar-toggler d-md-none" type="button" data-bs-toggle="offcanvas"
				data-bs-target="#categories" aria-controls="categories" aria-label="Toggle categories">
				<span class="navbar-toggler-icon"></span>
			</button>
		</div>
	</nav>
	<div class="d-flex">
		<div class="offcanvas-md offcanvas-start overflow-y-auto border-end border-dark" tabindex="-1" id="categories"
			aria-labelledby="categories-label">
			<div class="offcanvas-header">
				<h2 class="offcanvas-title fs-3" id="categories-label">Categories</h2>
				<button type="button" class="btn-close" data-bs-dismiss="offcanvas"
					data-bs-target="#categories" aria-label="Close">
				</button>
			</div>
			<h2 class="fs-3 d-none d-md-block px-3 pt-3">Categories</h2>
			<div class="offcanvas-body px-md-3 pb-md-3">
				<ul class="nav nav-pills flex-column" role="tablist" aria-orientation="vertical">
					% for (sort(keys %$categories)) {
						% my $id = $_ =~ s/\s/_/gr;
						<li class="nav-item">
							<a class="nav-link px-3" id="<%= $id %>-tab" href="#" data-bs-toggle="pill"
								data-bs-target="#<%= $id %>" role="tab"
								aria-controls="<%= $id %>" aria-selected="false">
								<%= $_ %>
							</a>
						</li>
					% }
				</ul>
			</div>
		</div>
		<div class="main-content">
			<div class="tab-content p-3">
				% for (sort(keys %$categories)) {
					% my $id = $_ =~ s/\s/_/gr;
					<div class="tab-pane fade" id="<%= $id %>" role="tabpanel" aria-labelledby="<%= $id %>-tab"
						tabindex="0">
						<h2 class="fs-3">Sample Problems for Category: <%= $_ %></h2>
						<ul>
							% for my $link (sort @{ $categories->{$_} }) {
								<li><a href="<%= $link %>"><%= $link %></a></li>
							% }
						</ul>
					</div>
				% }
			</div>
		</div>
	</div>
	<script type="module">
		const offcanvas = bootstrap.Offcanvas.getOrCreateInstance(document.getElementById('categories'));
		for (const link of document.querySelectorAll('.nav .nav-item .nav-link')) {
			link.addEventListener('click', () => offcanvas.hide());
		}
	</script>
</body>

</html>
