(:------------------------------------------------------------------------:
   Copyright (c) 2010, Intellectual Reserve, Inc.  All rights reserved. 
 :------------------------------------------------------------------------:)
xquery version "1.0-ml";

import module namespace server = "/xqdebug/debug/server" at "/debug/server.xqy";
import module namespace tables="/xqdebug/html/tables" at "/html/tables.xqy";

declare namespace ss="http://marklogic.com/xdmp/status/server";

let $banner := 	"Server Connect"
let $csvr as xs:unsignedLong? := xs:unsignedLong(xdmp:get-request-field("con", ()))
let $dsvr as xs:unsignedLong? := xs:unsignedLong(xdmp:get-request-field("dis", ()))
let $localSvr := xdmp:server()
let $content :=
  (: NOTE: There are some servers we don't want anyone connecting to or stopping. :)
  if ( exists($csvr) and ($csvr ne $localSvr) and fn:not(xdmp:server-name($csvr) = ("Admin", "App-Builder")) )
  then (
    try {
      dbg:connect( $csvr )
    }
    catch( $ex ) {
    	if ($ex/error:code/text() eq "DBG-CONNECTED") 
    	then () 
    	else xdmp:rethrow()
    }
    ,
    xdmp:redirect-response("/debug/requestList.xqy#currentExpr")
  )
  else if ( exists($dsvr) and ($dsvr ne $localSvr) and fn:not(xdmp:server-name($dsvr) = ("Admin", "App-Builder")) )
  then (
    try {
      dbg:disconnect( $dsvr )
    }
    catch( $ex ) {
    	if ($ex/error:code/text() eq "DBG-DISCONNECTED") 
    	then () 
    	else xdmp:rethrow()
    }
    ,
    xdmp:redirect-response("/debug/connect.xqy")
  )

  else
    <div id="dbg_connect" class="wrapper">
      <h2>Connect to:</h2>
      <div class="tableContainer">
      {
        tables:outputTable( server:groupServersDebugStatus( xdmp:group() ) )
      }
      </div>
    </div>
      
return (
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>{$banner} Page</title>
      <meta name="robots" content="noindex,nofollow"/>
      <link rel="stylesheet" href="/assets/styles/xqdebug.css"/>
    </head>
    <body> 
      {
        $content
      }
    </body>
    <head>
      <!-- NOTE: This header IS a work around for and IE bug (http://support.microsoft.com/kb/222064) -->
      <META HTTP-EQUIV="PRAGMA" CONTENT="NO-CACHE"/>
    </head>
  </html>
)
