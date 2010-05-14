if ($displayMode =~ m/HTML/ && !defined($_slides_loaded)) {
  TEXT(
     '<DIV ID="source_button" STYLE="float:right; margin-right:2em">'
    .  '<SCRIPT>function showSource () {'
    .  '  window.open("'.$htmlURL."show-source.cgi/$probFileName".'","ww_source");'
    .  '}</SCRIPT>'
    .  '<INPUT TYPE="button" VALUE="Show Problem Source" ONCLICK="showSource()">'
    .'</DIV>'
  );
}

sub NoSourceButton {
#  if ($displayMode =~ m/HTML/) {
#    TEXT('<SCRIPT>document.getElementById("source_button").style.display = "none"</SCRIPT>');
#  }
}

1;
