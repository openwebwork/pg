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
				<a class="nav-link px-3 py-1" id="<%= $id %>-tab" href="#" data-bs-toggle="pill"
					data-bs-target="#<%= $id %>" role="tab"
					aria-controls="<%= $id %>" aria-selected="false">
					<%= $_ %>
				</a>
			</li>
		% }
	</ul>
</div>
