(:------------------------------------------------------------------------:
   Copyright (c) 2010, Intellectual Reserve, Inc.  All rights reserved. 
 :------------------------------------------------------------------------:)
xquery version "1.0-ml";

module namespace request="/xqdebug/debug/requests";
import module namespace iv="/xqdebug/shared/common/invoke" at "/shared/common/invoke/invokeFunctions.xqy";
import module namespace setting = "/xqdebug/debug/session" at "/debug/session.xqy";
import module namespace util = "http://marklogic.com/xdmp/utilities" at "/MarkLogic/utilities.xqy";

declare namespace html = "http://www.w3.org/1999/xhtml";
declare namespace ss = "http://marklogic.com/xdmp/status/server";

declare option xdmp:mapping "false";

declare variable $g_reqTimeout := 30; (: set default timeout :)

(:~
  Get the current request to debug. If no request current then select the first request
  returned by dbg:attached()/dbg:stopped().
  @return current request ID.
~:)
declare function request:current()
as xs:unsignedLong?
{
  let $req := xs:unsignedLong(setting:getField( "dbgReqId" ))
  return
    if ( fn:exists( $req ) and ($req = dbg:stopped()) )
    then $req
    else request:current( dbg:attached()[fn:last()] )
};

(:~
  Set the current request to debug.
  @param $reqId Request to debug.
  @return $reqId.
~:)
declare function request:current( $reqId as xs:unsignedLong? )
as xs:unsignedLong?
{
  setting:setField( "dbgReqId", $reqId )
};

(:~
  Trim the trailing path seperator from the root directory.
  @param $db  Database ID of the current database.
  @param $rootDir Root directory to trim.
  @return The trimmed root directory.
~:)
declare function request:trimRoot( $db as xs:unsignedLong, $rootDir )
as xs:string
{
    if ($db eq 0 and (xdmp:platform() eq "winnt"))
    then fn:replace( $rootDir, "^(.*)[\\/]$", "$1" )
    else fn:replace( $rootDir, "^(.*)/$", "$1" )
};

declare function request:getSourceLine( $db as xs:unsignedLong, $uri as xs:string, $line as xs:unsignedShort )
as xs:string*
{
  if ( ($db ne 0) and (xdmp:database() ne $db ))
  then iv:invoke( xdmp:database-name($db), xdmp:function(xs:QName("request:getSourceLine"),"/debug/requests.xqy"), $db, $uri, $line )
  else if ( $db eq 0 )
  then (
    fn:tokenize( xdmp:filesystem-file( $uri ), "\n" )[$line]
  )
  else 
    fn:tokenize( fn:doc( $uri )/text(), "\n" )[$line]
};

declare function request:getSourceFile( $db as xs:unsignedLong, $uri as xs:string )
as xs:string*
{
  if ( $db eq 0 )
  then (
    xdmp:document-get( $uri )/text()
  )
  else fn:doc( $uri )/text()
};

(:
declare function request:listSource( $reqId as xs:unsignedLong )
{
  let $reqId := dbg:wait( $reqId,  30 )
  let $stack := dbg:stack($reqId)
  let $expr := $stack/dbg:expr
  let $db := xs:unsignedLong($expr/dbg:location/dbg:database)
  let $root := util:basepath($expr/dbg:location/dbg:uri/text())
  let $uri := $expr/dbg:uri/text() 
(:      let $uri := if ($uri eq "/") then "/default.xqy" else $uri :)
  return
    request:listSource( $reqId, $db, $root, $uri, $expr/dbg:line/fn:data(.) )
};
:)
(:~
  List the current expression and source file.  Highlight the current expression and mark current breakpoints in the source file.
  @param  $reqId  The current request ID.
  @param  $db     The request's modules database ID.
  @param  $root   The request server's root directory.
  @param  $uri    The relative URI of the source file to list.
  @param  $current  The current line number
~:)
declare function request:listSource( $reqId as xs:unsignedLong, $db as xs:unsignedLong, $root as xs:string, $uri as xs:string?, $current as xs:unsignedLong? )
{
  if ( ($db ne 0) and (xdmp:database() ne $db ))
  then iv:invoke( xdmp:database-name($db), xdmp:function(xs:QName("request:listSource"),"/debug/requests.xqy"), $reqId, $db, $root, $uri, $current )
  
  else (
    let $uri := if ($uri eq "/") then "/default.xqy" else $uri
    let $rootDir := request:trimRoot( $db, $root )
    let $path := fn:concat( $rootDir, $uri )
    let $content := 
          if ( fn:empty( $uri ) or fn:empty( $current ) ) 
          then () 
          else fn:tokenize( request:getSourceFile( $db, $path), "\n" )
    let $bpExprs := for $bp in dbg:breakpoints( $reqId ) 
                    return dbg:expr($reqId, $bp )[dbg:uri eq $uri]
    let $bpLines := $bpExprs/xs:unsignedLong(dbg:line)
    return 
    <code>
    <span class="tableContainer" id="dbg_src" uri="{$path}" db="{$db}">
      {if ($current ne 0) then attribute line {$current} else () }
      <table frame="box" rules="cols" id="dbg_src_table">
        <caption>Module: {$path}</caption>
        <thead>
          <tr class="rowHdr" frame="box" rules="cols">
            <th title="Set or clear a breakpoint.">bp</th>
            <th class="linenums" title="Line number">#</th>
            <th title="Source Code">Source</th>
          </tr>
        </thead>
        <tfoot></tfoot>
        <tbody>
        {
          for $src at $i in $content
          return 
            <tr>
              {
                if ( $i eq $current )
                then ( attribute class { "currentExpr" }, attribute name { "currentExpr" }, attribute id { "currentExpr" } )
                else if ($i mod 2 eq 0)
                then attribute class { "odd" }
                else ()
              }
              <td>{
                if ( $i = $bpLines ) 
                then (
                  attribute class { "breakpoint" },
                  <a target="resultFrame" href="/debug/breakpoints.xqy?clrbp={ $bpExprs[dbg:line eq $i]/dbg:expr-id/fn:data(.) }">&Oslash;</a>
                )
                else (
                  let $bpId := try { dbg:line( $reqId, $uri, $i)[fn:last()] } catch ($ex) { 0 }
                  return
                    if ( $bpId > 0 )
                    then <a target="resultFrame" href="/debug/breakpoints.xqy?setbp={ $bpId }">&oplus;</a>
                    else <span>&mdash;</span>
                )
              }</td>
              <td>{ $i }</td>
              <td class="src">{ $src }</td>
            </tr>
        }
        </tbody>
      </table>
    </span>
    </code>
  )
};

(:~
  Return all requests that are stopped for debugging.
  @return A list of all stopped requests on the specified servers.
~:)
declare function request:stopped()
as xs:unsignedLong*
{
  request:stopped( xdmp:group-servers() )
};

(:~
  Return all requests that are stopped on the specified server IDs.
  @param $sids  A list of server ids from which to look for stopped requests.
  @return A list of all stopped requests on the specified servers.
~:)
declare function request:stopped( $sids as xs:unsignedLong* )
as xs:unsignedLong*
{
  for $sid in $sids, $hid in xdmp:group-hosts()
  return 
    xdmp:server-status($hid, $sid)/ss:request-statuses/ss:request-status[ss:request-state/fn:data(.) eq 'stopped']/ss:request-id/fn:data(.)
};

(:~
  Return the status of the specified requests.
  @param $reqs  A sequence of request IDs.
  @return The status(es) of the specified request(s).
~:)
declare function request:status( $reqs as xs:unsignedLong* )
as element(ss:requests)
{
  element ss:requests {
    for $request in 
      for $hid in xdmp:group-hosts(), $sid in xdmp:group-servers()
      return xdmp:server-status($hid, $sid)/ss:request-statuses/ss:request-status[ss:request-id = $reqs]
    return
      element ss:request {
        $request/*
      }
  }
};

(:~
  Return an output table of the status of the specified requests.
  @param $reqs  A sequence of request IDs.
  @return An output table(s) of the specified request status(es).
~:)
declare function request:statusTable( $reqs as xs:unsignedLong* )
as element(requests)
{
	<requests ftype="table" name="dbgReqTbl">
		<format name="request" title="Request">
			<cell name="appserver-name" title="App Server" style="text-align:left" />
			<cell name="reqId" title="Request ID"/>
			<cell name="detach" title="Detach"/>
			<cell name="hostName" title="Host" />
			<cell name="modDbName" title="Modules" />
			<cell name="databaseName" title="Database" />
			<cell name="rootDir" title="Root Dir" />
			<cell name="reqText" title="Reqest Text" />
			<cell name="reqState" title="State" />
			<cell name="dbgStatus" title="Status" />
			<cell name="exprId" title="Expr ID" />
			<cell name="where" title="Where" />
		</format>
		{
		(: Return all application servers that can execute XQuery code. :)
		let $hids := xdmp:group-hosts()
		let $sids := xdmp:group-servers()
		for $req in fn:distinct-values($reqs)
    let 
      $request := 
        for $hid in $hids, $sid in $sids
        return xdmp:server-status( $hid, $sid )/ss:request-statuses/ss:request-status[ss:request-id = $req],
      $id := $request/ss:request-id/fn:data(.),
      $svr := xdmp:server-name( $request/ss:server-id/fn:data(.) ),
      $host := xdmp:host-name( $request/ss:host-id/fn:data(.) ),
      $modDbId := $request/ss:modules/fn:data(.),
      $modDb  := if ($modDbId eq 0 ) then "filesystem" else xdmp:database-name($modDbId),
      $dbId   := $request/ss:database/fn:data(.),
      $root   := $request/ss:root/fn:data(.),
      $reqText  := $request/ss:request-rewritten-text/fn:data(.),
      $state    := $request/ss:request-state/fn:data(.),
      $dbgStatus  := $request/ss:debugging-status/fn:data(.),
      $exprId     := $request/ss:expr-id/fn:data(.),
      $where      := $request/ss:where-stopped/fn:data(.)
		order by $svr,$id
		return (	
		  <request ftype="row">
				<appserver-name>{$svr}</appserver-name>
				<reqId>{<a target="resultFrame" href="/debug/requestList.xqy?req={$id}#currentExpr">{$id}</a>}</reqId>
				<detach>{<a target="resultFrame" href="/debug/attach.xqy?detach={$id}" title="Detach from request and allow it to run to completion.">detach</a>}</detach>
				<hostName>{$host}</hostName>
				<modDbName>{$modDb}</modDbName>
				<databaseName>{xdmp:database-name($dbId)}</databaseName>
				<rootDir>{$root}</rootDir>
				<reqText>{$reqText}</reqText>
				<reqState>{$state}</reqState>
				<dbgStatus>{$dbgStatus}</dbgStatus>
				<exprId>{$exprId}</exprId>
				<where>{$where}</where>
			</request>
			)
		}
	</requests>
};

(:~
  List the current expression and source file.  Highlight the current expression and mark current breakpoints in the source file.
  @param  $reqId  The current request ID.
  @param  $db     The request's modules database ID.
  @param  $root   The request server's root directory.
  @param  $uri    The relative URI of the source file to list.
  @param  $current  The current line number
~:)
declare function request:stackTable( $reqId as xs:unsignedLong, $modDb as xs:unsignedLong )
as element(div)
{
  (
    let $stack := dbg:stack( $reqId )
    let $expr := $stack/dbg:expr
    return 
    <div class="tableContainer" id="dbg_stack">
      <table frame="box" rules="all" id="dbg_stack_table">
        <tr class="rowHdr stack_expr">
          <th colspan="3">Expression</th>
        </tr>
        <tr class="stack_expr">
          <td colspan="3" >{$expr/dbg:expr-source/fn:data(.)}</td>
        </tr>
        {
          for $frame at $i in $stack/dbg:frame
          let $loc := $frame/dbg:location
(:*** 
  BUGBUG: MarkLogic bug #10298 -> the database returned in stack frame is always '0' => filesystem. 
  Should be database of dbg:uri.
  Until this is fixed need to assume files are in the modules database of the request.  
***:)
          let $srcDb := if ( $modDb ne 0 ) then $modDb else $loc/dbg:database/fn:data(.)
          let $srcDbName := if ( $srcDb eq 0 ) then 'filesystem' else xdmp:database-name($srcDb)
          let $globals := $frame/dbg:global-variables
          let $externals := $frame/dbg:external-variables
          let $vars := $frame/dbg:variables/dbg:variable
          return (
            <tr class="rowHdr stack_frame">
              <th style="width:65px;">Frame{$i}</th>
              <td style="text-align:left;" colspan="2">Line: '{$frame/dbg:line/fn:data(.)}' of '{$loc/dbg:uri/fn:data(.)}' on '{$srcDbName}'</td>
            </tr>,
            <tr class="stack_frame">
              <td colspan="3">{ request:getSourceLine( $srcDb, $loc/dbg:uri/fn:data(.), $frame/dbg:line/fn:data(.) ) }</td>
            </tr>,
            if ( fn:exists( $vars ) )
            then (
              <tr class="frame_variables">
                <th style="width:65px;">Variables</th>
                <td>Name</td>
                <td>Value</td>
              </tr>,
              for $var at $i in $vars
              return
                <tr class="frame_variable {if ($i mod 2) then "odd" else ()}">
                  <td></td>
                  <td>{ fn:QName( $var/dbg:prefix/@xmlns/fn:data(.), $var/dbg:name/xs:string(.) ) }</td>
                  <td>{ $var/dbg:value/fn:data(.) }</td>
                </tr>
            )
            else ()
            (: TODO: List externals and globals :)
          )
        }
      </table>
    </div>
  )
};
