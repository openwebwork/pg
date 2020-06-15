################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2020 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/macros/GroupTableAnswer.pl,v 1.0 2020/06/09 23:28:44 paultpearson Exp $
# 
# This program is free software; you can redistribute it and/or modify it under
# the terms of either: (a) the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any later
# version, or (b) the "Artistic License" which comes with this package.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See either the GNU General Public License or the
# Artistic License for more details.
################################################################################

=head1 NAME

GroupTableAnswer.pl

=head1 DESCRIPTION

Provides a way to collect and grade multiplication (group or ring) tables.
An html table with editable table cells is used for answer entry.  When the
problem is submitted, JavaScript reads the table cells and assembles them
into the form of a comma separated list which written to a hidden html input, 
passed to the server, and graded as a MathObject ordered List.  When the problem 
reloads, JavaScript reads the previous answer from a hidden html input and fills
the html table cells.

=head1 USAGE

Load the macro file via C<loadMacros("GroupTableAnswer.pl")>.

Begin by adding some named constants to the context.  We use the Matrix context
here, but we could have used the Permutation context, or for an abelian
group we could even use the Numeric context.  We use parsed student
answers so that student answers are printed by name rather than value.
When we add constants to the context, we use prime multiples of the 
matrices to ensure that students must reduce their answers (because
C<A*A = 9*$A*$A> is not equal to C<I = 2*$I>, for instance).

        Context("Matrix");

        $I = Matrix([[1,0],[0,1]]);
        $A = Matrix([[0,1],[1,0]]);
        $B = Matrix([[0,1],[-1,-1]]);
        $C = Matrix([[-1,-1],[0,1]]);
        $D = Matrix([[-1,-1],[1,0]]);
        $K = Matrix([[1,0],[-1,-1]]);

        Context()->constants->are( I=>2*$I, A=>3*$A, B=>5*$B, C=>7*$C, D=>11*$D, K=>13*$K );
        Context()->operators->undefine("+","-","inverse");
        Context()->flags->set(
            formatStudentAnswer=>'parsed'
        );

        $grouptable = Compute("I,A,B,C,D,K,  A,I,C,B,K,D,   B,K,D,A,I,C,   C,D,K,I,A,B,   D,C,I,K,B,A,   K,B,A,D,C,I");

        BEGIN_PGML
        # Group table input

        Suppose [``I=[$I]``], [``A=[$A]``], [``B=[$B]``], [``C=[$C]``], [``D=[$D]``], [``K=[$K]``].  Complete the group table for the group defined by these six elements.

        [@ GroupTable('grouptable_1', 'Group table', '\circ', ['I','A','B','C','D','K'], ['I','A','B','C','D','K'], $grouptable) @]*
        END_PGML

The first argument C<'grouptable_1'> is a unique identifier that gets used in the
html source code.  If you have more than one group table in a problem, their
identifiers must be different.

The second argument C<'Group Table'> is a caption for the table and is needed
by people with visual impairments who use screen readers.

The third argument C<'\circ'> is a TeX-formatted string for the operation in the group.
If this string contains a backslash, be sure to enclose it in single quotes.

The fourth and fifth arguments C<['I','A','B','C','D','K']> are the row and column headers.

The sixth argument C<$grouptable> is a MathObject list of answers in row major format.

=head1 AUTHOR

Paul Pearson (Hope College Mathematics and Statistics Department)

=cut



sub _GroupTableAnswer_init { };    # don't reload this file

sub GroupTable {

    my $id = shift;
    my $caption = shift;
    my $operation_tex = shift; # use single quotes '\circ' for all inputs with backslash!
    my $row_headers_ref = shift;
    my $column_headers_ref = shift;
    my $ans = shift;    # a MathObject Matrix of answers

    $operation_html = $operation_tex; #copy
    $operation_html =~ s{\\}{\\\\}g; # replace single backslash with double backslash
    my @row_headers = @{$row_headers_ref};
    my @col_headers = @{$column_headers_ref};

    my $num_rows = scalar(@row_headers);
    my $num_cols = scalar(@col_headers);


    if ( $main::displayMode eq "TeX" ) {

        ###########
        # TeX table
        my $table_tex = '\begin{center} ' . $caption . '\end{center}';
        $table_tex .= '\begin{displaymath}\begin{array}{r|';
        $table_tex .=
            "c" x $num_cols . '} '
          . $operation_tex . ' & '
          . join( ' & ', @col_headers )
          . ' \\\\ \hline ';
        foreach my $elt (@row_headers) {
            $table_tex .= $elt . ' & ' x $num_rows . ' \\\\ ';
        }
        $table_tex .= '\end{array}\end{displaymath}';

        # insert the html hidden input and check the answer
        my $ans_id = 'AnSwEr_' . $id;
        TEXT( NAMED_HIDDEN_ANS_RULE($ans_id) );

        #main::NAMED_HIDDEN_ANS_RULE($ans_id);
        NAMED_ANS( $ans_id, $ans->cmp );

        return $table_tex;

    }
    else {    # HTML mode or other mode

        #############
        # HTML table
        my $table_html = qq(<div id="div_$id" class="grouptable"><table id="$id" border="1" style="margin: 20px auto">);
        $table_html .= qq(<caption>$caption</caption>);
        $table_html .= qq(<tr><th scope="col" style="width:50px; background-color:#E8E8E8">)
          . EV3("\\\\($operation_html\\\\)") . '</th>';
        foreach my $elt (@col_headers) {
            $table_html .=
              qq(<th scope="col" style="width:50px; background-color:#E8E8E8">)
              . EV3("\\\\($elt\\\\)") . '</th>';
        }
        $table_html .= "</tr>";
        foreach my $elt (@row_headers) {
            $table_html .= "<tr>"
              . qq(<th scope="row" style="width:50px; background-color:#E8E8E8; text-align:center">)
              . EV3("\\\\($elt\\\\)") . '</th>';
            $table_html .= qq(<td contenteditable='true' style="background-color:#FFFFFF; text-align:center"></td>)
              x $num_cols;
            $table_html .= "</tr>";
        }
        $table_html .= "</table></div>";

        #############
        # JavaScript answer processing
        my $js = qq(
        <script>
        document.addEventListener("DOMContentLoaded", function() { // run on load or reload
        
        var previous_answers_string = String( document.getElementById("previous_AnSwEr_$id").value );
        if (previous_answers_string.length > 0) {
        	var previous_answers_array = previous_answers_string.replace(/\\[/g,"").replace(/\\]/g,"").replace(/none/g,"").split(',');
        	var i, j;
        	for (i = 1; i <= $num_rows; i++) {
        		for (j = 1; j <= $num_cols; j++) {
        			document.getElementById("$id").rows[i].cells[j].innerHTML = previous_answers_array.shift();
        		}
        	}
        }
        
        });
        
        document.querySelector("#problemMainForm").addEventListener("submit", function(){ // run on submit

            var i, j;
            var answers_array = [];
            for (i = 1; i <= $num_rows; i++) {
                for (j = 1; j <= $num_cols; j++) {
                    var cell = document.getElementById("$id").rows[i].cells[j].innerHTML;
      		    if (cell.length > 0) {
       			answers_array.push(cell);
       		    } else {
       			answers_array.push("none"); // placeholder for empty
       		    }
                }
            }

            //  create a string by joining elements of the array by commas, and then replacing any html tags using regex match and replace
            //  https://stackoverflow.com/questions/1499889/remove-html-tags-in-javascript-with-regex
            var answers_string = answers_array.join(",").replace(/(<([^>]+)>)/ig, '');
            document.getElementById('AnSwEr_$id').setAttribute('value', answers_string);

            //  mainly for debugging
            //sessionStorage.setItem("group",document.getElementById("div_$id").innerHTML);
        
        }, false);
        
        </script>
        );

        # insert the html hidden input and check the answer
        my $ans_id = 'AnSwEr_' . $id;
        TEXT( NAMED_HIDDEN_ANS_RULE($ans_id) );
        NAMED_ANS( $ans_id, $ans->cmp(ordered=>1, 'num_rows'=>$num_rows, 'num_cols'=>$num_cols)->withPostFilter(\&group_table_post_filter) ); 

        return $table_html . $js;

    }    # end HTML mode

}    # end GroupTable



sub group_table_post_filter {
    # for answer checking, we use lists; however, we want the answer preview 
    # and correct answer to be displayed as a table, which is what this post filter does.

    my $ans_hash = shift;

    my $nr = $ans_hash->{num_rows};
    my $nc = $ans_hash->{num_cols};

    #########################################
    my $stu = $ans_hash->{student_ans};
    my @stu_array = split(',' , $stu);
    #warn scalar(@stu_array);

    my $str = '';
    foreach my $i (0..($nr-1)) {
        $str .= join(','  , @stu_array[($i*$nc)..(($i+1)*$nc - 1)]) . '<br>';
    }
    $ans_hash->{student_ans} = $str;

    #########################################
    my $stu = $ans_hash->{preview_latex_string};
    my @stu_array = split(',' , $stu);

    my $str = '\begin{array}{';
    $str .= "c" x $nc . '} ';
    foreach my $i (0..($nr-1)) {
        $str .= join(' & '  , @stu_array[($i*$nc)..(($i+1)*$nc - 1)]) . ' \cr ';
    }
    $str .= ' \end{array}';
    $ans_hash->{preview_latex_string} = $str;

    ######################################## 
    my $stu = $ans_hash->{preview_text_string};
    my @stu_array = split(',' , $stu);

    my $str = '';
    foreach my $i (0..($nr-1)) {
        $str .= join(','  , @stu_array[($i*$nc)..(($i+1)*$nc - 1)]) . '<br>';
    }
    $ans_hash->{preview_text_string} = $str;

    ########################################
    my $cor = $ans_hash->{correct_ans_latex_string};
    my @cor_array = split(',' , $cor);
    
    my $str = '\begin{array}{';
    $str .= "c" x $nc . '} ';
    foreach my $i (0..($nr-1)) {
        $str .= join(' & '  , @cor_array[($i*$nc)..(($i+1)*$nc - 1)]) . ' \cr ';
    }
    $str .= ' \end{array}';
    $ans_hash->{correct_ans_latex_string} = $str;

    ######################################## 
    my $cor = $ans_hash->{correct_ans};
    my @cor_array = split(',' , $cor);

    my $str = '';
    foreach my $i (0..($nr-1)) {
        $str .= join(','  , @cor_array[($i*$nc)..(($i+1)*$nc - 1)]) . '<br>';
    }
    $ans_hash->{correct_ans} = $str;

    ########################################
    # for debugging
    #warn pretty_print($ans_hash);

    return $ans_hash;
}


1;
