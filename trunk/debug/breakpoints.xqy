(:------------------------------------------------------------------------:
   Copyright (c) 2010, Intellectual Reserve, Inc.  All rights reserved. 
 :------------------------------------------------------------------------:)
(: Breakpoints :)
xquery version "1.0-ml";

import module namespace request="/xqdebug/debug/requests" at "/debug/requests.xqy";
import module namespace tables="/xqdebug/html/tables" at "/html/tables.xqy";

declare namespace bp="/xqdebug/debug/breakpoints";

declare option xdmp:mapping "false";

(:~
  Return all breakpoints for the specified request.
  @param $reqId Request ID of the breakpoints.
  @param $bps   List of breakpoints to put in the table.
  return breakpoints element containing specified breakpoints.
~:)
declare function bp:breakpointTable( $reqId as xs:unsignedLong, $bps as xs:unsignedLong* )
as element(breakpoints)
{
	<breakpoints ftype="table" name="dbgBpTbl" request="{$reqId}">
		<format name="breakpoint" title="Breakpoint">
			<cell name="clrBp" title="Clear"  style="text-align:center"/>
			<cell name="bpId" title="ID"  style="text-align:right"/>
			<cell name="uri" title="URI" />
			<cell name="line" title="Line" style="text-align:right;" />
			<cell name="statement" title="Stmt"  style="text-align:right;"/>
			<cell name="source" title="Source"/>
		</format>
		{
		(: Return all breakpoints for the specified request. :)
		for $bp in $bps
		let $bpExpr := dbg:expr($reqId, $bp)
		let $uri := $bpExpr/data(dbg:uri)
		let $line := $bpExpr/data(dbg:line)
		let $stmt := $bpExpr/dbg:statements/data(dbg:statement[1])
		let $src := $bpExpr/dbg:expr-source/text()
		order by $uri,$line 
		return (	
		  <breakpoint ftype="row">
		    <clrBp>{<a target="resultFrame" href="/debug/breakpoints.xqy?display=true&amp;clrbp={$bp}">&empty;</a>}</clrBp>
				<bpId>{$bp}</bpId>
				<uri>{$uri}</uri>
				<line>{$line}</line>
				<statement>{$stmt}</statement>
				<source>{$src}</source>
			</breakpoint>
			)
		}
	</breakpoints>
};

let $fields := xdmp:get-request-field-names()
let $req := xs:unsignedLong(xdmp:get-request-field( "req", "0" ))
let $reqId := 
      if ( $req eq 0 ) 
      then request:current() 
      else $req
let $bps := 
        try { 
          dbg:breakpoints( $reqId ) 
        } catch( $x) { () }

return (
  (: Set Breakpoint :)
  if ( "setbp" = $fields )
  then
    try { dbg:break ( $reqId, xs:unsignedLong( xdmp:get-request-field( "setbp", "0" ) ) ) } catch( $x ) {}
  else ()
,
  (: Clear Breakpoint :)
  if ( "clrbp" = $fields )
  then 
    try { 
      dbg:clear( $reqId, xs:unsignedLong( xdmp:get-request-field( "clrbp", "0" ) ) ) 
    } catch( $x ) {}
  else ()
,
(: Clear All Breakpoints :)
  if ( "clrall" = $fields )
  then 
    try {
      for $bp in dbg:breakpoints( $reqId )
      return dbg:clear( $reqId, $bp ) 
    } catch( $x ) {}
  else ()
,
  if ( fn:not("display" = $fields ) )
  then xdmp:redirect-response( "/debug/requestList.xqy#currentExpr" )
  else (
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>Breakpoints Page</title>
      <meta name="robots" content="noindex,nofollow"/>
      <link rel="stylesheet" href="/assets/styles/xqdebug.css"/>
    </head>
    <body> 
      <div id="dbg_bp_wrap" class="wrapper">
        <h4>Breakpoints</h4>
        { 
          if ( fn:exists( $bps ) ) 
          then 
            <div id="dbg_bp" class="tableContainer">
              { tables:outputTable( bp:breakpointTable($reqId, dbg:breakpoints( $reqId )) ) }
            </div>
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

)


