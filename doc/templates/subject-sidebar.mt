<div class="offcanvas-header">
				<h2 class="offcanvas-title fs-3" id="categories-label">Subject Areas</h2>
				<button type="button" class="btn-close" data-bs-dismiss="offcanvas"
					data-bs-target="#subjects" aria-label="Close">
				</button>
			</div>

<h2 class="fs-3 d-none d-md-block px-3 pt-3">Subject Areas</h2>
<div class="offcanvas-body px-md-3 pb-md-3">
	<ul class="nav nav-pills flex-column" role="tablist" aria-orientation="vertical">
		% for (sort(keys %$subjects)) {
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
