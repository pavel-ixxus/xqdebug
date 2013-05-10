(:------------------------------------------------------------------------:
   Copyright (c) 2010, Intellectual Reserve, Inc.  All rights reserved. 
 :------------------------------------------------------------------------:)
xquery version "1.0-ml";

import module namespace request="/xqdebug/debug/requests" at "/debug/requests.xqy";

declare namespace stepping = "/xqdebug/debug/stepping";

declare option xdmp:mapping "false";

(:~
  This is a workaround for the behavior of dbg:next().  
  dbg:next() if stopped at the start of an expression will step to the end of the 
  current expression... which is not typically expected behavior.  So if at the start of an expression
  we step and check if we are at the 'end' and if we are we call dbg:next() again.
~:)
declare function stepping:next($reqId) 
{ 
  let $status := dbg:status( $reqId )/dbg:request
  let $exprId := $status/dbg:expr-id/fn:data(.)
  return
    if ( $status/dbg:where-stopped = 'end' )
    then dbg:next( $reqId )
    
    else (
      (: NOTE:
        Put dbg:next() call into params of dbg:wait() to force sequentialization.  
        ( dbg:next() returns empty-sequence so it has no effect except sequentialization. )
        Put dbg:wait() call into dbg:status() params for same reason.
      :)
      let $stat := dbg:status( dbg:wait( ($reqId, dbg:next( $reqId ) ), 5) )
      return
        if ( ($exprId = $stat/dbg:expr-id) and ($stat/dbg:where-stopped = 'end') ) 
        then dbg:next( $reqId )
        else () 
    )
};

let $op := xdmp:get-request-field("op", "none")
let $reqId := request:current()
let $sequentialize :=
  if ( fn:empty( $reqId ) or ($op eq "none") )
  then ()

  else if ($op eq "step")
  then dbg:step( $reqId )

  else if ($op eq "next")
  then stepping:next( $reqId )

  else if ($op eq "out")
  then dbg:out( $reqId )

  else if ($op eq "finish")
  then dbg:finish( $reqId )

  else if ($op eq "continue")
  then dbg:continue( $reqId )

  else ()

return (
  dbg:wait( ($reqId, $sequentialize), 5)
  ,
  xdmp:redirect-response( "/debug/requestList.xqy#currentExpr" )
)