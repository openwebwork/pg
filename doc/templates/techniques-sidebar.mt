<div class="offcanvas-header">
	<h2 class="offcanvas-title fs-3" id="categories-label">Problem Techniques</h2>
	<button type="button" class="btn-close" data-bs-dismiss="offcanvas"
		data-bs-target="#techniques" aria-label="Close">
	</button>
</div>

<h2 class="fs-3 d-none d-md-block px-3 pt-3">Problem Techniques</h2>
<div class="offcanvas-body px-md-3 pb-md-3">
	% my $alpha = [ ['A'..'C'],['D'..'F'],['G'..'Z']];
	<ul class="nav nav-pills flex-column" role="tablist" aria-orientation="vertical">
		% for (@$alpha) {
		<li class="nav-item">
				<a class="nav-link px-3 py-1" id="<%= $_->[0] %>-tab" href="#" data-bs-toggle="pill"
					data-bs-target="#<%= $_->[0] %>" role="tab"
					aria-controls="<%= $_->[0] %>" aria-selected="false">
					<%= $_->[0] %> .. <%= $_->[scalar(@$_)-1] %>
				</a>
			</li>
		% }
	</ul>
</div>