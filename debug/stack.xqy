(:------------------------------------------------------------------------:
   Copyright (c) 2010, Intellectual Reserve, Inc.  All rights reserved. 
 :------------------------------------------------------------------------:)
xquery version "1.0-ml";

import module namespace request="/xqdebug/debug/requests" at "/debug/requests.xqy";
import module namespace server = "/xqdebug/debug/server" at "/debug/server.xqy";
import module namespace tables="/xqdebug/html/tables" at "/html/tables.xqy";

declare namespace ss="http://marklogic.com/xdmp/status/server";
declare option xdmp:mapping "false";

let $reqs := request:stopped()
let $rt := request:statusTable( $reqs )
let $reqTable := tables:outputTable( $rt )
let $reqId := xdmp:get-request-field( "req", "" )
let $reqId := 
  if ( fn:empty($reqId) or ($reqId eq "") )
  then request:current()
  else request:current( xs:unsignedLong($reqId) )

return (
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>Stack Frame Page</title>
      <meta name="robots" content="noindex,nofollow"/>
      <link rel="stylesheet" href="/assets/styles/xqdebug.css"/>
    </head>
    <body> 
      <div id="req-table" class="wrapper">
        {$reqTable}
      </div><br/>
      { 
        if ( fn:exists($reqId) and ($reqId = $reqs) ) 
        then
          <div id="xquery-source" class="tableContainer wrapper" style="width:100%; height:90%; ">
            <h4>Stack</h4>
            <pre>{ xdmp:quote(dbg:stack( $reqId )) }</pre>
          </div>
        else ()
      }
    </body>
  </html>
)

