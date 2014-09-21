######################################################################
#
#  This file implements discussion-based questions, where the student
#  can provide essay-style answers, and the professor can make comments
#  on those.  The student and professor can continue to respond to
#  either other, and so carry on a mathematical discussion.  The
#  discussion is private between the professor and student, with
#  each student carrying on a separate discussion with the professor.
#
#  The professor can view a list of the students in the class with links
#  to their discussions, and indications of how many new messages there
#  are in each.
#
#  The messages can contain mathematics by enclosing it with \(...\)
#  for in-line mathematics and \[...\] for display-mode math.  The
#  mathematics is entered in TeX format.  It is also possible to use
#  Parser strings that are like the ones students give in normal formula
#  answer blanks.  These are enclosed in `...` or ``...`` for in-line
#  and display modes.  For example `sin(x/(x+1))` would have the same
#  effect as \(\sin\!\left(\frac{x}{x+1}\right)\), but is somewhat easier
#  to read.  [FIXME: a more complete Context() needs to be provided
#  for this.]
#
#  To make discussions work properly, the professor must set up two files:
#  one called courseStudentList.pg and one called courseProfessorList.pg,
#  with the first containing a list of the userID's of the students in the
#  course and the second containing a list of the professor ID's.  Sample
#  files are provided that you can place in your course templates/macros
#  directory and edit to suit your needs.  Without these files, the
#  professor functions will not operate properly, though the students
#  could still create entries on their own.
#
#  To start a duscussion, simply assign answerDiscussion.pg to any homework
#  set.  That's it.  The professors can write messages that are visible
#  to all the students, so such a message could be used to provide the
#  starting question for a discussion, for example.  Or the problem could
#  be used by the student to keep a "math journal" for the course (you would
#  want to be sure to keep the homework set open for the whole course in
#  this case).
#
#  This code is currently considered experimental, and there are still features
#  the need to be added, but it gives a sense of what is possible.
#
######################################################################

loadMacros(
  "EV3P.pl",
  "text2PG.pl",
);

sub _answerDiscussion_init {}

######################################################################

package Discussion;

#
#  The defaults for the discussion
#
our %discussion = (
  graderSummary => 
    '<script>(document.getElementsByName("previewAnswers"))[0].parentNode.style.display="none";</script>',
  upArrow     => '&#x25B2;',
  downArrow   => '&#x25BC;',
  rightArrow  => '>',  # &#x25B6;
  leftArrow   => '<',  # &#x25C0;  # (Mozilla doesn't handle this well on a Mac)
  selectMark  => '&#x25B6;',
  newMark     => ' <small>[new]</small>',
  CSSfile     => "answerDiscussion.css",
  CSSfilePG   => "answerDiscussionCSS.pg",
  profFile    => "courseProfessorList.pg",
  studentFile => "courseStudentList.pg",
  columns     => 5,
  extension   => ($WWPlot::use_png)? '.png': '.gif',
  allowStudentEdits => 0,
);

##################################################
#
#  Create a new discussion object
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $discussion = bless {%discussion,@_}, $class;
  $main::inputs_ref->{user} = $main::studentLogin unless defined $main::inputs_ref->{user};
  $main::inputs_ref->{effectiveUser} = $main::studentLogin unless defined $main::inputs_ref->{effectiveUser};
  $discussion->getProfessors;
  $discussion->{isActing} = ($main::inputs_ref->{user} ne $main::inputs_ref->{effectiveUser});
  $discussion->{isProfessor} = $discussion->{isActing} || $discussion->isProfessor;
  $discussion->{isSuperProf} = (defined($main::SuperProf) && $main::SuperProf eq $main::inputs_ref->{user});
  $discussion->{pastDue} = (time() > $main::dueDate) && !$self->{isProfessor};
  
  return $discussion;
}

##################################################
#
#  make it easier to access the TEXT command in main::
#
sub TEXT {main::TEXT(@_)}

##################################################
#
#  True if the user is a professor
#
sub isProfessor {
  my $self = shift;
  my $user = $main::inputs_ref->{user};
  foreach my $prof (@main::ProfessorIds) {return 1 if $prof eq $user}
  return 0;
}

##################################################
#
#  Get the list of professors from the courseProfessorList.pg file.
#  (At some point this could be obtained from the database.)  We
#  fail silently if the file can't be read.
#
sub getProfessors {
  my $self = shift;
  if (!defined(@main::ProfessorIds)) {
    my $profFile = main::findMacroFile($self->{profFile});
    return unless $profFile;
    my ($text,$error) = main::PG_restricted_eval("read_whole_file('$profFile')");
    return unless $text;
    main::PG_restricted_eval($$text);
    return unless defined(@main::ProfessorIds);
  }
}

##################################################
#
#  Get the list of students from the courseStudentList.pg file.
#  (At some point this could be taken from the database.)
#
sub getStudents {
  my $self = shift;
  if (!defined(@main::StudentIds)) {
    @main::StudentIds = ();
    my $studentFile = main::findMacroFile($self->{studentFile});
    if (!$studentFile) {warn "You must provide a '$self->{studentFile}' file"; return}
    my ($text,$error) = main::PG_restricted_eval("read_whole_file('$studentFile')");
    if ($error) {warn "There was an error reading your '$self->{studentFile}' file:<br />".$error; return}
    ($text,$error) = main::PG_restricted_eval($$text);
    if ($error) {warn "There was an error executing your '$self->{studentFile}' file:<br />".$error; return}
  }
}

##################################################
#
#  Create a partial URL used for links that maintain the current data on the page.
#
sub getURL {
  my $self = shift; my $url = "?";
  foreach my $id ('key','displayMode','user',@_) {
    $url .= "$id=$self->{inputs}{$id}&"
      if defined $self->{inputs}{$id} && $self->{inputs}{$id} ne '';
  }
  return $url;
}

##################################################
#
#  Look up the styles from the answerDiscussion.css file.
#  This can be overridden by putting a modified copy in
#  your course templates/macros directory.
#
sub setStyles {
  my $self = shift; my $css;
  TEXT('<STYLE>.problemHeader {display:none}</STYLE>');
  my $cssFile = main::findMacroFile($self->{CSSfile});
  ### FIXME:  do error checking here
  $css =  main::read_whole_file($cssFile) if $cssFile;
  TEXT('<style>'.$$css.'</style>') if $css;
}

##################################################
#
#  Build the list of entries based on the private
#  list in the student's directory, and the public
#  ones in the professors' directories.
#
sub getEntries {
  my $self = shift; my @entries = ();
  my $text = $self->Read("entries");
  push(@entries,split(/\n/,$text)) if defined($text);
  $self->{localEntries} = [main::PGsort(\&sortEntries,@entries)];
  if ($self->{isActing} || !$self->{isProfessor}) {
    foreach my $prof (@main::ProfessorIds) {
      $text = $self->Read($prof.'/entries');
      push(@entries,split(/\n/,$text)) if defined($text);
    }
  }
  $self->{entries} = [main::PGsort(\&sortEntries, @entries)];
}
sub sortEntries {(split('[-/]',$_[0]))[1] > (split('[-/]',$_[1]))[1]}

##################################################
#
#  Determine which are new entries by comparing to the list
#  of entries that have been read.
#
sub getNewEntries {
  my $self = shift; my $user = $self->{inputs}{user};
  my @read = (); my %unread; my %alread;
  my $text = $self->Read("read-".$user);
  push(@read,split(/\n/,$text)) if defined($text);
  foreach my $entry (@{$self->{entries}}) {$unread{$entry} = 1 unless $entry =~ m/-$user$/o}
  foreach my $entry (@read) {$alread{$entry} = 1 unless $entry =~ m/-$user$/o}
  foreach my $entry (@read) {delete $unread{$entry}}
  $self->{newEntries} = \%unread;
  $self->{oldEntries} = \%alread;
}

##################################################
#
#  Get the number of new messages from a give student
#  (used in building the array of student messages
#  for the professor).
#
sub getUnreadCount {
  my $self = shift; my $student = shift;
  my $user = $self->{inputs}{user};
  my $text = $self->Read("$student/entries");
  return 0 unless defined $text;
  my %unread; 
  foreach my $entry (split(/\n/,$text)) {$unread{$entry} = 1 unless $entry =~ m/-$user$/o}
  $text = $self->Read("$student/read-$user");
  if (defined($text)) {foreach my $entry (split(/\n/,$text)) {delete $unread{$entry}}}
  return scalar(keys %unread);
}

##################################################
#
#  Get the number of new messages from a give student
#  (used in building the array of student messages
#  for the professor).
#
sub getAlreadCount {
  my $self = shift; my $student = shift;
  my $user = $self->{inputs}{user};
  my $text = $self->Read("$student/entries");
  return 0 unless defined $text;
  my %alread;
  foreach my $entry (split(/\n/,$text)) {$alread{$entry} = 1}
  return scalar(keys %alread);
}
##################################################
#
#  True if the given entry hasn't been read yet
#
sub isNew {
  my $self = shift; my $entry = shift;
  return $self->{newEntries}{$entry};
}

##################################################
#
#  True if the user is the author of the given entry
#
sub amAuthor {
  my $self = shift; my $entry = shift;
  my ($name,$user) = $self->ParseEntryName($entry);
  return $user eq $self->{inputs}{user};
}

##################################################
#
#  Get the formatted name and user from the entry
#  file name
#
sub ParseEntryName {
  my $self = shift;
  my ($dir,$time,$user) = split('[-/]',shift);
  my ($sec,$min,$hour,$mday,$mon,$year) = localtime($time);
  my $name = main::spf($year+1900,"%04d")."-".main::spf($mon+1,"%02d")."-".main::spf($mday+1,"%02d")." "
           . main::spf($hour,"%02d").":".main::spf($min,"%02d");
  return ($name,$user);
}

##################################################
#
#  Find the currently selected entry based on the
#  current action and the state contained in the
#  form.
#
sub selectedEntry {
  my $self = shift; my $action = $self->{action};
  return if $action eq 'View All';
  if ($action eq 'Clear') {
    delete $self->{inputs}{entry};
    delete $self->{inputs}{preview};
  }
  if ($action eq 'Compose' || $action eq 'Respond') {
    delete $self->{inputs}{entry};
    delete $self->{inputs}{preview};
    delete $self->{inputs}{source};
    delete $self->{inputs}{editing};
    $self->{inputs}{compose} = 1;
    return if $action eq 'Compose';
  }
  return $self->MakeEntry if $action eq 'Make Entry' || $action eq 'Update Entry';
  return $self->DeleteEntry(0) if $action eq 'Delete';
  return $self->DeleteEntry(1) if $action eq 'Yes';
  return $self->EditEntry if $action eq 'Edit';
  return $self->{inputs}{next} if $self->{inputs}{goNext};
  return $self->{inputs}{prev} if $self->{inputs}{goPrev};
  return $self->{inputs}{go} if $self->{inputs}{go};
  return $self->{inputs}{selected} if $self->{inputs}{selected};
  return if $action eq 'Clear' || $action eq 'Preview';
  return $self->firstEntry;
}

##################################################
#
#  Find the first (oldest) unread message
#
sub firstEntry {
  my $self = shift;
  return unless $self->{entries} && scalar(@{$self->{entries}});
  my @unread = keys %{$self->{newEntries}};
  return $self->{entries}[0] unless scalar(@unread);
  return (main::PGsort(\&sortEntries,@unread))[-1];
}

######################################################################
######################################################################

#
#  Initialize a discussion problem
#  (get the initial data and start the table that
#  holds the various windows)
#
sub Begin {
  my $self = shift;
  $self->setStyles;
  $self->Grader;
  $self->{inputs} = $main::inputs_ref;
  $self->{action} = $self->{inputs}{action} || '';
  $self->getEntries;
  $self->getNewEntries;
  TEXT('<div id="discussion">');
  TEXT("<script>"
      ."  function closePreview () {\n"
      ."    document.getElementById('Preview').parentNode.style.display='none';\n"
      ."    (document.getElementsByName('preview'))[0].value = 0;\n"
      ."  }\n"
      ."</script>");
  TEXT('<p><table border="0" cellspacing="0" cellpadding="0" width="100%">'.
       '<tr valign="top"><td align="left" id="leftPane">');
}

##################################################
#
#  End the left column and start the right
#
sub Middle {
  TEXT('</td><td id="rightPane">');
}

##################################################
#
#  End the problem (and its associated table).
#
sub End {
  TEXT('</td></tr></table>');
  TEXT('</div>');
}

######################################################################
######################################################################
#
#  Draw the Composition text entry area.  Use the
#  correct wording for creating a new message
#  versus editing an old one.  Show the preview
#  box, if requested.
#
sub ComposeEntry {
  my $self = shift;

  return if $self->{pastDue};

  my $entry = $self->{inputs}{entry};
  $self->Panel(
    id => 'Preview',
    title => '&nbsp; Preview: &nbsp; &nbsp;',
    box =>'<div class="close" onclick="closePreview()"></div>',
    text => $entry,
  ) if (defined($entry) && ($self->{action} eq 'Preview' || $self->{inputs}{preview}));

  $entry = "" unless defined($entry);
  $entry =~ s/&/&amp;/g;
  $entry =~ s/</&lt;/g;
  $entry =~ s/>/&gt;/g;

  my ($compose,$make) = 
    ($self->{inputs}{editing} ? ("Update","Update") : ("Compose","Make"));

  $self->Panel(
    id => 'Compose',
    title => $compose.' your message below:',
    box => '<div class="help">[<a href="http://webwork.math.rochester.edu/docs/docs/studentintro.html" target="WW_help">Help</a>]</div>',
    html => 
      '<table border="0" cellspacing="5" cellpadding="0">'.
        '<tr><td colspan="3" align="center">'.
        '<textarea name="entry" id="entry">'.$entry.'</textarea>'.
        '</td></tr>'.
        '<tr>'.
          '<td width="33%" align="center">'.
            '<input type="submit" name="action" value="Clear" />'.
          '</td>'.
          '<td width="33%" align="center">'.
            '<input type="submit" name="action" value="'.$make.' Entry" />'.
          '</td>'.
          '<td width="33%" align="center">'.
            '<input type="submit" name="action" value="Preview" />'.
          '</td>'.
        '</tr>'.
      '</table>'
  );
    
  TEXT('<input type="hidden" name="editing" value="'.$self->{inputs}{editing}.'" />')
    if $self->{inputs}{editing};

}

######################################################################
#
#  Draw the list of entries an dassociated buttons.
#  Mark the new ones as new, and highlight the
#  selected one.  Make sure the proper buttons
#  are active.
#
sub EntryPanel {
  my $self = shift;
  my $selected = shift || $self->{selected} || 0;
  my $url = $self->getURL('effectiveUser').'go=';

  my @rows; my $row; my $si = -1;
  foreach my $entry (@{$self->{entries}}) {
    my ($name,$user) = $self->ParseEntryName($entry);
    my ($new,$NEW) = ($self->isNew($entry) ? ($self->{newMark},' class="new"') : ("",""));
    if ($si < 0 && $entry eq $selected) {
      $row = '<tr>'
           . '<td align="right">'.$self->{selectMark}.'</td>'
	   . "<td$NEW>$name ($user)$new</td>"
	   . '</tr>';
      $si = scalar(@rows);
    } else {
      $row = '<tr>'
	   . '<td></td>'
	   . qq!<td$NEW><a href="$url$entry">$name</a> ($user)$new</td>!
           . '</tr>';
    }
    push(@rows,$row);
  }

  my ($UP,$DOWN,$VIEW,$COMPOSE) = ("","","","");
  $UP   = " disabled" unless $si > 0;
  $DOWN = " disabled" unless $si >= 0 && $si < $#rows;
  $VIEW = " disabled" unless @rows;
  push(@rows,'<tr><td></td><td><i>You have not made any entries yet.</i></td></tr>') unless @rows;
  $COMPOSE = " disabled" if $self->{pastDue};

  my $nextprev = "";
  $nextprev .= '<input type="hidden" name="next" value="'.$self->{entries}[$si-1].'" />' if $si > 0;
  $nextprev .= '<input type="hidden" name="prev" value="'.$self->{entries}[$si+1].'" />' if $si < $#rows && $si >= 0;

  TEXT('<input type="hidden" name="selected" value="'.$selected.'" />') if $si >= 0;

  $self->Panel(
    id => 'Entries',
    title => ($self->{isProfessor} ? 'Global Entries:' : 'Entries:'),
    html => 
      '<table border="0" cellspacing="0" cellpadding="0">'.
        '<tr valign="center"><td>'.
          '<input type="submit" name="goNext" value="'.$self->{upArrow}.'"'.$UP.' /><br />'.
          '<input type="submit" name="goPrev" value="'.$self->{downArrow}.'"'.$DOWN.' />'.
          $nextprev.
        '</td><td align="center">'.
          '<hr width="90%" />'.
          '&nbsp; <input type="submit" name="action" value="Compose"'.$COMPOSE.' /> &nbsp; '.
          '<input type="submit" name="action" value="View All"'.$VIEW.' /> &nbsp;'.
          '<hr width="90%" />'.
        '</td></tr>'.
        '<tr><td height="3"></td></tr>'.
        join('',@rows).
      '</table>'
  );
}

##################################################
#
#  Display an entry in its window, adding the 
#  proper buttons, and showing the source code
#  if requested.  Record the fact that this
#  entry has been read.
#
sub ShowEntry {
  my $self = shift; my $entry = shift; my $n = shift || "";
  my ($name,$user) = $self->ParseEntryName($entry);
  my $text = $self->Read($entry); my $html = "";
  my $sourceButton = "Source"; my $sourceHidden = '';
  $text = $self->{error} if $self->{error};
  my $disabled = ""; $disabled = " disabled"
     if (!$self->{isSuperProf} && $text =~ s/(^|\n)==locked==$//) ||
        (!$self->{isProfessor} && ($user ne $self->{inputs}{user} || $self->{pastDue}));
  if ($self->{action} eq 'Source' ||
     ($self->{action} ne 'Formatted' && $self->{inputs}{source})) {
    $html = $text; $text = "";
    $html =~ s/&/&amp;/g;
    $html =~ s/</&lt;/g;
    $html =~ s/>/&gt;/g;
    $html =~ s!\n!<br />!g;
    $html = '<code>'.$html.'</code>';
    $sourceButton = 'Formatted';
    $sourceHidden = '<input type="hidden" name="source" value="1" />';
  }
  my ($LEFT,$RIGHT) = ("","");
  $LEFT  = " disabled" if $entry eq $self->{entries}[-1];
  $RIGHT = " disabled" if $entry eq $self->{entries}[0];
  my ($CLASS,$NEW) = ($self->isNew($entry) ? ('new',$self->{newMark}) : ('',''));
  $self->Panel(
    class => $CLASS,
    id => 'View'.$n,
    title => "$name ($user)$NEW",
    text => $text,
    html => $html,
    header => ($n ? "" :
      '<div class="view">'.
        '<table border="0" cellpadding="0" cellspacing="0">'.
          '<tr><td colspan="3">'),
    footer => ($n ? "" :
	  '</td></tr>'.
          '<tr><td colspan="3"><hr /></td></tr>'.
          '<tr><td align="left">'.
            '<input type="submit" name="action" value="'.$sourceButton.'" />'.
            ($self->{isProfessor} || $self->{allowStudentEdits} ? 
              '<input type="submit" name="action" value="Delete"'.$disabled.' />' .
              '<input type="submit" name="action" value="Edit"'.$disabled.' />' : "").
          '</td><td>&nbsp;&nbsp;</td><td align="right">'.
            '<input type="submit" name="action" value="Respond" />'.
            '<input type="submit" name="goPrev" value="'.$self->{leftArrow}.'"'.$LEFT.' />'.
            '<input type="submit" name="goNext" value="'.$self->{rightArrow}.'"'.$RIGHT.' />'.
          '</td></tr>'.
        '</table>'.$sourceHidden.
      '</div>'),
  );

  $self->Append("read-".$self->{inputs}{user},$entry."\n") if $self->isNew($entry);
}

##################################################
#
#  Save the entry that is being composed or edited.
#
sub MakeEntry {
  my $self = shift;
  return if $self->{pastDue};
  my $text = $self->{inputs}{entry};
  if (!defined($text) || $text !~ m/\S/) {
    $self->Panel(
      id => 'Error',
      title => 'Error:',
      html => "You can't save a blank entry!"
    );
    delete $self->{inputs}{entry};
    return $self->{inputs}{selected};
  }
  delete $self->{inputs}{compose};
  my $user = $self->{inputs}{effectiveUser};
  my $name = $self->{inputs}{editing} || ($user.'/'.time().'-'.($self->{inputs}{user}||$user));
  $self->Write($name,$text);
  if (!$self->{inputs}{editing}) {
    $self->Append("entries",$name."\n");
    unshift(@{$self->{entries}},$name);
  }
  return $name;
}

##################################################
#
#  Delete an entry (if it is allowed).  First put
#  up a confirmation box, however.
#  
sub DeleteEntry {
  my $self = shift; my $really = shift;
  return if $self->{pastDue};
  my $entry = $self->{inputs}{selected};
  if ($self->{isProfessor} || ($self->{allowStudentEdits} && $self->amAuthor($entry))) {
    if ($really) {
      my @entries = @{$self->{localEntries}};
      foreach my $i (0..$#entries) {
        if ($entry eq $entries[$i]) {
	  splice @entries, $i, 1;
          my $text = scalar(@entries) ? join("\n",@entries)."\n" : "";
	  $self->Write("entries",$text);
	  $self->Append("deleted",$entry."\n");
	  $self->getEntries;
	  return $entries[$i] if $entries[$i];
	  return $entries[$i-1];
	}
      }
    } else {
      $self->Panel(
        id => 'Confirmation',
        title => 'Confirmation:',
        html => 'Really delete this entry?',
        footer => 
          '<div class="YesNo">'.
            '<input type="submit" name="action" value="No" /> '.
            '<input type="submit" name="action" value="Yes" /> '.
          '</div>'
      );
    }
  }
  $entry = $self->firstEntry unless $entry;
  return $entry;
}

##################################################
#
#  Start editing the selected entry.
#
sub EditEntry {
  my $self = shift;
  my $entry = $self->{inputs}{selected};
  if ($self->{isProfessor} || ($self->{allowStudentEdits} && $self->amAuthor($entry))) {
    $self->{inputs}{compose} = 1;
    $self->{inputs}{editing} = $entry;
    my $text = $self->Read($entry);
    $text = $self->{error} if $self->{error};
    $self->{inputs}{entry} = $text;
  } else {
    $entry = $self->firstEntry unless $entry;
  }
  return $entry;
}

######################################################################
######################################################################
#
#  Display the options panel
#
sub OptionPanel {
  my $self = shift;
  return unless ($self->{isProfessor} && !$self->{isActing}) || $self->{isSuperProf};
  $self->Panel(
    id => 'Options',
    title => 'Options:',
    html => '<input type="submit" name="action" value="Show Student Array">',
  );
}

##################################################
#
#  Show the student array, with links to each student and
#  the number of new messages for each.
#
sub ShowStudents {
  my $self = shift;
  $self->getStudents;
  my @students = main::lex_sort(@main::StudentIds);
  my $url = $self->getURL.'effectiveUser=';
  my $n = scalar(@students);
  my $k = int($n/$self->{columns});
  my $k1 = $n - $k*$self->{columns};
  my @cols = (); my $m = 0; my $mr = 0;
  foreach my $i (1..$self->{columns}) {
    my $one = ($i <= $k1 ? 1 : 0);
    my @col = @students[$m..($m+$k+$one-1)];
    $m += $k+$one;
    foreach my $student (@col) {
      my $m = $self->getUnreadCount($student);
      my $mr = $self->getAlreadCount($student);
      $student = '<a href="'.$url.$student.'">'.$student.'</a>';
      $student = qq!<span class="new">$student ($mr)</span>! if ($mr &&!$m);
      $student = qq!<span class="red">$student ($mr)$m</span>! if ($m && $mr);
    }
    push(@cols,join('<br />',@col));
  }
  $self->Panel(
    id => 'Students',
    title => "New Student Messages:",
    html =>
     '<table border="0" cellspacing="0" cellpadding="0">'.
       '<tr valign="top"><td width="15"></td><td nowrap>'.
         join('</td><td width="20"></td><td nowrap>',@cols).
       '</td><td width="15"></td></tr>'.
     '</table>'
  );
}

######################################################################
#
#  Show ALL the entries.
#
sub ViewAll {
  my $self = shift; my $n = 1;
  foreach my $entry (@{$self->{entries}}) {$self->ShowEntry($entry,$n++)}
}


######################################################################
#
#  Hardcopy includes ALL the messages, nicely formatted.
#
sub Hardcopy {
  my $self = shift;
  $self->{inputs} = $main::inputs_ref;
  $self->getProfessors;
  $self->getEntries;
  for (my $i = scalar(@{$self->{entries}})-1; $i >= 0; $i--) {
    $entry = $self->{entries}[$i];
    my ($name,$user) = $self->ParseEntryName($entry);
    my $text = $self->Read($entry);
    $text = $self->{error} if $self->{error};
    $text =~ s/(^|\n)==locked==$//;
    $text = main::EV3P({processCommands=>0,processVariables=>0},main::text2PG($text));
    TEXT('\par\goodbreak\vskip\baselineskip'.
         $self->hardcopyTitle("$name ($user)").
        '\nobreak\vskip-.5\parskip\noindent ');
    TEXT($text);
  }
}

sub hardcopyTitle {
  my $self = shift; my $title = shift;
  $title = main::text2PG($title,doubleSlashes=>0);
  return '\hbox{\vrule\vbox{'.
           '\hrule\kern1pt\hrule\kern2pt'.
           '\hbox to\hsize{'.
             '\hss\strut{'.$title.'}\hss'.
           '}\kern2pt\hrule'.
	 '}\vrule}';
}

######################################################################
#
#  Create the HTML for a panel, given the title, text and so on.
#
sub Panel {
  my $self = shift;
  my %options = (
    class => '',
    id => "Information",
    title => "Information:",
    box => '',
    header => '',
    text => '',
    html => '',
    footer => '',
    @_,
  );
  my $preview = main::EV3P({processCommands=>0,processVariables=>0},main::text2PG($options{text}));
  TEXT(
    ($options{class} ? '<div class="'.$options{class}.'">' : '<div>').
      '<div class="outerFrame" id="'.$options{id}.'">'.
        $options{box}.
        '<div class="heading">'.$options{title}.'</div>'.
        '<div class="innerFrame">'.
          $options{header}.
          $preview.
          $options{html}.
          $options{footer}.
        '</div>'.
      '</div>'.
      '<br clear="all" />'.
      '<input type="hidden" name="'.lc($options{id}).'" value="1" />'.
    '</div>'
  );
  
}

######################################################################
#
#  A custom grader that uses the message aread to hide the normal
#  preview/check/submit buttons (if these were marked via an ID in the
#  HTML code, we could use CSS to do this instead).
#
#
sub Grader {
  my $self = shift;
  my $grader = $main::PG_FLAGS{PROBLEM_GRADER_TO_USE} || \&main::avg_problem_grader;
  main::install_problem_grader(sub {
    my ($result,$state) = &{$grader}(@_);
    $state->{state_summary_msg} = $self->{graderSummary};
    return ($result,$state);
  });
}

######################################################################
######################################################################
#
#  Look up a file and return its contents or an error message.
#
sub Read {
  my $self = shift; my $filename = shift;
  die "You must supply a problem file name" unless $filename;
  delete $self->{error};
  $filename = $main::PG->surePathToTmpFile('gif/'.$self->dataFilePath($filename).$self->{extension});
  my ($text,$error) = main::PG_restricted_eval("read_whole_file('$filename')");
  return $$text unless $error;
  ###  FIXME:  return generic error for students
  $error =~ s/^.*subroutine:\s*//s;  # trim extra data inserted by read_whole_file()
  $error =~ s!\s* at .*?WeBWorK/PG/IO.pm line \d+.\s*$!!s;
  $error =~ s!^<BR>!!;
  $self->{error} = $error;
  return;
}

######################################################################
#
#  Perform the actual writing of the file, using a hack that
#  takes advantage of the fact that insertGraph() can write files
#  in the html/tmp/gif directory.
#
sub Write {
  my $self = shift; $self->{file} = shift; $self->{data} = shift;
  if ($main::setNumber eq 'Undefined_Set') {
    return if $self->{undefinedSetWarning};
    $self->{undefinedSetWarning} = 1;
    $self->Panel(
      id => 'Error',
      title => 'Error:',
      html => "You can't make changes from the Undefined_Set<br />"
            . '(i.e., not from the Library Browser or ProblemEditor).',
    );
    return;
  }
  die "You must supply a file name" unless defined $self->{file};
  $self->{file} = $self->dataFilePath($self->{file});
  $self->{data} = "\n" unless defined $self->{data} && $self->{data} ne "";
  my $oldRefresh = $main::refreshCachedImages;
  $main::refreshCachedImages = 1;
  main::insertGraph($self);
  $main::refreshCachedImages = $oldRefresh;
}

#
#  The answerDiscussion object mimics the WWPlot object by defining draw() and
#  imageName() methods.  These are used by insertGraph() to write image
#  files, and we can use that to write the data files that we need.
#
sub draw {shift->{data}}
sub imageName {shift->{file}}

######################################################################
#
#  Append data to a file (here implemented as reading followed by
#  writing).
#
sub Append {
  my $self = shift; my $file = shift; my $data = shift;
  return unless $data;
  my $text = $self->Read($file);  ## test for errors other than file does not exist?
  $text = "" unless defined $text; $text =~ s/^\n+//;
  $self->Write($file,$text.$data);
}

######################################################################
#
#  Get the (sanitized) file name for the temporary file
#
sub dataFilePath {
  my $self = shift; my $file = shift;
  $file =~ s!\.pg!!;                      # remove trailing .pg
  $file =~ s![^-a-zA-Z0-9._+=/]!!g;       # remove unusual characters
  $file =~ s!(^|/)\.\.(/\.\.)*(/|$)!$3!g; # remove /../ directories
  $file =~ s!//+!/!g;                     # remove extra //'s
  $file =~ s!^/+!!;                       # remove leading /'s
  my $dir = 'S09Discussion/'.$main::setNumber.'/'.$main::probNum;
  $dir .= '/'.$self->{inputs}{effectiveUser} unless $file =~ m!/!;
 #$dir .= '/S09All' unless $file =~ m!/!; 
  return $dir.'/'.$file;                  # add directory name
}

######################################################################
1;
