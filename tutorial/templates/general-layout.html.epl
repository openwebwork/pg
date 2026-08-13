<!DOCTYPE html>
<html lang="en">

<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title>PG Sample Problems</title>
	<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.7/dist/css/bootstrap.min.css" rel="stylesheet">
	<style>
		.navbar {
			height: 70px;
		}
		.main-content {
			margin-top: 70px;
		}
		#sidebar {
			--bs-offcanvas-width: 320px;
		}
		@media only screen and (min-width: 768px) {
			#sidebar {
				width: 320px;
				height: calc(100vh - 70px);
			}
			.main-content {
				margin-left: 320px;
			}
		}
	</style>
	<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.7/dist/js/bootstrap.bundle.min.js" defer></script>
</head>

<body>
	<nav class="navbar fixed-top bg-primary border-bottom border-dark" data-bs-theme="dark">
		<div class="container-fluid">
			<ul class="nav nav-pills">
				<li class="nav-item dropdown">
					<a class="nav-link fs-3 dropdown-toggle active" href="#" role="button"
						data-bs-toggle="dropdown" aria-expanded="false">
						<%= $active eq 'categories' ? 'Sample Problems'
							: $active eq 'techniques' ? 'Problem Techniques'
							: $active eq 'subjects' ? 'Subject Area Problems'
							: 'Problems by Macro' =%>
					</a>
					<ul class="dropdown-menu">
						<li>
							<a class="dropdown-item <%= $active eq 'categories' ? 'active' : '' %>"
								href="categories.html" <%= $active eq 'categories' ? 'aria-current="page"' : '' %>>
								Sample Problems
							</a>
						</li>
						<li>
							<a class="dropdown-item <%= $active eq 'techniques' ? 'active' : '' %>"
								href="techniques.html" <%= $active eq 'techniques' ? 'aria-current="page"' : '' %>>
								Problem Techniques
							</a>
						</li>
						<li>
							<a class="dropdown-item <%= $active eq 'subjects' ? 'active' : '' %>"
								href="subjects.html" <%= $active eq 'subjects' ? 'aria-current="page"' : '' %>>
								Subject Area Problems
							</a>
						</li>
						<li>
							<a class="dropdown-item <%= $active eq 'macros' ? 'active' : '' %>"
								href="macros.html" <%= $active eq 'macros' ? 'aria-current="page"' : '' %>>
								Problems by Macro
							</a>
						</li>
					</ul>
				</li>
			</ul>
			<button class="navbar-toggler d-md-none" type="button" data-bs-toggle="offcanvas"
				data-bs-target="#sidebar" aria-controls="sidebar" aria-label="Toggle Sidebar">
				<span class="navbar-toggler-icon"></span>
			</button>
		</div>
	</nav>
	<aside class="offcanvas-md offcanvas-start overflow-y-auto position-fixed border-end border-dark flex-shrink-0"
		tabindex="-1" id="sidebar" aria-labelledby="sidebar-label">
		<%= $sidebar %>
	</aside>
	<div class="main-content">
		<div class="tab-content p-3">
			<%= $main_content %>
		</div>
	</div>
	<script type="module">
		const offcanvas = bootstrap.Offcanvas.getOrCreateInstance(document.getElementById('sidebar'));
		for (const link of document.querySelectorAll('#sidebar-list .list-group-item-action')) {
			link.addEventListener('click', () => offcanvas.hide());
		}
	</script>
</body>

</html>
