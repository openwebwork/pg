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
		#sidebar {
			--bs-offcanvas-width: 250px;
		}
		@media only screen and (min-width: 768px) {
			#sidebar {
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

			<ul class="nav nav-pills nav-fill">
				<li class="nav-item">
					<a class="nav-link" href="categories.html">Sample Problems</a>
				</li>
				<li class="nav-item">
					<a class="nav-link" href="techniques.html">Problem Techniques</a>
				</li>
				<li class="nav-item dropdown">
					<a class="nav-link" href="subjects.html">Subject Area Problems</a>
				</li>
			</ul>

			<button class="navbar-toggler d-md-none" type="button" data-bs-toggle="offcanvas"
				data-bs-target="#sidebar" aria-controls="sidebar" aria-label="Toggle Sidebar">
				<span class="navbar-toggler-icon"></span>
			</button>
		</div>
	</nav>
	<div class="d-flex">
		<div class="offcanvas-md offcanvas-start overflow-y-auto border-end border-dark" tabindex="-1" id="sidebar"
			aria-labelledby="sidebar-label">
				<%= $sidebar %>
		</div>
		<div class="main-content">
			<div class="tab-content p-3">
				<%= $main_content %>
			</div>
		</div>
	</div>
	<script type="module">
		const offcanvas = bootstrap.Offcanvas.getOrCreateInstance(document.getElementById('sidebar'));
		for (const link of document.querySelectorAll('.nav .nav-item .nav-link')) {
			link.addEventListener('click', () => offcanvas.hide());
		}
		// Set the link active in the header bar.
		const page = location.href.split('/').at(-1);
		var els = document.querySelectorAll(`a[href='${page}']`);
		els[0].classList.add('active');
	</script>
</body>

</html>
