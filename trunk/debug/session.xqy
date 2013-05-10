(:------------------------------------------------------------------------:
   Copyright (c) 2010, Intellectual Reserve, Inc.  All rights reserved. 
 :------------------------------------------------------------------------:)
xquery version "1.0-ml";

module namespace setting = "/xqdebug/debug/session";

import module namespace iv="/xqdebug/shared/common/invoke" at "../shared/common/invoke/invokeFunctions.xqy";

declare variable $userSession as xs:string := setting:sessionFileForUser( xdmp:get-current-user() );
declare variable $dbgDb as xs:string := "Debug";
declare option xdmp:mapping "false";


declare function setting:sessionFileForUser( $username as xs:string )
as xs:string
{
  fn:concat( "/content/xqdebug/session/settings-", $username, ".xml" )
};

declare function setting:initSessionForUser( $username as xs:string )
as element(keys)
{
    let $keys := 
          element keys {
            element user { $username }
          }
    return (
      xdmp:document-insert( setting:sessionFileForUser( $username ), $keys )
      ,
      $keys
    )
};

declare function setting:getSession()
{
  if ( fn:doc-available( $userSession ) )
  then fn:doc( $userSession )/keys
  else fn:error( xs:QName( "INITFILE-MISSING" ), fn:concat("XQDebug has not been initialized for user '", xdmp:get-current-user(), "'") )
};

(:~
  Get the specified key from the session store.
  @param  $key      Session key to set
  @return The value of the key or () if the key did not exist.
~:)
declare function setting:getField( $key as xs:string )
as item()*
{
  if ( $key eq "" ) 
  then ()
  else
    setting:getSession()/*[fn:name(.) eq $key]
};

(:~
  Get the specified key from the session store.  If the specified key does not currently exist
  set it to the specified default.
  @param  $key      Session key to set
  @param  $default  Default
  @return The value of the key or $default if the key did not exist.
~:)
declare function setting:getField( $key as xs:string, $default as item()* )
as item()*
{
  if ($key eq "")
  then ()
  else
    let $value := setting:getSession()/*[fn:name(.) eq $key]
    return
      if ( fn:exists($value) )
      then $value
      
      else setting:setField( $key, $default )
};

(:~
  Set the specified session field key to the specified value and return the value unchanged.
  @param $key   Key to set.
  @param $value Value of the key.
  @return $value
~:)
declare function setting:setField( $key as xs:string, $value as item()* )
as item()*
{
  if ( $key eq "")
  then fn:error()
  else
    let $oldNode := setting:getField( $key )
    return (
      $value
      ,
      if ( fn:exists( $value ) )
      then (
        let $newNode := element { $key } { $value }
        return
          if ( fn:empty($oldNode) )
          then xdmp:node-insert-child( setting:getSession(), $newNode )
          else xdmp:node-replace( $oldNode, $newNode )
      )
      else if ( fn:exists( $oldNode ) )
      then xdmp:node-delete( $oldNode )
      else ()
        
    )        
};

