#!/usr/bin/perl -w 

###################################
# quick matrix entry package
###################################


sub INITIALIZE_QUICK_MATRIX_ENTRY {
	main::HEADER_TEXT($quick_entry_javascript);
	main::TEXT($quick_entry_form);
	return '';
}

# <input class="opener" type='button' name="AnSwEr0002" value="Quick Entry"
#  rows=5 columns=9>
sub MATRIX_ENTRY_BUTTON {
	my ($answer_number,$rows,$columns) = @_;
	$rows=$rows//1;
	$columns=$columns//5;
	my $answer_name = "AnSwEr".sprintf('%04d',$answer_number);
	return qq!
	$PAR
		<input class="opener" type='button' name="$answer_name" value="Quick Entry" 
		rows="$rows" columns="$columns">
	$PAR!;
}

our $quick_entry_javascript = <<'END_JS';
<script type="text/javascript">
$(function() {        
        $( "#quick_entry_form" ).dialog({
            autoOpen: false,  
            });
        //console.log('startup');
        var name = $("#quick_entry_form").attr("name");
        //console.log("name is " + name );
        var insert_value = function(name, i,j,entry) {
			var pos = "#MaTrIx_"+name+"_"+i+"_"+j;
			if (i==0 && j==0 ) {
				pos= "#"+name;
			}  //MaTrIx_AnSwEr0007_0_3
			//console.log($(pos).val());
			$(pos).val(entry); //instead of 4000
		}
    $( ".opener" ).click(function() {
         //console.log(this.name );
         name = this.name;
         rows = $(this).attr("rows");
         columns = $(this).attr("columns");
         //console.log("cols = " + columns);
         // enter something that indicates how many columns to fill
         entry = '';
         for(i=1;i<=columns;i++) {entry = entry + i+' ';}
         //console.log("entry " + entry);
         $("textarea#matrix_input").val(entry);
         $( "#quick_entry_form" ).dialog( "open" );
      
    });
    $( "#closer" ).click(function() {
        //var name="AnSwEr0007";
        var mat2=$("textarea#matrix_input").val().split(/\n/);
        //var mat2=mat.split(/\n/);
        var mat3=[];
        for (i=0; i<mat2.length; i++) {
            mat3.push( mat2[i].split(/\s+/) );
        }
        for (i=0; i<mat3.length; i++) {
            for(j=0; j<mat3[i].length; j++){
                insert_value(name,i,j,mat3[i][j]);
            }		
        }
        $( "#quick_entry_form" ).dialog( "close" );
      });
});
</script>
END_JS

our $quick_entry_form = <<'END_TEXT';
<div id="quick_entry_form" name="quick entry" title="Enter matrix">
  <textarea id="matrix_input" rows="5" columns = "10"> 
  </textarea>
  <button id="closer">enter</button>
</div>
END_TEXT