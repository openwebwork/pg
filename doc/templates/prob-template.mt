<html>
	<head>
		<style>
			body {
				padding: 20px;
			}
			.code {
				border: 1px gray dashed;
				background-color: #2a3b4d;
				overflow-x: scroll;
			}
			.explanation {
				border: 1px black solid;
			}
			.preamble {
				background-color: lightblue;
			}
			.setup {
				background-color: #ddffdd;
			}
			.statement {
				background-color: #eeb081;
			}
			.answer {
				background-color: #ffffdd;
			}
			.solution {
				background-color: lightpink;
			}
			.header {
				font: 125% bold;
			}
		</style>
		<script>
			document.addEventListener('DOMContentLoaded', () => {
				const code_elems = document.getElementsByClassName("code");
				for (const el of code_elems) {
					const b = el.getElementsByTagName('button');
					const code = el.getElementsByClassName('hidden-code');
					b[0].addEventListener('click', () => {
						navigator.clipboard.writeText(code[0].textContent);
					})
				}
			});
		</script>
	</head>

<div class="container">
	<div class="row pb-3">
		<h1><%= $filename =~ s/\.pg//r %></h1>
	</div>
	<div class="row pb-3">
		<div class="col">
		<%= $description %>
		</div>
		<div class="col">
			<h2>POD for macro files</h2>
			<ul>
			<% for my $macro (@$macros) {
				if ($macro_loc->{$macro}) {
				%>
					<li><a href="<%=$pod_dir%>/<%=$macro_loc->{$macro}%>"><%= $macro =%></a></li>
				<% } else { %>
					<li style="color: red"><%= $macro %></li>
			<% }} %>
			</ul>
		</div>
	</div>
	<div class="row">
		<div class="col header">
			PG problem file
		</div>
		<div class="col header">
			Explanation
		</div>
	</div>
	<% for my $b (@$blocks) { %>
		<div class="row">
			<div class="col code p-0">
				<button class="float-end" type="button" class="btn btn-sm btn-light">
					<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-clipboard" viewBox="0 0 16 16">
						<path d="M4 1.5H3a2 2 0 0 0-2 2V14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V3.5a2 2 0 0 0-2-2h-1v1h1a1 1 0 0 1 1 1V14a1 1 0 0 1-1 1H3a1 1 0 0 1-1-1V3.5a1 1 0 0 1 1-1h1v-1z"/>
						<path d="M9.5 1a.5.5 0 0 1 .5.5v1a.5.5 0 0 1-.5.5h-3a.5.5 0 0 1-.5-.5v-1a.5.5 0 0 1 .5-.5h3zm-3-1A1.5 1.5 0 0 0 5 1.5v1A1.5 1.5 0 0 0 6.5 4h3A1.5 1.5 0 0 0 11 2.5v-1A1.5 1.5 0 0 0 9.5 0h-3z"/>
					</svg>
				</button>
				<pre><code class="language-perl"><%= $b->{code} %></code></pre>
				<div class="hidden-code" style="display: none"> <%= $b->{code} %></div>
			</div>
			<div class="col <%= $b->{section} %> explanation">
				<p><b><%= ucfirst($b->{section}) %></b></p>
				<%= $b->{doc} %>
			</div>
		</div>
	<% } %>
</div>

<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-KK94CHFLLe+nY2dmCWGMq91rCGa5gtU4mk92HdvYe+M/SXH301p5ILy+dN9+nJOZ" crossorigin="anonymous">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.7.0/styles/base16/eva.min.css">
<script type="module">
import hljs from 'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.7.0/es/highlight.min.js';
//  and it's easy to individually load additional languages
//import go from 'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.7.0/es/languages/go.min.js';
//hljs.registerLanguage('go', go);
hljs.highlightAll();
</script>

</html>