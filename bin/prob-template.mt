<html>
	<head>
		<style>
			.code {
				border: 1px black dashed;
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
				background-color: #ccffcc;
			}
			.answer {
				background-color: #ffffdd;
			}
			.solution {
				background-color: lightpink;
			}
		</style>
	</head>

<% my $colors = {
	preamble => '#f9f9f9',
	setup => '#ddffdd',
	statement => '#ccffcc',
	answer => '#ffffdd',
	solution => '#ffffcc'
};
%>

<table cellspacing="0" cellpadding="2" border="0">
	<thead>
		<tr valign="top">
			<th width="50%"> PG problem file </th>
			<th width="50%"> Explanation </th>
		</tr>
	</thead>
<tbody>
	<% for my $b (@$blocks) { %>
		<tr valign="top">
			<td class="code">
				<pre><%= $code->{$b} %></pre>
			</td>
			<td class="<%= $b %> explanation">
			<p><b><%= ucfirst($b) %></b></p>
				<%= $doc->{$b} %>
			</td>
		</tr>
		<% } %>
</tbody>
</table>
</html>