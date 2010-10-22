(:------------------------------------------------------------------------:
  Copyright (c) 2010, Intellectual Reserve, Inc.  All rights reserved. 
 :------------------------------------------------------------------------:)
(: Watch Expressions :)
xquery version "1.0-ml";

import module namespace request="/xqdebug/debug/requests" at "/debug/requests.xqy";
import module namespace watch="/xqdebug/debug/watch-expressions" at "/debug/watch-functions.xqy";

declare namespace ss="http://marklogic.com/xdmp/status/server";

declare option xdmp:mapping "false";

let $fields := xdmp:get-request-field-names()
let $req := xs:unsignedLong(xdmp:get-request-field( "req", "0" ))
let $reqId := 
      if ( $req eq 0 ) 
      then request:current() 
      else $req
      
(: 
  Update Watch Expressions - 
  Even though we save expressions they will not be available in this transaction
  so we need to return the hold the current batch (in $watchExprs) for processing if we need them. 
:)
let $watchExprs := 
      if ( "watch" = $fields )
      then watch:watchSaveExprs( xdmp:get-request-field("watch") )

      else if ("addwatch" = $fields)
      then watch:watchAddExpr()

      else if ( "deletewatch" = $fields )
      then watch:watchDeleteExpr( xs:integer(xdmp:get-request-field("deletewatch")) )

      else watch:getExpressions()

return (
  if ( fn:not("display" = $fields ) )
  then xdmp:redirect-response( "/debug/requestList.xqy#currentExpr" )
  else (
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <title>Watchpoint Page</title>
        <meta name="robots" content="noindex,nofollow"/>
        <link rel="stylesheet" href="/assets/styles/xqdebug.css"/>
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
      { 
        watch:watchBlock($reqId, $watchExprs, fn:true() ) 
      }
      </body>
      <head>
        <!-- NOTE: This header IS a work around for and IE bug (http://support.microsoft.com/kb/222064) -->
        <META HTTP-EQUIV="PRAGMA" CONTENT="NO-CACHE"/>
      </head>
    </html>
  )
)


