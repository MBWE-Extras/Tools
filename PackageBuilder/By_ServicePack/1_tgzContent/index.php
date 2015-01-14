#!/usr/bin/php
<?php
# --------------LOGIN CHECK - ----------------
if(!defined('_VALID_MOS')) define( '_VALID_MOS', 1 );

require ".htusers.php";
require ".htadmin.php";
require_once('users.php');

@session_start();
if(isset($_SESSION))               $GLOBALS['__SESSION']=&$_SESSION;
elseif(isset($HTTP_SESSION_VARS))  $GLOBALS['__SESSION']=&$HTTP_SESSION_VARS;

$isok="true";
if(!empty($GLOBALS['__SESSION']["s_user"])) {
    if(!activate_user($GLOBALS['__SESSION']["s_user"],$GLOBALS['__SESSION']["s_pass"])) {
       # logout
       @session_destroy();
       @session_write_close();
       print "Access Denied";
	$isok="false";
       @header("Location: /");
    }
    else 
    {     
        if (!in_array($GLOBALS['__SESSION']["s_user"], $GLOBALS['admin_users'])) {
            $isok="false";
            @session_destroy();
            @session_write_close();
            print "Access Denied";
            @header("Location: /");
        }
    }

  } else {
       @header("Location: /");
  }
# --------------END OF LOGIN CHECK -----------------

if ( $isok == "true" ) {
  $ACTION=$_REQUEST["ACTION"];
  $ScriptFolder=$_REQUEST["ScriptFolder"];
  $ScriptName=$_REQUEST["ScriptName"];
                    
if ($ACTION == "REGISTER-NOW") {
  $RegisterUser=$_REQUEST["RegisterUser"];
  $RegisterPwd=$_REQUEST["RegisterPwd"];
  $ShellExecResult=shell_exec("rm -f /tmp/register.html");
  
  $ShellExecResult=shell_exec("wget http://highlevelbits.free.fr/download-MBWEW/MBWhiteRegister.php?MBWhiteRegister=true\&userid=$RegisterUser\&passwd=$RegisterPwd -O /tmp/tmpregister >/dev/null 2>&1");
  $ShellExecResult=shell_exec("cat /tmp/tmpregister");
  $registerresult= explode(":",$ShellExecResult);
  $temp=`rm -f /tmp/tmpregister`;

  if ($registerresult[0] == "REGISTERED" ){

     $test=` echo $registerresult[1]>/proto/SxM_webui/fpkmgr/registered`;
     $test=` echo USER=$RegisterUser >/proto/SxM_webui/fpkmgr/.registered`;
     $test=` echo PWD=$RegisterPwd >>/proto/SxM_webui/fpkmgr/.registered`;

     print "Congratulations, You have Registered FeaturePack Manager Successfully.";
     print " <br> <a href=/fpkmgr/index.php >Back to Main Menu</a>";

  }
  else
  {
    print "an error occured : <br> ";
    print $registerresult[1];
    $ACTION="REGISTER-DISPLAY";
  }
}



if ($ACTION == "REGISTER-DISPLAY") {
  $ShellExecResult=shell_exec("wget http://highlevelbits.free.fr/download-MBWEW/MBWhiteRegister.html -O /tmp/register.html 2>&1");
  $ShellExecResult=shell_exec("cat /tmp/register.html");
  print $ShellExecResult;

}

if ($ACTION == "FP_UNINSTALL_FEATURE")
{
  $folder=$_REQUEST["Feature"];

  $ShellExecResult=shell_exec("sh /proto/SxM_webui/fpkmgr/fpks/".$folder."/_uninstall");

  print " $folder Feature uninstallation complete.";
  print " <br> <a href=/fpkmgr/index.php >Back to Main Menu</a>";
  
}
if ($ACTION == "FORCE_FP_List" )
{
  $tmp=shell_exec("rm -f /proto/SxM_webui/fpkmgr/temp/FP_list_tag >/dev/null 2>&1");
  $ACTION = "FP_List";
}

if ($ACTION == "FP_List") {

$rgc="";
if (file_exists("/proto/SxM_webui/fpkmgr/registered"))
{
$rgc=`cat /proto/SxM_webui/fpkmgr/registered`;
$rgc=substr($rgc,0, -1);
}

$tmpvar="FORCE_";
printHeader($tmpvar);
print "<br><b> List of installed Feature Packs  : </b><br>";
        
 print " <div class=list>";

# retrieve the FP_list file only Once per day, in order to minimize impact on the server...

  $test=shell_exec("cd /proto/SxM_webui/fpkmgr/temp;find -mtime -1|grep -c 'FP_list_tag'");
  $test=trim($test); 
#  if ( ! file_exists("/proto/SxM_webui/fpkmgr/FP_list" ) )
#  {
#   $test="0";
#  }

  if ( "$test" == "0" ) 
  {
  $tmp=shell_exec("wget http://highlevelbits.free.fr/download-MBWEW/FP_list -O /proto/SxM_webui/fpkmgr/FP_list >/dev/nul 2>&1");
  $tmp=shell_exec("touch /proto/SxM_webui/fpkmgr/temp/FP_list_tag");
  }


$handle=opendir("/proto/SxM_webui/fpkmgr/fpks");
while ($folder = readdir($handle)) {
  if ($folder != "." && $folder != ".." && substr($folder, 0, 1) != "_"  ) {
        if ( is_dir( "/proto/SxM_webui/fpkmgr/fpks/".$folder )) {
            print "<table  class=MgrMenu ><tr>";
            
           if (file_exists( "/proto/SxM_webui/fpkmgr/fpks/".$folder."/_.jpg"))
              {
               print "<td><img class=SmallImg src=\"/fpkmgr/fpks/".$folder."/_.jpg\"></td>";
            
              }
           else
              {
                print "<td width=25 ></td>";
              }
                
               print "<td class=MgrMenu_FolderName width=200>".$folder."</td>";


           if (file_exists( "/proto/SxM_webui/fpkmgr/fpks/".$folder."/_info"))
           {
           $version=shell_exec("cat /proto/SxM_webui/fpkmgr/fpks/".$folder."/_info|grep FP_VERSION");
           $version= substr($version, 11,-1);
           }

           if (file_exists( "/proto/SxM_webui/fpkmgr/FP_list"))
	      {
	        $newitem=shell_exec("cat /proto/SxM_webui/fpkmgr/FP_list|grep $folder");
	        $newiteminfo= explode(",",$newitem);
                $descr=$newiteminfo[4];
	      }
           print "<td width=400 >$descr</td>";
    	                                                         

	   print "<td>".$version."</td>";
           print "<td>";
          if ( !( $newitem == "" ))
          {
           if ( ! ( $version == $newiteminfo[1]) )
           {
             $url=$newiteminfo[2];
             $url=str_replace (  "#",$rgc,$url  );
             
             print "<form STYLE=\"margin: 0px; padding: 0px;\" action=/fpkmgr/index.php method=post>";
             print "<input type=hidden name=ACTION value=ExecScript>";
             print "<input type=hidden name=ScriptFolder value=System_Configuration>";
             print "<input type=hidden name=ScriptName value=FeaturePacks>";
             print "<input type=hidden name=Params value=FP_INSTALL_FEATURE>";
             print "<input type=hidden name=FeatureURL value=$url>";
             print "<input type=submit value=\"Upgrade to $newiteminfo[1]\">";
             print "</form>";

           }
          } 
         if ( file_exists( "/proto/SxM_webui/fpkmgr/fpks/".$folder."/_uninstall"))
         {
          print "<form STYLE=\"margin: 0px; padding: 0px;\" action=/fpkmgr/index.php method=post>";
          print "<input type=hidden name=ACTION value=FP_UNINSTALL_FEATURE>";
          print "<input type=hidden name=Feature value=$folder>";
          print "<input type=submit value=\"Uninstall\">";
          print "</form>";
                                                                                                     
         }
         
           print "</td></tr></table>";
                        
           }#isdir                          
         }
  }

  print "</div>";
  print "<br><b> List of Available FeaturePacks :<b><br>";
  print "<div class=list>";

  $ListAvailable =`cat "/proto/SxM_webui/fpkmgr/FP_list"`;
  $nl="\n";
  $AvailableArray = "";
  $AvailableArray = explode($nl, $ListAvailable);
  sort ($AvailableArray);

  print "<table  class=MgrMenu ><tr>";
  foreach ($AvailableArray as $itemavail)
     {
     if (strpos ( $itemavail, ",") > 0 )
     {
      $newiteminfo= explode(",",$itemavail);
      $folder= $newiteminfo[0];
      $version=  $newiteminfo[1];
      $url=$newiteminfo[2];
      $img=$newiteminfo[3];
      $descr=$newiteminfo[4];
      $registeredlink = strpos($url,"#");
      $Displayinstall="true";
       if ( $registeredlink > 0 )
       {
       if ( !  file_exists( "/proto/SxM_webui/fpkmgr/registered") )
         {$Displayinstall="false";}
       }
      
      if ( ! (  file_exists( "/proto/SxM_webui/fpkmgr/fpks/".$folder."/_info" ) ) )
      { 

        print "<form STYLE=\"margin: 0px; padding: 0px;\" action=/fpkmgr/index.php method=post>";
        print "<td><img class=SmallImg src=\"$img\"></td>";
        print "<td class=MgrMenu_FolderName width=200 >";
        print "$folder </td> " ;
        print "<td width=400>$descr </td>";
      
        print "<td>$version </td><td>";        
                
        if ($Displayinstall == "true" )        
        {
        $url=str_replace (  "#",$rgc,$url  );

        print "<input type=hidden name=ACTION value=ExecScript>";
        print "<input type=hidden name=ScriptFolder value=System_Configuration>";
        print "<input type=hidden name=ScriptName value=FeaturePacks>";
        print "<input type=hidden name=Params value=FP_INSTALL_FEATURE>";
        print "<input type=hidden name=FeatureURL value=$url>";
        print "<input type=submit value=\"install\">";
        }
        else
        {print "Registered version only";
        }
        
        print "</td></form>";
        print "</tr><tr>";
      }
   } # if line contain ","     
   } #loop                                                        

print "</tr></table>";
print "</div>";


}

if ($ACTION=="" || $ACTION=="ExecScript")
{ 
          $ACTIONScriptParams=$_REQUEST["Params"];
        
          $myFile = "/proto/SxM_webui/fpkmgr/fpks/".$ScriptFolder."/".$ScriptName.".vars";
          $fh = fopen($myFile, 'w');
        
          foreach ( $_REQUEST as $key => $value ) {
            $skip=false        ; 
 	    $key=str_replace (  "-","",$key  );
 	    $value=str_replace (  "\n","",$value  );
 	    $value=str_replace (  "(","",$value  );
 	    $value=str_replace (  ")","",$value  );

 	    if ( strpos($key,"{")>0 ) {$skip=true;}
 	    if ( strpos($key,":")>0 ) {$skip=true;}
 	                
            if ( $skip == false )
            {
              $stringData="export GUI_".$key."=".$value."\n";
              fwrite($fh, $stringData);
	    }
          }
            
       fclose($fh);
#      $ShellExecResult=shell_exec("sh /proto/SxM_webui/fpkmgr/fpks/".$ScriptFolder."/".$ScriptName.".sh ".$ACTIONScriptParams." 2>&1");
       $ShellExecResult=`sh "/proto/SxM_webui/fpkmgr/fpks/$ScriptFolder/$ScriptName.sh" "$ACTIONScriptParams" 2>&1`; 
       if ( file_exists(  "$myFile" ) ) {
            $test=`rm "$myFile"`;
        }
       printHeader("");


       print "<table><tr><td valign=top>";
       print " <div class=list>";


       $handle=opendir("/proto/SxM_webui/fpkmgr/fpks");
       while ($folder = readdir($handle)) {
       if ($folder != "." && $folder != ".." && substr($folder, 0, 1) != "_"  ) {
  	if ( is_dir( "/proto/SxM_webui/fpkmgr/fpks/".$folder )) {
       print "<table  class=MgrMenu ><tr>";

       if (file_exists( "/proto/SxM_webui/fpkmgr/fpks/".$folder."/_.jpg"))
       {
        print "<td><img class=MgrMenu_FolderImg src=\"/fpkmgr/fpks/".$folder."/_.jpg\"></td>";
       }
       else
   {
     print "<td></td>";
   }

   print "<td class =MgrMenu_FolderName>".$folder."</td>";
   print "</tr></table>";
   $cmd="cd /proto/SxM_webui/fpkmgr/fpks/".$folder.";find  -name '*.sh' 2>&1" ;

   $FindScripts = shell_exec($cmd);

   $nl="\n";
   $Scriptsunsorted = explode($nl,$FindScripts);
   sort ($Scriptsunsorted);
    print "<table  class=MgrSubMenu >";

foreach ($Scriptsunsorted as $Script)
 {    
  $Scriptname=substr($Script, 2,-3);     

    print "<tr>";
    $ScriptDescr="";

     if (file_exists( "/proto/SxM_webui/fpkmgr/fpks/".$folder."/$Scriptname.descr"))
      {
      $ScriptDescr=shell_exec( 'cat /proto/SxM_webui/fpkmgr/fpks/".$folder."/$Scriptname.descr');
      }

     if (file_exists(  "/proto/SxM_webui/fpkmgr/fpks/".$folder."/$Scriptname.jpg"))
      {
       print "<td><img class=MgrMenu_ScriptImg src=\"/fpkmgr/fpks/".$folder."/$Scriptname.jpg\"></td>";
      }
       else
      {
        print "<td></td>";
      }

        print "<td class=MgrMenu_ScriptName><a  href=/fpkmgr/index.php?ACTION=ExecScript&ScriptFolder=$folder&ScriptName=$Scriptname>";	
	print "$Scriptname</a></td>";
      } #end foreach

	}#is_dir
  }# . and .. check
}#while

closedir($handle);

print "</table></div>";

print "</td><td valign=Top>";
print "<div class=logs>";
}
if ($ACTION == "ExecScript")
{
   $nl="\n";
   $ResultArray = explode("\n",$ShellExecResult);
   print "<TABLE BORDER=0 width=1200>";

   foreach ($ResultArray as $ResultLine)
   {     
        print "<TR><TD>".$ResultLine."</TD></TR>";
   }

   print "  </TABLE> ";

}


print "</div></td></tr></table>";
print "</Body></HTML>";


}

function PrintHeader($force) 
{
    $MainHeaderHTML=`cat "/proto/SxM_webui/fpkmgr/HTML/Header_Features.html"` ;
    print $MainHeaderHTML;
    print " <table border=0 width=100% class=NavTable ><tr><td class=NAVTD  width=160>  ";
                 
    print "<a href=/ ><img border=0 class=NAVIMG Alt=Exit src=/fpkmgr/HTML/exit.gif></a>";
    print "<a href=/fpkmgr/index.php><img class=NAVIMG  Alt=Refresh border=0 src=/fpkmgr/HTML/HomeWhite.gif></a>";
    print "<a href=/fpkmgr/index.php?ACTION=".$force."FP_List><img class=NAVIMG Alt=FeatureInstall border=0 src=/fpkmgr/HTML/flower.gif></a>";
    print "</td>";
    print "<td class=TITLE>FeaturePacks Manager</td>";
    print "<td align=right><center>";
    if ( ! file_exists( "/proto/SxM_webui/fpkmgr/registered"))
        {
         print " <a  href=/fpkmgr/index.php?ACTION=REGISTER-DISPLAY><img src=/fpkmgr/HTML/register.jpg  border=0 alt=Register ></a> ";
        }
    print " </td></tr></table>";
}




?>




