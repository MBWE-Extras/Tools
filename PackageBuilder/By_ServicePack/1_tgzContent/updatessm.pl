# this perl script will modify index.php to add the Feature Manager link...

if ( ! -e "/proto/SxM_webui/index.php.ori" )
  {
  $test = `cp "/proto/SxM_webui/index.php" "/proto/SxM_webui/index.php.ori"`;


#$test=` cat /proto/SxM_webui/index.php|grep -c fpkmgr`;
#if ( "$test" eq "0" ) 


  open (FH, "/proto/SxM_webui/index.php.ori");
  @files=<FH>;
  close(FH); 


  $Pattern1= "} else if (\$GLOBALS['__POST']['login_mode'] == 'copymanager') {";
  $Pattern2= "\$is_success_for_login = TRUE;";
  $Addstr="              } else if (\$GLOBALS['__POST']['login_mode'] == 'fpkmgr') {\n\              \$is_success_for_login = TRUE;\n";
  $NewIndex=AddStrAfterPattern($Pattern1,$Pattern2,"",$Addstr);
  @files=split(/\n/,$NewIndex);


  $Pattern1= "} else if (\$GLOBALS['__POST']['login_mode'] == 'copymanager') {";
  $Pattern2= "\@header(\"Location: \" . \$GLOBALS['http_host'] . \"/cpsync/index.php{\$nLUS}\");";
  $Addstr="            } else if (\$GLOBALS['__POST']['login_mode'] == 'fpkmgr') {\n              \@header(\"Location: \" . \$GLOBALS['http_host'] . \"/fpkmgr/index.php\");\n";
  $NewIndex=AddStrAfterPattern($Pattern1,$Pattern2,"\n",$Addstr);

  @files=split(/\n/,$NewIndex);

  $Pattern1= "php endif";
  $Pattern2= "\$lang['login']['copymanager']";
  $Addstr="        <option value=\"fpkmgr\">FeaturePacks Manager</option>\n";
  $NewIndex=AddStrAfterPattern($Pattern1,$Pattern2,"\n",$Addstr);

  open(LOGF, ">/proto/SxM_webui/index.php");
  print LOGF "$NewIndex";
  close (LOGF); 

  }


sub AddStrAfterPattern()
{
  my $result="";
  # Search a pattern : 
  $Pattern1= $_[0];
  $Pattern2= $_[1];
  $ffl=$_[2];
  $Addstr=$_[3];

  $CurPattern=$Pattern1;
  $level="PAT1";

  foreach $indexline (@files)
  {
      $result .= "$indexline$ffl";
      $n = index($indexline,"$CurPattern");
    
      if ($level  eq "PAT2" )
      {
        if ( $n >0 )
        {
        $result .= $Addstr;
        $CurPattern=$Pattern1;
        $level="PAT1";
	$n= 0;
        }
      else
        {
        $CurPattern=$Pattern1;
        $level="PAT1";
	$n= 0;
        }
      }
        
      if ( ( $n >0 ) && ($level  eq "PAT1" ) )
        {
        $CurPattern=$Pattern2;
        $level="PAT2";
	$n= 0;
        }
 }
return $result;
}

