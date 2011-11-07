(:------------------------------------------------------------------------:
   Copyright (c) 2010, Intellectual Reserve, Inc.  All rights reserved. 
 :------------------------------------------------------------------------:)
xquery version "1.0-ml";

module namespace install = "xqdebug/install-functions";
import module namespace iv="/xqdebug/shared/common/invoke" at "../shared/common/invoke/invokeFunctions.xqy";
import module namespace sec="http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
import module namespace util = "http://marklogic.com/xdmp/utilities" at "/MarkLogic/utilities.xqy";
declare namespace zip="xdmp:zip";

(:~
  Load the specified zip file into the specified database directory.
  @param  $dbname Target database.
  @param  $dirname  Target directory.
  @param  $file     Document node of zip file to unload.
  @return empty-sequence()
~:)
declare function install:loadZip( $dbname as xs:string, $dirname as xs:string, $file )
as empty-sequence()
{
  if ( xdmp:database-name( xdmp:database() ) ne $dbname )
  then iv:invoke( $dbname, xdmp:function( xs:QName("install:loadZip"), "" ), $dbname, $dirname, $file )
  else (
    for $name in xdmp:zip-manifest( $file )/zip:part[@uncompressed-size ne 0]/fn:data(.)
    let $filename := util:basename( $name )
    return
      if ( fn:starts-with($name, "__MACOS") or fn:contains( $name, ".svn/" ) or fn:starts-with( $filename, "." ) )
      then ()
      else if ( fn:ends-with( $filename, ".txt" ) )
      then 
        xdmp:document-insert( 
          fn:concat( $dirname, $name ), 
          xdmp:zip-get( $file, $name,  <options xmlns="xdmp:zip-get"> <format>text</format> <encoding>auto</encoding> </options> )
        )
      else xdmp:document-insert( fn:concat( $dirname, $name ), xdmp:zip-get( $file, $name ) )
  )
};

(:~
  Return user configuration information
  @return Selected user information from security database.
~:)
declare function install:getUsers()
{
  if ( xdmp:database-name(xdmp:database()) ne "Security" )
  then
  	(: Need to read user info from the "Security" database. :)
  	iv:invoke( "Security", xdmp:function(xs:QName("install:getUsers"), "") )
	else
    for $user in fn:collection(sec:users-collection())/sec:user
    return 
      element sec:user {
      	$user/( sec:user-id | sec:user-name | sec:description | sec:role-ids | sec:permissions | sec:collections)
      }
};

