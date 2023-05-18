<div class="offcanvas-header">
	<h2 class="offcanvas-title fs-3" id="sidebar-label">Subject Areas</h2>
	<button type="button" class="btn-close" data-bs-dismiss="offcanvas"
		data-bs-target="#sidebar" aria-label="Close">
	</button>
</div>

<h2 class="fs-3 d-none d-md-block px-3 pt-3">Subject Areas</h2>
<div class="offcanvas-body px-md-3 pb-md-3 w-100">
	<div class="list-group w-100" role="tablist" id="sidebar-list">
		% for (sort(keys %$subjects)) {
			% my $id = $_ =~ s/\s/_/gr;
			<a class="list-group-item list-group-item-action" id="<%= $id %>-tab" href="#<%= $id %>"
				data-bs-toggle="list" role="tab" aria-controls="<%= $id %>">
				<%= $_ %>
			</a>
		% }
	</div>
</div>
