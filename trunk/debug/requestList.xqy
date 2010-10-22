(:------------------------------------------------------------------------:
  Copyright (c) 2010, Intellectual Reserve, Inc.  All rights reserved. 
 :------------------------------------------------------------------------:)
xquery version "1.0-ml";

import module namespace request="/xqdebug/debug/requests" at "/debug/requests.xqy";
import module namespace tables="/xqdebug/html/tables" at "/html/tables.xqy";
import module namespace watch="/xqdebug/debug/watch-expressions" at "/debug/watch-functions.xqy";
import module namespace win="/xqdebug/debug/window-expressions" at "/debug/window-functions.xqy";

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
      <link rel="stylesheet" type="text/css" href="/assets/styles/jquery-ui-1.8.2.css"/>
    	<script src='/assets/scripts/jquery-1.4.0.js' type='text/javascript' ></script>
        <script src='/assets/scripts/jquery-ui-1.8.2.min.js' type='text/javascript' ></script>
        <script src='/assets/scripts/resize.js' type='text/javascript' ></script>
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
              <div class="resizable" style="{win:getParentStyle('dbg_stack_wrap')}" > 
                <div class="viewport wrapper" id="dbg_stack_wrap" style="{win:getStyle('dbg_stack_wrap')}" >
                <h3>Stack</h3>
               { request:stackTable( $reqId, $modDb ) }
                </div>
              </div>
              ,<br/>,
              
              watch:watchBlock($reqId, watch:getExpressions(), fn:false() ),<br/>,
              
              <h3>Source: {$exprUri} Line: {$line}</h3>,
              <div class="resizable" style="{win:getParentStyle('dbg_src_wrap')}" >
              <div class="viewport wrapper" id="dbg_src_wrap" style="{win:getStyle('dbg_src_wrap')}" >
                { 
                  if ( fn:starts-with( $exprUri, "/MarkLogic/" ) )
                  then
                    request:listSource( $reqId, 0, fn:concat( xdmp:install-directory(), "/Modules/" ), $expr/dbg:uri/fn:data(.), $line ) 
                  else
                    request:listSource( $reqId, $modDb, $rstat/ss:root/fn:data(.), $exprUri, $line ) 
                }
              </div>
              </div>,<br/>
            )
          else ()
        }
      </div>
    </body>
    
    <head>
      <!-- NOTE: This header IS a work around for and IE bug (http://support.microsoft.com/kb/222064) -->
      <META HTTP-EQUIV="PRAGMA" CONTENT="NO-CACHE"/>
    </head>
  </html>
)
