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


=head3   sourceButton

activating the source button

In order for this button to work the course needs to have a link from 

	myCourse/html/show-source.cgi to webwork2/htdocs/show-source.cgi

in the directory myCourse/html.  To create this link execute the following
command (you will need command line access to the server to do this)

	ln -s /opt/webwork/webwork2/htdocs/show-source.cgi    show-source.cgi
 
You need to make sure that the file webwork2/htdocs/show-source.cgi is executable by the 
apache webserver.  

To accomplish this you need to uncomment this line in webwork.apache2-config

	ScriptAliasMatch /webwork2_course_files/([^/]*)/show-source.cgi/(.*) /opt/webwork/courses/$1/html/show-source.cgi/$2

The show-source.cgi script may also have to be customized to set C<$root> to the webwork2 directory

=cut

1;
