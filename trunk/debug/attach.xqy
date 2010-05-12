(:------------------------------------------------------------------------:
  Copyright (c) 2010, Intellectual Reserve, Inc.  All rights reserved. 
 :------------------------------------------------------------------------:)
xquery version "1.0-ml";
import module namespace request="/xqdebug/debug/requests" at "/debug/requests.xqy";

declare option xdmp:mapping "false";
declare variable $g_reqTimeout := 30; (: set default timeout :)

(: Attach or Detach to a request :)
let $fields := xdmp:get-request-field-names()
let $reqId := 
  if ( 'detach' = $fields )
  then dbg:detach( xs:unsignedLong( xdmp:get-request-field( 'detach' ) ) )
  else if ( 'attach' = $fields )
  then dbg:attach( xs:unsignedLong( xdmp:get-request-field( 'attach' ) ) )
  else request:current()
let $wait := dbg:wait( $reqId, $g_reqTimeout )
return
  xdmp:redirect-response( "/debug/requestList.xqy#currentExpr" )