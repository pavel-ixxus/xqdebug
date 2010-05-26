(:------------------------------------------------------------------------:
  Copyright (c) 2010, Intellectual Reserve, Inc.  All rights reserved. 
 :------------------------------------------------------------------------:)
(: Watch Functions :)
xquery version "1.0-ml";

module namespace watch="/xqdebug/debug/watch-expressions";

import module namespace request="/xqdebug/debug/requests" at "/debug/requests.xqy";
import module namespace setting = "/xqdebug/debug/session" at "/debug/session.xqy";
import module namespace tables="/xqdebug/html/tables" at "/html/tables.xqy";

declare namespace ss="http://marklogic.com/xdmp/status/server";

declare option xdmp:mapping "false";

(:~
  Return all watch expressions for current debug session.
  @param $reqId Request ID of the breakpoints.
  return watchExprs element containing watchExpr elements.
~:)
declare function watch:watchTable( $reqId as xs:unsignedLong?, $watchExprs as element(watch-expr)*, $display as xs:boolean )
as element(watchExprs)
{
	<watchExprs ftype="table" name="dbgWatchTbl" request="{$reqId}">
		<format name="watchExpressions" title="Watch Expressions">
			<cell name="clr" title="del"/>
			<cell name="num" title="#"/>
			<cell name="expr" title="Expression"/>
			<cell name="value" title="Value"/>
		</format>
		{
		(: Return all watch expressions for the current session. :)
		let $exprs := 
		      if ( fn:empty($watchExprs) ) 
		      then watch:getExpressions( ) 
		      else $watchExprs
		for $wexpr at $i in $exprs
		let $expr := $wexpr/fn:data(.)
		let $value := 
		      if ( fn:exists($reqId ) ) 
		      then 
		        try{ 
		          xdmp:quote( dbg:value( $reqId, $expr ) )
		        } 
		        catch( $ex ) {
            	fn:concat( "<", $ex/error:code, ": ", $ex/error:message, ">" )
		        }
		      else "<No Requests Stopped for evaluation.>"
		return (	
		  <watchExpr ftype="row">
		    <clr>{<a target="_self" href="/debug/watch.xqy?deletewatch={$i}{if ($display) then '&amp;display' else ''}">&empty;</a>}</clr>
		    <num>{$i}</num>
		    <expr>{<input target="_self" type="text" name="watch" value="{$expr}" size="50" onKeyPress="return submitenter(this,event)" />}</expr>
				<value>{$value}</value>
			</watchExpr>
			)
		,
	  <watchExpr ftype="row">
	    <clr>{<a target="_self" href="/debug/watch.xqy?addwatch{if ($display) then '&amp;display' else ''}">&oplus;</a>}</clr>
	    <num>{}</num>
	    <expr>{<a target="_self" href="/debug/watch.xqy?addwatch{if ($display) then '&amp;display' else ''}">add expression</a>}</expr>
			<value />
		</watchExpr>

		}
	</watchExprs>
};

declare function watch:getExpressions( )
as element( watch-expr )*
{
  setting:getField("watch")/watch-expr
};

declare function watch:watchBlock( $reqId as xs:unsignedLong?, $watchExprs as element(watch-expr)* )
as element(div)
{
  watch:watchBlock( $reqId, $watchExprs, fn:true() )
};

declare function watch:watchBlock( $reqId as xs:unsignedLong?, $watchExprs as element(watch-expr)*, $display as xs:boolean )
as element(div)
{
  <div id="dbg_watch_wrap" class="wrapper">
    <h4>Watch Expressions</h4>
    <div id="dbg_watch" class="tableContainer">
      <form id="form_watch" method="post" >
        { 
          if ( $display )
          then attribute action { "/debug/watch.xqy?display" }
          else attribute action { "/debug/watch.xqy" }
          ,
          tables:outputTable( watch:watchTable($reqId, $watchExprs, $display ) )
        }
      </form>
    </div>
  </div>
};

declare function watch:watchSaveExprs( $watchExprs as xs:string* )
as element(watch-expr)*
{
    let $watch := 
          for $expr in $watchExprs
          return  element watch-expr { $expr }
    let $save := 
          if ( fn:exists($watch) ) 
          then setting:setField( "watch", $watch ) 
          else ()
    return $watch 
};

declare function watch:watchAddExpr( )
as element(watch-expr)*
{
  let $exprs := (
          watch:getExpressions()
          ,
          element watch-expr { "()" }
        )
  return watch:watchSaveExprs( $exprs )
};

declare function watch:watchDeleteExpr( $num as xs:integer )
as element(watch-expr)*
{
  watch:watchSaveExprs( fn:remove( watch:getExpressions(), $num ) )
};

