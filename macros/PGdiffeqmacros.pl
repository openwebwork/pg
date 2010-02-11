
=head1 PGdiffeqmacros.pl DESCRIPTION

# Macros for Prills 163 problems

=cut

#!/usr/bin/perl -w
#use strict;
#use Carp;
BEGIN {
	be_strict();#all variables must be declared local or global
}

#my @answer = oldivy(1,2,1,8,4);
#print ("The old program says:\n");
#print ($answer[0]);
#print ("\n");
#@answer = ivy(1,2,1,8,4);
#print ("My program says:\n");
#print ($answer[0]);
#print ("\n");

#the subroutine is invoked with arguments such as complexmult(2,3,4,5) or
#complexmult(@data), where @data = (2,3,4,5)

sub complexmult {
    my ($S,$T,$U,$V) = @_;
#this line defines the input arguments as local variables
    my $R = $S *$U -$T * $V;
    my $I = $S *$V + $T * $U ;
    ($R,$I) ;#this returns ($R,$I) from the subroutine
}      

=head3 addtwo($1stAddend,$1stIndicator,$2ndAddend,$2ndIndicator)

##########					
# sub addtwo adds two strings formally
# An "indicator"  for a string is a
#  number ,e.g. coefficient,which indicates 
# whether the string is to be 
# added or is to be regarded as zero. 
# The  non-zero terms are formally added as strings.
# The input is an array 
# ($1staddend, $1stindicator,$2ndaddend,$2ndindicator)
# The return is an array
# (formal sum, indicator of formal sum)

=cut

sub addtwo {
   my ($A,$a,$B,$b) = @_;
    my $out = "0";
    if ($a  != 0) {
	$out= $A;
    }
    
    
    if ($b  != 0) {
	if ($a  == 0) {
	    $out= $B ;
	} else {
	    $out = "$A + $B";
	}
    }
    my $ind = abs($a) + abs($b);
    ($out,$ind); 
}

=head3 add($1stAddend,$1stIndicator,$2ndAddend,$2ndIndicator,...)

########
# sub add generalizes sub addtwo to more addends.
# It formally adds the nonzero terms. 
# The input is an array of even length
# consisting of each addend,a string,
# followed by its indicator.  

=cut

sub add { 
    # this function takes the first two terms, puts them together, and keep repeating until you have emptied the list.
    my @sum = ("0" ,0);  
    my @list = @_;
    my $el = @list;
    my $x = "0";
    my $y = 0;
    while ($el > 0) {
	$x = shift(@list);
	$y = shift(@list);
	push(@sum,$x,$y);
	@sum = addtwo(@sum);
	$el = @list;         
    }
    @sum ;
}

=head3 diffop($a,$b,$c)

#######
# sub diffop cleans up the typed expression 
# of a diff. operator.
# input @diffop =($A,$B,$C) is the coefficients.
# input is given as arguments viz difftop($A,$B,$C);
# output is the diff. operator as a string $L in TEX

=cut

sub diffop 
{
    my ($A,$B,$C) = @_ ;
    my ($LDD, $LD ,$LF) = ($A."y'' ",$B."y' ",$C."y ");
    # re-write 1y'' as y''.
    if ($A==1){
	$LDD = "y''";
    }
    # re-write 1y' as y'
    if ($B==1) {
	$LD = "y'";
    }
    # re-write -1y' as -y'
    elsif ($B==-1) {
	$LD = "-y'";
    }  
    # re-write 1y as y
    if ($C==1) {
	$LF = "y";
    } 
    # re-write -1y as -y
    elsif ($C==-1) {
	$LF = "-y";
    } 
    my ($L,$ind) = add($LDD,$A,$LD,$B,$LF,$C);
    $L;
}

=head3 rad($num1,$num2,$num3)

########
# sub rad simplifies (a/b)*(sqrt(c))
# input is given as arguments on rad viz.: rad($a,$b,$c);
# $a,$b,$c are integers and $c>=0 and $b is not zero.
# output is an array =(answer as string,new$a,new$b, new$c)

=cut

sub rad{
    # initalize primes
    my @p = (2,3,5,7,11,13,17,19,23,29);
    my ($a,$b,$c) = @_;
    my $s = "0" ;
    my $i = 0 ;    
    # if a=0 then re-write as (0/1)*(sqrt(1)) = 0.
    if ($c*$a ==0){
	$a = 0;
	$b = 1;
	$c = 1;
    }

    # if b<0 then re-write the numerator as negative, denominator as positive
    if ($b < 0){
	$a = - $a ;
	$b = - $b ;
    }
    
    my $j = 1 ;
    while($j == 1){
	# can't reduce sqrt(1).
	if ($c == 1){
	    last;
	}
	$j = 0;
	foreach $i (@p){
	    # if you can factor a prime out of c, do it. 
	    # ie, sqrt(75) = 5*sqrt(3)
	    if ( $c == $i*$i*int($c/($i*$i))){
		$a = $a *$i;
		$c = $c/($i*$i);
		$j=1;
	    }
	}
    }
    $j = 1;
    
    # reduce fraction is lowest terms.
    while($j==1){
	# if the denominator is 1, then we're set.
	if ($b==1){
	    last;
	}
	$j = 0;
	foreach $i (@p){
	    # if you can factor a prime out of both numerator and denominator, do it.
	    if ( abs($a) + $b == $i*int(abs($a) /$i) + $i*int($b/$i) ){
		$a = $a /$i;
		$b = $b /$i;
		$j=1;
	    }
	}
    }
    
    # $s = answer string
    
    # if you have ($a/1)*sqrt(1) then the answer is simply "$a".
    if ($c == 1) {
	if ($b == 1){
	    $s = "$a";
	} 
	# if you have ($a/$b)*sqrt(1) then the answer is "$a/$b".
	else {
	    $s = "$a/$b";
	}
    }
    
    if ($c > 1) {
	if ($a != 1){
	    if ($b == 1) {
		# if denominator is 1, then answer is "$a*sqrt($c)".
		$s = "$a * sqrt($c)";
	    }
	    # if denominator is nonzero... answer is all three terms.
	    else {
		$s = "$a *sqrt($c) /$b";
	    }
	} else {
	    # if you have "(1/1)*sqrt($c)" then the answer is "sqrt($c)".
	    if ($b == 1) {
		$s = "sqrt($c)";
	    }
	    # if you have "(1/$b)*sqrt($c)" then answer is "sqrt($c)/$b".
	    else {
		$s = "sqrt($c) /$b";
	    }
	}
    }
# return all four variables: answer string, reduced numerator, reduced denominator, squareroot with primes factored out 
    my $rh_hash = {    	displaystr 	=> $s,
		       			num 		=> $a,
		     			denom 		=> $b,
                      	root 		=> $c};
    $rh_hash;

}

##########
sub frac {
    # use rad subroutine 
    my ($a,$b) = @_;
    rad($a,$b,1);
}
##########

=head3 simpleexp($r,$ind)

####
# sub exp simplifies exp($r*t) in form for writing perl
# or tex. The input is exp($r,$ind); $ind indicates whether
# we want perl or tex mode. $r is a string that represents
# a number.
# If $ind = 0  output is "exp(($r)*t)", simplified if possible.
# If $ind = 1  output is "exp(($r)*t)", simplified if possible.

=cut

sub simpleexp {
    my $r = shift;
    my @rr = @_;
    my %options;
    if ($rr[0] eq 'mode') {
	$options{'mode'} = $rr[1];
    } elsif ( $rr[0] == 1) {
	$options{'mode'} = 'typeset';  
    } elsif ($rr[0] == 0 ) {
	$options{'mode'} = 'standard';# means we use * for multiplication
	}
    
    my $y = "0";
    if ($r eq "0"){
	if ($options{'mode'} eq 'standard' ) {
	    $y = "1";
	} elsif ($options{'mode'} eq 'typeset' ) {
	    $y = "";  # multiplication by 1 is the identity
	} else {
	    warn "simpleexp doesn't recognize the mode $options{'mode'}";
	}
	
	# change exp(1t) = exp(t)
    }elsif  ($r eq "1"){
	$y = "exp(t)";
    }
    # change exp(-1t) = exp(-t)
    elsif  ($r eq "-1"){
	$y = "exp(-t)";   
    }
    # in typeset modeset you don't use the *
    # in standard modeset you use *
    else {
	if ($options{'mode'} eq 'typeset') {
	    $y = "exp(($r)t)";
	} elsif ($options{'mode'} eq 'standard') {
	    $y = "exp(($r)*t)";
	} else {
	    warn "simpleexp doesn't recognize the mode $options{'mode'}";
	}
    }
    $y;
}

sub ivy {
    # $a*y'' + $b*y' + $c*y = 0.  y(0)=$m.  y'(0)=$n.
    my ($a, $b, $c, $m, $n) = @_; 
    my $d = ($b*$b)-(4*$a*$c); # d is the discriminant
    my $c1 = "0";
    my $c2 = "0";
    my $r1 = "0";
    my $r2 = "0";
    my $answer = "";

    # c1 = first coefficient, c2 = second coefficient, rr1 = e^r1, rr2 = e^r2.
    # c1*rr1 + c2*rr2 = c1*e^r1 + c2*e^r2
    
    if ($d > 0) {
	# y(t) = [m/2 + sqrt(d)*(2An+Bm)/(2d)]e^[t*(-B+sqrt(d))/(2A)] + [m/2 - sqrt(d)*(2An+Bm)/(2d)]e^[t*(-B-sqrt(d))/(2A)]
	my $piece1 = frac($m,2);
	my $piece2 = rad(2*$a*$n+$b*$m,2*$d,$d);
	$c1 = "$piece1->{displaystr} + $piece2->{displaystr}"; # first coefficient:  "m/2 + sqrt(d)*(2An+Bm)/(2d)"
	$c2 = "$piece1->{displaystr} - $piece2->{displaystr}"; # second coefficient: "m/2 - sqrt(d)*(2An+Bm)/(2d)"
	$piece1 = frac(-$b,2*$a); # find (-B/(2A)) in lowest terms
	$piece2 = rad(1,2*$a,$d); # find (sqrt(B*B-4AC)/(2A)) in lowest terms
	$r1 = "$piece1->{displaystr} + $piece2->{displaystr}"; # r1: (-B+sqrt(d))/(2A)
	$r2 = "$piece1->{displaystr} - $piece2->{displaystr}"; # r2: (-B-sqrt(d))/(2A)
	my $rr1 = simpleexp($r1,0); # raise e^r1.
	my $rr2 = simpleexp($r2,0); # raise e^r2.
	$answer = "($c2) *$rr2 + ($c1) *$rr1";
	
    }

    if ($d == 0) {
	# y(t) = me^((-B/(2A)t) + [(n+mB)/(2A)]*t*e^((-Bt)/(2*A))
	my $piece1 = frac(-$b,2*$a); # find (-B/(2A)) in lowest terms
	my $piece2 = frac(2*$a*$n+$m*$b,2*$a); # find (2An+Bm)/(2A) in lowest terms
	$c1 = "$m";                 #  first coefficient: "m"
	$c2 = "$piece2->{displaystr}";         # second coefficient: "(n+mB)/(2A)"
	$r1 = "$piece1->{displaystr}";         # r1: (-B/(2A)) 
	$r2 = $r1;                  # r2: (-B/(2A))
	my $rr1 = simpleexp($r1,0); # rr1 = e^r1 = e^(-B/(2A))
	my $rr2 = simpleexp($r2,0); # rr2 = e^r2 = e^(-B/(2A))
	$answer = "($c1) *$rr1 + ($c2)*t *$rr2";
    }

    # if the descriminant is negative, then the roots are imaginary.
    # recall, e^x where x=a+ib then e^x = (e^a)*cos(bt) + (e^a)*sin(bt).
    if ($d<0){
	# y(t) = me^(-Bt/(2A))*cos(t*sqrt(4AC-B*B)/(2A))+(2An+Bm)*sqrt(4AC-B*B)/(4AC-B*B)*e^(-Bt/(2A))*sin(t*sqrt(4AC-B*B)/(2A))
	my $piece1 = rad (2*$a*$n+$b*$m,-$d,-$d); # find ((2An+Bm)*sqrt(4AC-B*B))/(4AC-B*B) in lowest terms 
	my $piece2 = rad (1,2*$a,-$d);            # find (sqrt(4AC-B*B)/(2A)) in lowest terms
	$c1 = "$m";                      #  first coefficient: "m"
	$c2 = "$piece1->{displaystr}";              # second coefficient: "(2An+Bm)*sqrt(4AC-B*B)/(4AC-B*B)"
	my $cs1 = "cos(($piece2->{displaystr})*t)"; # cos(t*sqrt(4AC-B*B)/(2A))
	my $cs2 = "sin(($piece2->{displaystr})*t)"; # sin(t*sqrt(4AC-B*B)/(2A))
	my $piece3 = frac (-$b,2*$a);    # find (-B/(2A)) in lowest terms
	$r1 = "$piece3->{displaystr}";              # r1: (-B/(2A))
	$r2 = $r1;                       # r2: (-B/(2A))
	my $rr1 = simpleexp($r1,0);      # rr1 = e^r1 = e^(-B/(2A))
	my $rr2 = simpleexp($r2,0);      # rr2 = e^r2 = e^(-B/(2A))
	$answer = "($c1) *($rr1)*($cs1) + ($c2) *($rr2)*($cs2)";
    }
    $answer;
}


############
#sub ivy solves the initial value problem
# $a*y'' + $b*y' + $c*y = 0, with  y(0) = $m,  y'(0) = $n 

#The numbers $a,$b,$c,$m,$n should be integers with $a not 0.
#The inputs are given as arguments viz: ivy ($a,$b,$c,$m,$n).
#The output is the solution as a string giving a function of t.



sub undeterminedExp {
    my ($A,$B,$C,$r,$q0,$q1,$q2) = @_;
    my $P = "$A*x*x + $B *x + $C "; #characteristic poly.
    my $PP = "$A*2*x + $B ";#derivative of characteristic poly.
    my $exp = simpleexp($r,0);
    #$Pr = $P;
    #$Pr =~ s~~x~~$r~~g;
    #$Pr = PG_answer_eval("$Pr ");
    #$PPr = $PP;
    #$PPr =~ s~~x~~$r~~g;
    #$PPr = PG_answer_eval("$PPr ");
    my $Pr = $A *$r *$r + $B *$r + $C  ;
    my $PPr = 2* $A* $r + $B;	
    #################
    if ($Pr  !=  0){   
	#$r not a root of $P
	# $v0  = "($q0 /$Pr)  ";
	my $n1 = -$q1 * $PPr ;
	my $d1 = $Pr * $Pr;
	# $v1 = " ($q1 /$Pr)* t   +  ($n1 / $d1) ";
	my $n22 = $Pr *$Pr  *$q2;
	my $n21 =  (- 2 *$PPr ) *$q2;
	my $n20 =  (2*$PPr *$PPr - ($A*2*$Pr)) *$q2 ;
	my $d2 = $Pr **3;
	# $v2 = "($n22/$d2) *t*t  + ($n21/$d1) *t + ($n20/$d2) ";    
	my $c00n = $q0*$d1 -$q1 *$PPr *$Pr + $n20;
	my $c00d = $d2;
	my $fraca = frac ($c00n ,$c00d );
	my $c00 = $fraca->{displaystr};
	my $c01n = $Pr *$q1 - 2 *$PPr *$q2;
	my $c01d = $d1;
	my $fracb = frac($c01n ,$c01d );
	my $c01 = $fracb->{displaystr};
	$c01 = "($c01) *t";
	my $c02n = $q2;
	my $c02d = $Pr;
	my $fracc = frac($c02n ,$c02d );
	my $c02 = $fracc->{displaystr};
	$c02 = "($c02 ) *t*t";
	my @adda = add ($c00,$c00n,$c01,$c01n,$c02,$c02n);
	my $outa = $adda [0];
        my $y = "( $outa ) * $exp " ;
	#############
    } elsif ($PPr != 0){
	#$r a simple root of $P
	my $q2m = -$q2; 
	#$v0 = "( $q0/$PPr)*t ";       
	my $q2d = 2*$q2;
	my $d10 = 2*$PPr;
	my $d11 = $PPr **2 ;
	my $q1m = -$q1;
	#$v1 = "($q1 / $d10)*t*t   +   ($q1m / $d11)*t ";    
	my $d23 = 3*$PPr;
	my $d22 = $PPr *$PPr ;
	my $d21 = $PPr *$d22;           
	#$v2 = "($q2 / $d23) *t*t*t + ($q2m/$d22) *t*t  + ($q2d/ #$d21) *t ";		
	######  	
	my $c10n = $q0 *$d22 -$q1*$A *$PPr + $A*$A*$q2d;
	my $c10d = $d21;
	my $fracd = frac($c10n ,$c10d );
	my $c10 = $fracd->{displaystr};
	#warn " c10 $c10";
	$c10 = "($c10 )*t";
	my $c11n = $PPr * $q1 - 2 *$A * $q2;
	my $c11d = 2*$PPr*$PPr;
	my $frace = frac($c11n ,$c11d );
	my $c11 = $frace->{displaystr};
	#warn " c11 $c11";
	$c11 = "($c11 )*t*t";
	my $c12n = $q2;
	my $c12d = 3*$PPr;
	my $fracf = frac ($c12n ,$c12d );
	my $c12 = $fracf->{displaystr};
	$c12 = "($c12 ) *t*t*t";
	my @addb = add($c10,$c10n,$c11,$c11n,$c12,$c12n);
	my $outb = $addb[0];
	my $y = "( $outb ) * $exp" ; 	
	######  	  	
    } else {
        # $v2 =  "($q2 /12*$A) *t*t*t*t  ";	   
        #v1 =  "($q1 /6*$A) *t*t*t   ";
        #$v0 =  "($q0 /2*$A) *t*t  " ;	
	my $c20n = $q0;
	my $c20d = 2*$A;
	my $fracg = frac($q0 ,$c20d );
	my $c20 = $fracg->{displaystr};
	$c20 = "($c20 ) *t*t";
	my $c21n = $q1;
	my $c21d = 6*$A;
	my $frach = frac($c21n ,$c21d );
	my $c21 = $frach->{displaystr};
	$c21 = "($c21)  *t*t*t";
	my $c22n = $q2;
	my $c22d = 12*$A;
	my $fraci = frac($c22n ,$c22d );
	my $c22 = $fraci->{displaystr};
	$c22 = "($c22 ) *t*t*t*t";
	my @addc = add($c20,$c20n,$c21,$c21n,$c22,$c22n);
	my $outc = $addc[0];
	my $y = "( $outc ) * $exp" ;                               
    }
    
}

=head3 undeterminedSin($A,$B,$C,$r,$w,$q1,$q0,$r1,$r0)

#################
# undeterminedSin is a subroutine to solve 
# undetermined coefficient problems that have
# sines and cosines. 
# The input is an array ($A,$B,$C,$r,$w,$q1,$q0,$r1,$r0)
# given as arguments on undeterminedSin 
# $L =$A y'' + $B y' + $C y
# $rhs = ($q1 t + $q0) cos($w t)exp($r t) +
#        ($r1 t + $r0) sin($w t)exp($r t)
# The subroutine uses undetermined coefficients
# to find a solution $y of $L = $rhs .
# The output \is $y

=cut

sub undeterminedSin {
    my ($A,$B,$C,$r,$w,$q1,$q0,$r1,$r0) = @_;
    my $Pr = ($A*$r*$r) + $B *$r + $C;
    my $PPr = (2*$A *$r ) + $B ;
    my $re = $Pr -$A* $w*$w ;
    my $im = $PPr * $w ; 
    #If P(x) = A x^2 +Bx +C,
    #P($r+i*$w)=$re+i $im.
    my $D = $re **2 + $im **2 ; 
    # $D = |P($r + i*$w)|^2 
    my $reprime = $PPr;
    my $imprime = 2*$A*$w;
    #If PP(x) = derivative of P(x),
    #PP($r+i $w)=$reprime+$imprime.
    my $cos = "cos($w *t)";
    my $sin  =  "sin($w *t)";
    if ($w == 1){
	$cos = "cos(t)";
	$sin = "sin(t)";
    }
    
    
    my $exp = simpleexp($r,0);
    
    ############
    if ($D != 0){   
	#We first handle case that$r+i$w not a root of $P(x)
	#This solution is based on:
	#Let L[y] = Ay'' +By'+C,z=r+iw,p=P(z),q=P'(z),S,T complex;p!=0.
	#Then L[((St+T-(Sq/p))/p)*e^{zt}]=(St+T)e^{zt}.
	#Take S=q1-i*r1;T=q0-i*r0.Then take real part.
	my ($renum1 ,$imnum1) = complexmult($q1,-$r1,$re, -$im);
	
	#S*(p conjugate)=   $renum1+i imnum1
	my ($renum2 ,$imnum2) = complexmult ($renum1,$imnum1,$reprime,$imprime);
	#The above are real and imag parts  of q*S*(p conjugate)
	my $first = ($D *$q0 ) - $renum2 ;
	my $second = (-$r0 *$D ) -$imnum2 ;
	my ($renum3, $imnum3 )  = complexmult( $first,$second,$re,-$im);
	#these are re and im of (DT-qS(p conj))*(p conj.)           
	my $n1 = $renum1;
	my $n2 = $renum3;       
	my $n3 = -$imnum1;
	my $n4 = -$imnum3;
	my $fraca  = frac($n1,$D );
	my $tcosp = $fraca->{displaystr};
	#$tcospart = "($tcosp )*t*$exp *$cos ";
	my $tcospart = "($tcosp)*t*$exp *$cos " ; #####################
	my $DD = $D *$D;
	my $fracb = frac($n2 , $DD );
	my $cospart = $fracb->{displaystr};
	$cospart = "($cospart )*$exp*$cos";
	my $fracc = frac($n3 , $D );
	my $tsinpart = $fracc->{displaystr};
	$tsinpart = "($tsinpart )*t*$exp*$sin";
	my $fracd = frac($n4 , $DD );
	my $sinpart = $fracd->{displaystr};
	$sinpart = "($sinpart )*$exp*$sin";
	my @suma = add($tcospart,$n1,$cospart,$n2,$tsinpart,$n3,$sinpart,$n4 );
	my $out = $suma[0];
	#The solution is $out                    
    } else{
	#We now handle case that $r+iw is a  root of $P
	#In this case $PPr = 0 and $PP($r + i$w) = 2*$A*i*$w
	#Solution based on
	#L[((S/2q)t*t -(AS/q*q)t +(T/q)t)e^{zt}]=
	#(St+T)e^{zt}.Notation as for 1st part.        
	my $n3 = $q1 - (2*$w *$r0);
	my $n4 = $r1 + (2*$w *$q0 );
	my $n1 = -$r1 ;
	my $n2 = $q1 ;
	my $T2 = 4*$A *$w ;
	my $T1 = $w * $T2 ;
	my $frace = frac($n1 , $T2 );
	my $t2cospart = $frace->{displaystr};
	$t2cospart = "($t2cospart )*t*t*$exp *$cos ";
	my $fracf  = frac($n3 , $T1 );
	my $tcospart = $fracf->{displaystr};
	$tcospart = "($tcospart )*t*$exp *$cos ";
	my $fracg = frac($n2 , $T2 );
	my $t2sinpart = $fracg->{displaystr};
	$t2sinpart = "($t2sinpart )*t*t*$exp*$sin";
	my $frach = frac($n4 , $T1 );
	my $tsinpart = $frach->{displaystr};
	$tsinpart = "($tsinpart )*t*$exp*$sin";
	my @addb = add ($t2cospart,$n1,$tcospart,$n3,$t2sinpart,$n2,$tsinpart,$n4 );
	my $out = $addb[0];
    }
    
}  

sub check_eigenvector {
    
    my $eigenvalue = shift;
    my $matrix = shift;
    my %options = @_;
    assign_option_aliases( \%options,   );
    
    set_default_options(	\%options,
				'debug'				=>	0,
     				'correct_ans'			=>	undef
    );
    

    my @correct_vector = ();
    @correct_vector = @{$options{'correct_ans'}} if defined ($options{'correct_ans'});
    
    my $ans_eval = new AnswerEvaluator;
    
    $ans_eval->{debug} = $options{debug};
    my $corr_ans_points = "( " . join(", ", @correct_vector). " )" ;
    $ans_eval->ans_hash( correct_ans  => $corr_ans_points );
    $ans_eval->install_pre_filter(\&is_array);
    $ans_eval->install_pre_filter(\&std_num_array_filter);
        
    $ans_eval->install_evaluator(sub { my $rh_ans = shift;
				       my %options  = @_;
				       my @vector = @{$rh_ans->input()};
				       return($rh_ans) unless @correct_vector == @vector;
						# make sure the vectors are the same dimension
				       
				       my $vec = new Matrix(2,1);
				       $vec->assign(1,1, $vector[0]);
				       $vec->assign(2,1, $vector[1]);
				       my $out_vec = $matrix * $vec;
				       my @diff;
				       $diff[0] = $out_vec->element(1,1) - $vec->element(1,1)*$eigenvalue;
				       $diff[1] = $out_vec->element(2,1) - $vec->element(2,1)*$eigenvalue;
				       $rh_ans->{score} = zero_check(\@diff);
				       $rh_ans;
				       
				   });
    $ans_eval->install_post_filter( sub { 	  my $rh_ans= shift;
						  if ($rh_ans->error_flag('SYNTAX') ) {
						      $rh_ans->{ans_message} = $rh_ans->{error_message};
						      $rh_ans->clear_error('SYNTAX');
						      $rh_ans;
						  }
					      });
    
    $ans_eval;
}



=pod

    rungeKutta4a
    
	Answer checker filter for comparing to an integral curve of a vector field.
	
	
=cut

    
    
sub rungeKutta4a { 
	my $rh_ans = shift;
	my %options = @_;
 	my $rf_fun = $rh_ans->{rf_diffeq};
	set_default_options(	\%options,
			    'initial_t'					=>	1,
			    'initial_y'					=>	1,
			    'dt'						=>  .01,
			    'num_of_points'				=>  10,     #number of reported points
			    'interior_points'			=>  5,      # number of 'interior' steps between reported points
			    'debug'						=>	1,      # remind programmers to always pass the debug parameter
			    );
 	my $t = $options{initial_t};
 	my $y = $options{initial_y};
	
 	my $num = $options{'num_of_points'};  # number of points
 	my $num2 = $options{'interior_points'};  # number of steps between points.
 	my $dt   = $options{'dt'}; 
 	my $errors = undef;
	my $rf_rhs = sub { 	my @in = @_; 
				my ( $out, $err) = &$rf_fun(@in);
				$errors .= " $err at ( ".join(" , ", @in) . " )<br>\n" if defined($err);
				$out = 'NaN' if defined($err) and not is_a_number($out);
				$out;
			    };
	
 	my @output = ([$t, $y]);
 	my ($i, $j, $K1,$K2,$K3,$K4);
 	
 	for ($j=0; $j<$num; $j++) {
	    for ($i=0; $i<$num2; $i++) {	
		$K1 = $dt*&$rf_rhs($t, $y);
		$K2 = $dt*&$rf_rhs($t+$dt/2,$y+$K1/2);
		$K3 = $dt*&$rf_rhs($t+$dt/2, $y+$K2/2);
		$K4 = $dt*&$rf_rhs($t+$dt, $y+$K3);
		$y = $y + ($K1 + 2*$K2 + 2*$K3 + $K4)/6;
		$t = $t + $dt;
	    }
	    push(@output, [$t, $y]);
 	}
 	$rh_ans->{evaluation_points} = \@output;
 	$rh_ans->throw_error($errors) if defined($errors);
	$rh_ans;
}


sub level_curve_check {
    my $diffEqRHS = shift;    #required differential equation
    my $correctEqn = shift;   # required answer in order to check the equation
    my %options = @_;
	my $saveUseOldAnswerMacros = main::PG_restricted_eval('$main::useOldAnswerMacros') || 0;
	main::PG_restricted_eval('$main::useOldAnswerMacros = 1');
    assign_option_aliases( \%options,
			  'vars'			=>		'var',
			  'numPoints'		=>		'num_of_points',
			  'reltol'		=>		'relTol',
	);
    set_default_options(  \%options,
			'initial_t'		=>		0,
			'initial_y'		=>		1,
			'var'			=>		[qw( x y )],
			'num_of_points'         =>		10,
			'tolType'		=>  	(defined($options{tol}) ) ? 'absolute' : 'relative',
			'relTol'		=>		.01,
			'tol'			=>		.01,
			'debug'			=>		0,
	);
    
    my $initial_t = $options{initial_t};
    my $initial_y = $options{initial_y};
    my $var = $options{var};
    my $numPoints = $options{num_of_points};
    my @VARS = get_var_array( $var );
    my ($tolType, $tol);
    if ($options{tolType} eq 'absolute') {
		$tolType = 'absolute';
		$tol = $options{'tol'};
		delete($options{'relTol'}) if exists( $options{'relTol'} );
    } else {
		$tolType = 'relative';
		$tol = $options{'relTol'};
		delete($options{'tol'}) if exists( $options{'tol'} );
    }
    #prepare the correct answer and check its syntax
    my $rh_correct_ans = new AnswerHash;
    $rh_correct_ans ->{correct_ans} = $correctEqn;
    # check and calculate the function defining the differential equation
    $rh_correct_ans->input( $diffEqRHS );
    $rh_correct_ans = check_syntax($rh_correct_ans);
    warn  $rh_correct_ans->{error_message},$rh_correct_ans->pretty_print() if $rh_correct_ans->{error_flag};
    
    $rh_correct_ans->{error_flag} = undef;
    
    $rh_correct_ans = function_from_string2($rh_correct_ans, 
					    ra_vars => [@VARS], 
					    store_in =>'rf_diffeq',
					    debug=>$options{debug}
					    );
    warn "Error in compiling instructor's answer: $diffEqRHS<br> $rh_correct_ans->{error_message}<br>\n$rh_correct_ans->pretty_print()"
	if $rh_correct_ans->{error_flag};
    
    
    # create the test points that should lie on a solution curve of the differential equation
    $rh_correct_ans = rungeKutta4a( $rh_correct_ans, 
				   initial_t => $initial_t, 
				   initial_y => $initial_y, 
				   num_of_points => $numPoints,
				   debug=>$options{debug}
				   );                                                         
    warn "Errors in calculating the solution curve $rh_correct_ans->{student_ans}<BR>\n
          $rh_correct_ans->{error_message}<br>\n",$rh_correct_ans->pretty_print() if $rh_correct_ans->catch_error();
    $rh_correct_ans->clear_error();  
    
    # check and compile the correct answer submitted by the instructor.
    my ($check_eval) = fun_cmp('c', 	vars 	=> 	[@VARS], 
			       params 	=> 	['c'],
			       tolType  =>	$options{tolType},
			       relTol	=>	$options{relTol},
			       tol	=>	$options{tol},
			       debug	=>	$options{debug},
			       );  # an evaluator that tests for constants;
    $check_eval->ans_hash(evaluation_points => $rh_correct_ans->{evaluation_points});
    $check_eval->evaluate($rh_correct_ans->{correct_ans});
    if( $check_eval->ans_hash->{score} == 0 or (defined($options{debug}) and $options{debug})) {
	  # write error message for professor
	  my $out1 = $check_eval->ans_hash->{evaluation_points};
	  my $rf_corrEq = $check_eval->ans_hash->{rf_student_ans};
        # if student answer is empty and go on, we get a pink screen
	    my $error_string = "This equation $correctEqn is not constant on solution curves of  y'(t) = $diffEqRHS\r\n<br>
    		                    starting at ( $initial_t , $initial_y )<br>
    		                    $check_eval->ans_hash->pretty_print()".
					"options<br>\n".pretty_print({	vars 	=> 	[@VARS], 
									params 	=> 	['c'],
									tolType =>	$options{tolType},
									relTol	=>	$options{relTol},
									tol		=>	$options{tol},
									debug	=>	$options{debug},
								    });
	
	    for (my $i=0; $i<$numPoints;$i++) {
	      my ($z, $err) = &$rf_corrEq( $out1->[$i][0], $out1->[$i][1] );
	      $z = $err if defined $err;
	      $error_string .= "F( ". $out1->[$i][0] . " , ". $out1->[$i][1] . " ) = $z <br>\r\n";
	    }
	    $error_string .= $rh_correct_ans->error_message();
	    warn $error_string, $check_eval->ans_hash->pretty_print;
    }
    
    my ($constant_eval) = fun_cmp('c', vars => [@VARS], 
				  params 	=> 	['c'],
				  tolType =>	$options{tolType},
				  relTol	=>	$options{relTol},
				  tol		=>	$options{tol},
				  debug	=>	$options{debug},
				  );  # an evaluator that tests for constants;
    $constant_eval->ans_hash(evaluation_points => $rh_correct_ans->{evaluation_points});
    my $answer_evaluator = new AnswerEvaluator;
    $answer_evaluator->ans_hash( 	correct_ans 		=> 	$rh_correct_ans->{correct_ans},       # used for answer only
				rf_correct_ans		=> 	sub { my @input = @_; pop(@input); }, 
				# return the last input which is the constant parameter 'c';
				evaluation_points	=>	$rh_correct_ans->{evaluation_points},
				ra_param_vars 		=> 	['c'],                                # compare with constant function
				ra_vars				=>	[@VARS],
				type				=>	'level_curve',
				);
    $answer_evaluator->install_evaluator(sub { my $ans_hash = shift; 
					       my %options = @_; 
					       $constant_eval->evaluate($ans_hash->{student_ans});
					       $constant_eval->ans_hash;
					   });
    
    $answer_evaluator->install_post_filter( sub { my $ans_hash = shift; $ans_hash->{correct_ans} = $correctEqn; $ans_hash; } );
    $answer_evaluator->install_post_filter( sub { 	  my $rh_ans= shift;
							  my %options = @_;
							  if ($rh_ans->catch_error('SYNTAX') ) {
							      $rh_ans->{ans_message} = $rh_ans->{error_message};
							      $rh_ans->clear_error('SYNTAX');
							      
							  }
							  $rh_ans;
						      });
    
	main::PG_restricted_eval('$main::useOldAnswerMacros = '.$saveUseOldAnswerMacros);
    $answer_evaluator;
    
}


1;
