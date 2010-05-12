(:------------------------------------------------------------------------:
  Copyright (c) 2010, Intellectual Reserve, Inc.  All rights reserved. 
 :------------------------------------------------------------------------:)
xquery version "1.0-ml";

import module namespace request="/xqdebug/debug/requests" at "/debug/requests.xqy";
import module namespace tables="/xqdebug/html/tables" at "/html/tables.xqy";
import module namespace watch="/xqdebug/debug/watch-expressions" at "/debug/watch-functions.xqy";

declare namespace ss="http://marklogic.com/xdmp/status/server";
declare option xdmp:mapping "false";

let $fields := xdmp:get-request-field-names()
let $req := xdmp:get-request-field( "req", "" )
let $reqId := 
  if ( fn:empty($req) or ($req eq "") )
  then request:current()
  else request:current( xs:unsignedLong($req) )
let $wait := dbg:wait( $reqId, $request:g_reqTimeout )

return ( 
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>{"Request List"} Page</title>
      <meta name="robots" content="noindex,nofollow"/>
      <meta http-equiv="cache-control" content="no-cache"/> 
      <meta http-equiv="pragma" content="no-cache"/> 
      <link rel="stylesheet" type="text/css" href="/assets/styles/xqdebug.css"/>
    	<script src='/assets/scripts/jquery-1.4.0.js' type='text/javascript' ></script>
      <script type="text/javascript">
        <!--
        function submitenter(myfield,e)
        {
        var keycode;
        if (window.event) keycode = window.event.keyCode;
        else if (e) keycode = e.which;
        else return true;
        
        if (keycode == 13)
           {
           myfield.form.submit();
           return false;
           }
        else
           return true;
        }
        //-->
      </script>
    </head>
    <body> 
      <div class="wrapper">
        <h3>Stopped Requests</h3>
        <div id="req-table" class="tableContainer">
        {
          tables:outputTable( request:statusTable( $reqId ) ) 
        } 
        </div>
      </div><br/>
      <div id="current-req">
        { 
          if ( fn:exists($reqId) ) 
          then
            let $rstat := request:status($reqId)/ss:request
            let $expr := dbg:stack( $reqId )/dbg:expr
            let $exprUri := $expr/dbg:uri/fn:data(.)
            let $line := $expr/dbg:line/fn:data(.)
            let $modDb := xs:unsignedLong($rstat/ss:modules)
            return (
              <div class="wrapper" id="dbg_stack_wrap">
                <h3>Stack</h3>
               { request:stackTable( $reqId, $modDb ) }
              </div>,<br/>,
              
              watch:watchBlock($reqId, watch:getExpressions(), fn:false() ),<br/>,
              
              <div class="wrapper" id="dbg_src_wrap">
                <h3>Source: {$exprUri} Line: {$line}</h3>
                { 
                  if ( fn:starts-with( $exprUri, "/MarkLogic/" ) )
                  then
                    request:listSource( $reqId, 0, "", $expr/dbg:location/dbg:uri/fn:data(.), $line ) 
                  else
                    request:listSource( $reqId, $modDb, $rstat/ss:root/fn:data(.), $exprUri, $line ) 
                }
              </div>,<br/>
            )
          else ()
        }
      </div>
    </body>
  </html>
)
