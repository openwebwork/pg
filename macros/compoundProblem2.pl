sub _compoundProblem2_init {};   # don't reload this file
$width =700; #457
HEADER_TEXT(<<'END_HEADER_TEXT');

<style type="text/css">

* {margin:0; padding:0; font:12px Verdana,Arial}
code {font-family:"Courier New",Courier}

#options {width:${width}px; margin:20px auto; text-align:right; color:#6600}
#options a {text-decoration:none; color:#9ac1c9}
#options a:hover {color:#033}

#acc {width:${width}px; list-style:none; color:#033; margin:0 auto 40px}
#acc h3 {width:${width-14}px; border:1px solid #9ac1c9; padding:6px 6px 8px; font-weight:bold; margin-top:5px; cursor:pointer; background:url(images/header.gif)}
#acc h3:hover {background-color:#ff0}
#acc .acc-section {overflow:hidden; background:#fff}
#acc .acc-content {width:${width-32}px; padding:15px; border:1px solid #9ac1c9; border-top:none; background:#fff}

#nested {width:425px; list-style:none; color:#033; margin-bottom:15px}
#nested h3 {width:411px; border:1px solid #9ac1c9; padding:6px 6px 8px; font-weight:bold; margin-top:5px; cursor:pointer; background:url(images/header.gif)}
#nested h3:hover {background:url(images/header_over.gif)}
#nested .acc-section {overflow:hidden; background:#fff}
#nested .acc-content {width:393px; padding:15px; border:1px solid #9ac1c9; border-top:none; background:#fff}
#nested .acc-selected {background:url(images/header_over.gif)}
.iscorrect {color:green;}
.iswrong {color:red;}
 .canshow {background-color:#9f9;}
.isclosed{ {background-color: #666; display:none;}
</style>


<script language="javascript">

var TINY={};

function T$(i){return document.getElementById(i)}
function T$$(e,p){return p.getElementsByTagName(e)}

TINY.accordion=function(){
	function slider(n){this.n=n; this.a=[]}
	slider.prototype.init=function(t,e,m,o,k){
		var a=T$(t), i=s=0, n=a.childNodes, l=n.length; this.s=k||0; this.m=m||0;
		for(i;i<l;i++){
			var v=n[i];
			if(v.nodeType!=3){
				this.a[s]={}; this.a[s].h=h=T$$(e,v)[0]; this.a[s].c=c=T$$('div',v)[0]; h.onclick=new Function(this.n+'.pr(0,'+s+')');
				if(o==s){h.className=this.s; c.style.height='auto'; c.d=1}else{c.style.height=0; c.d=-1} s++
			}
		}
		this.l=s
	};
	slider.prototype.pr=function(f,d){
		for(var i=0;i<this.l;i++){
			var h=this.a[i].h, c=this.a[i].c, k=c.style.height; k=k=='auto'?1:parseInt(k); clearInterval(c.t);
			if((k!=1&&c.d==-1)&&(f==1||i==d)){
				c.style.height=''; c.m=c.offsetHeight; c.style.height=k+'px'; c.d=1; h.className=this.s; su(c,1)
			}else if(k>0&&(f==-1||this.m||i==d)){
				c.d=-1; h.className=''; su(c,-1)
			}
		}
	};
	function su(c){c.t=setInterval(function(){sl(c)},20)};
	function sl(c){
		var h=c.offsetHeight, d=c.d==1?c.m-h:h; c.style.height=h+(Math.ceil(d/5)*c.d)+'px';
		c.style.opacity=h/c.m; c.style.filter='alpha(opacity='+h*100/c.m+')';
		if((c.d==1&&h>=c.m)||(c.d!=1&&h==1)){if(c.d==1){c.style.height='auto'} clearInterval(c.t)}
	};
	return{slider:slider}
}();
</script>
END_HEADER_TEXT


###########################################
sub DISPLAY_SECTION {
     my $text_string = shift;
     my %options = @_;
    #FIXME  need to check options for accuracy

    my $name = $options{name};
    # determine correctness color
    my $iscorrect = "";
    if ($options{iscorrect} == 1) {
            $iscorrect = 'color:green;';
    } elsif ($options{iscorrect} == -1 ) {
            $iscorrect = 'color:red;';
    } else {
            $iscorrect = 'color:#999;';
    }

    # determine whether the segment can be shown
    my $canshow = (defined($options{canshow}) and $options{canshow}==1 ) ?  " ": "display:none;";
    my $canshow_bg_color = (defined($options{canshow}) and $options{canshow}==1 ) ?  " ": "background-color:#333;";
    #my $this_part_bg_color = (defined($options{part}) and $options{part}==$part ) ?  " ": "background-color:#00f;";
     my $this_part_bg_color=""; 
      TEXT(   qq!<li>
          <h3  class="" style= "$iscorrect $canshow_bg_color " >Part: $name:</h3>
         <div class="acc-section" style="height: 0px; opacity: 0.004347826086956522;">
         <div class="acc-content"  style="$canshow">
      !);
     my $rendered_text_string = EV3($text_string);
     TEXT( $rendered_text_string ) if $options{canshow}==1;
     TEXT( "</p></div></div></li>" );
}

# FIXME   we will make a $cp object that keeps track of the part 

sub BEGIN_SECTIONS {TEXT(q!<ul class="acc" id="acc"> !); }
sub END_SECTIONS {
	my $part = shift;
	TEXT(q!</ul  !);
	TEXT($PAR, qq!
	<script language="javascript">
	var parentAccordion=new TINY.accordion.slider("parentAccordion");
	parentAccordion.init("acc","h3",0,-1);
	parentAccordion.pr(0,$part)
	</script>
	!, "part=",$part+1);
}