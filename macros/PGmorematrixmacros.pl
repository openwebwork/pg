#!/usr/local/bin/webwork-perl

BEGIN{
	be_strict();
}

sub _PGmorematrixmacros_init{}

sub random_inv_matrix { ## Builds and returns a random invertible \$row by \$col matrix.

    warn "Usage: \$new_matrix = random_inv_matrix(\$rows,\$cols)"
      if (@_ != 2);
    my $A = new Matrix($_[0],$_[1]);
    my $A_lr = new Matrix($_[0],$_[1]);
    my $det = 0;
    my $safety=0;
    while ($det == 0 and $safety < 6) {
        foreach my $i (1..$_[0]) {
            foreach my $j (1..$_[1]) {
                $A->assign($i,$j,random(-9,9,1) );
                }
            }
            $A_lr = $A->decompose_LR();
            $det = $A_lr->det_LR();
        }
    return $A;
}

sub swap_rows{

    warn "Usage: \$new_matrix = swap_rows(\$matrix,\$row1,\$row2);"
      if (@_ != 3);
    my $matrix = $_[0];
    my ($i,$j) = ($_[1],$_[2]);
    warn "Error:  Rows to be swapped must exist!" 
      if ($i>@$matrix or $j >@$matrix);
    warn "Warning:  Swapping the same row is pointless"
      if ($i==$j);    
    my $cols = @{$matrix->[0]};
    my $B = new Matrix(@$matrix,$cols);
    foreach my $k (1..$cols){
        $B->assign($i,$k,element $matrix($j,$k));
        $B->assign($j,$k,element $matrix($i,$k));
    }
    return $B;
}

sub row_mult{

    warn "Usage: \$new_matrix = row_mult(\$matrix,\$scalar,\$row);"
      if (@_ != 3);
    my $matrix = $_[0];
    my ($scalar,$row) = ($_[1],$_[2]);
    warn "Undefined row multiplication" 
      if ($row > @$matrix);
    my $B = new Matrix(@$matrix,@{$matrix->[0]});
    foreach my $j (1..@{$matrix->[0]}) {
        $B->assign($row,$j,$scalar*element $matrix($row,$j));
    }
    return $B;
}

sub linear_combo{

    warn "Usage: \$new_matrix = linear_combo(\$matrix,\$scalar,\$row1,\$row2);"
      if (@_ != 4);
    my $matrix = $_[0];
    my ($scalar,$row1,$row2) = ($_[1],$_[2],$_[3]);
    warn "Undefined row in multiplication"
      if ($row1>@$matrix or $row2>@$matrix);
    warn "Warning:  Using the same row"
      if ($row1==$row2);
    my $B = new Matrix(@$matrix,@{$matrix->[0]});
    foreach my $j (1..@$matrix) {
        my ($t1,$t2) = (element $matrix($row1,$j),element $matrix($row2,$j));
        $B->assign($row2,$j,$scalar*$t1+$t2);
    }
    return $B;
}


1;
