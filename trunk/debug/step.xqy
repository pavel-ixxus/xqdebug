(:------------------------------------------------------------------------:
   Copyright (c) 2010, Intellectual Reserve, Inc.  All rights reserved. 
 :------------------------------------------------------------------------:)
xquery version "1.0-ml";

import module namespace request="/xqdebug/debug/requests" at "/debug/requests.xqy";
import module namespace server = "/xqdebug/debug/server" at "/debug/server.xqy";
import module namespace tables="/xqdebug/html/tables" at "/html/tables.xqy";

declare option xdmp:mapping "false";

let $op := xdmp:get-request-field("op", "none")
let $reqId := request:current()
return (
  if ( fn:empty( $reqId ) or ($op eq "none") )
  then ()
  else if ($op eq "step")
  then dbg:step( $reqId )
  else if ($op eq "next")
  then dbg:next( $reqId )
  else if ($op eq "out")
  then dbg:out( $reqId )
  else if ($op eq "finish")
  then dbg:finish( $reqId )
  else if ($op eq "continue")
  then dbg:continue( $reqId )
  else ()
  ,
  dbg:wait( $reqId, 5)
  ,
  xdmp:redirect-response( "/debug/requestList.xqy#currentExpr" )
)