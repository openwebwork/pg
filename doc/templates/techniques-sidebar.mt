<div class="offcanvas-header">
	<h2 class="offcanvas-title fs-3" id="sidebar-label">Problem Techniques</h2>
	<button type="button" class="btn-close" data-bs-dismiss="offcanvas"
		data-bs-target="#sidebar" aria-label="Close">
	</button>
</div>

<div class="offcanvas-body p-md-3 w-100">
	<div class="list-group w-100" role="tablist" id="sidebar-list">
	<a style="display: none" class="list-group-item list-group-item-action active" id="default-tab" href="#default"
			data-bs-toggle="list" role="tab" aria-controls="default">Default</a>
		% for (['A' .. 'C'], ['D' .. 'F'], ['G' .. 'Z']) {
			<a class="list-group-item list-group-item-action" id="<%= $_->[0] %>-tab" href="#<%= $_->[0] %>"
				data-bs-toggle="list" role="tab" aria-controls="<%= $_->[0] %>">
				<%= $_->[0] %> .. <%= $_->[-1] %>
			</a>
		% }
	</div>
</div>
