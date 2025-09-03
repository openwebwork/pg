<!DOCTYPE html>
<html lang="en">

<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title><%= $filename %></title>
	<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.7/dist/css/bootstrap.min.css" rel="stylesheet">
	<link href="https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@7.0.0/css/all.min.css" rel="stylesheet">
	<link rel="stylesheet" href="<%= $sample_problem_base_url %>/sample-problem.css">
	<script
		src="https://cdn.jsdelivr.net/npm/@openwebwork/pg-codemirror-editor@0.0.5/dist/pg-codemirror-editor.js"
		defer></script>
</head>

% # Default explanations
% my $default = {
	% preamble  => 'These standard macros need to be loaded.',
	% setup     => 'This perl code sets up the problem.',
	% statement => 'This is the problem statement in PGML.',
	% answer    => 'This is used for answer checking.',
	% solution  => 'A solution should be provided here.'
% };

<body>
	<div class="container-fluid p-3">
		<div class="row">
			<div class="col">
				<h1><%= $name %></h1>
				<p><%= $description %></p>
			</div>
			<div class="col text-end">
				<a href="<%= $sample_problem_base_url =%>/../">Return to the PG documentation home</a>
			</div>
		</div>
		<div class="row">
			<div class="col">
				<h2>Complete Code</h2>
				<p>Download file: <a href="<%= $filename =%>"><%= $filename =%></a></p>
			</div>
			% if (scalar(@{$metadata->{$filename}{macros}}) > 0 ) {
				<div class="col">
					<h2>POD for Macro Files</h2>
					<ul>
						% for my $macro (@{$metadata->{$filename}{macros}}) {
							% if ($macro_locations->{$macro}) {
								<li>
									<a href="<%= $pod_base_url %>/<%= $macro_locations->{$macro} %>"><%= $macro =%></a>
								</li>
							% } else {
								<li class="text-danger"><%= $macro %></li>
							% }
						% }
					</ul>
				</div>
				% }
			% if ($metadata->{$filename}{related} && scalar(@{$metadata->{$filename}{related}}) > 0) {
			<div class="col">
				<h2>See Also</h2>
				<ul>
					% for (@{$metadata->{$filename}{related}}) {
					<li>
						<a href="<%= $sample_problem_base_url =%>/<%= $metadata->{$_}{dir} =%>/<%= $_ =~ s/.pg$//r =%>.html">
							<%= $metadata->{$_}{name} =%>
						</a>
					</li>
					% }
				</ul>
			</div>
			% }
		</div>
		<div class="row">
			<div class="col text-center"><h2 class="fw-bold fs-3">PG problem file</h2></div>
			<div class="col text-center"><h2 class="fw-bold fs-3">Explanation</h2></div>
		</div>
		% for (@$blocks) {
			<div class="row">
				<div class="col-sm-12 col-md-6 order-md-first order-last p-0 position-relative overflow-x-hidden">
					<button class="clipboard-btn btn btn-sm btn-secondary position-absolute top-0 end-0 me-1 mt-1 z-1"
						type="button" data-code="<%== $_->{code} %>" aria-label="copy to clipboard">
						<i class="fa-regular fa-clipboard fa-xl"></i>
					</button>
					<pre class="PGCodeMirror m-0 h-100 p-3 border border-secondary overflow-x-scroll"><%== $_->{code} %></pre>
				</div>
				<div class="explanation <%= $_->{section} %> col-sm-12 col-md-6 order-md-last order-first p-3 border border-dark">
					<p><b><%= ucfirst($_->{section}) %></b></p>
					% if ($_->{doc}) {
						<%= $_->{doc} %>
					% } else {
						<%= $default->{$_->{section}} %>
					% }
				</div>
			</div>
		% }
	</div>

	<script type="module">
		for (const pre of document.body.querySelectorAll('pre.PGCodeMirror')) {
			PGCodeMirrorEditor.runMode(pre.textContent, pre);
		}

		for (const btn of document.querySelectorAll('.clipboard-btn')) {
			if (navigator.clipboard)
				btn.addEventListener('click', () => navigator.clipboard.writeText(btn.dataset.code));
			else btn?.remove();
		}
	</script>
</body>

</html>
