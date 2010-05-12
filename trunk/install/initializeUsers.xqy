(:------------------------------------------------------------------------:
   Copyright (c) 2010, Intellectual Reserve, Inc.  All rights reserved. 
 :------------------------------------------------------------------------:)
(: ************************* Initialize User Session Files ************************* :)
xquery version "1.0-ml";
import module namespace install="xqdebug/install-functions" at "/install/install-functions.xqy";
import module namespace iv="/xqdebug/shared/common/invoke" at "/shared/common/invoke/invokeFunctions.xqy";
import module namespace setting = "/xqdebug/debug/session" at "/debug/session.xqy";

declare namespace sec="http://marklogic.com/xdmp/security";

declare variable $dbg-db-name := "XQDebug";

"", fn:concat( "Initialize XQDebug config files for all users with 'admin' role ... " )
,
let $admin-id := xdmp:role("admin" )
let $users := 
      for $username in install:getUsers()[$admin-id = xdmp:user-roles(sec:user-name)]/sec:user-name/fn:data(.)
      return 
        iv:invoke( $dbg-db-name, xdmp:function( xs:QName("setting:initSessionForUser"), "" ), $username )/user/fn:data(.)
return
  fn:concat( "Initalized XQDebug for the following users: ", fn:string-join( $users, "," ) )

