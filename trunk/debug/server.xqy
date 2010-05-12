(:------------------------------------------------------------------------:
   Copyright (c) 2010, Intellectual Reserve, Inc.  All rights reserved. 
 :------------------------------------------------------------------------:)
xquery version "1.0-ml";
module namespace server="/xqdebug/debug/server";

declare namespace gr="http://marklogic.com/xdmp/group";
declare namespace ss="http://marklogic.com/xdmp/status/server";

declare option xdmp:mapping "false";

declare private variable $groups.xml as element(gr:groups) := xdmp:read-cluster-config-file("groups.xml")/gr:groups;

(: Return the configurations for the specified groups in the cluster. :)
declare function server:getGroups($gids as gr:group-id+)
as element(gr:group)*
{
  $groups.xml/gr:group[gr:group-id = $gids]
};

declare function server:groupAppServerConfigs($gids as gr:group-id+)
{
	(
		$groups.xml/gr:group[gr:group-id = $gids]/gr:xdbc-servers/gr:xdbc-server
		,
		$groups.xml/gr:group[gr:group-id = $gids]/gr:http-servers/gr:http-server
	)
};

declare function server:connected($sid as xs:unsignedLong)
as xs:boolean
{
  (: 
    HACK: This is as good as it gets without a query dbg:connected() function from MarkLogic.
  
    Without a dbg:connected() API method to determine what servers are 'connected' our only recourse is to
    call dbg:disconnect() and if it throws an exception immediately call dbg:connect() on the same server.
    
    An alternative is to keep track ourselves of what servers are connected. But the server 
    state could change if there are other debugger applications.  
    NOTE: The debug API does not support multiple debugging sessions because we can potentially 
    disconnect other debug sessions anyway.
  :)
  try {
    dbg:disconnect($sid)
    ,
     (: NOTE: If we were not 'connected' dbg:disconnect() will throw an exception and we won't execute the dbg:connect() :) 
    dbg:connect($sid)
    ,
    fn:true()
  }
  catch( $ex ) {
    fn:false()
  }
};

declare function server:groupServersDebugStatus($gid as xs:unsignedLong+) 
as element(servers)
{
	<servers ftype="table" name="dbgSvrTbl">
		<format name="appserver" title="Application Servers">
			<cell name="appserver-name" title="App Server" class="firstcell" style="text-align:left" />
			<cell name="port" title="Port" class="statuscell" />
			<cell name="kind" title="Kind" class="statuscell" style="text-align:left" />
			<cell name="database" title="Database" class="statuscell" style="text-align:left" />
			<cell name="modules" title="Modules" class="statuscell" style="text-align:left" />
			<cell name="root" title="Root Dir" class="statuscell" style="text-align:left" />
			<cell name="connect" title="Connect" class="statuscell" />
			<cell name="enabled" title="Enabled" class="statuscell" />
			<cell name="log-errors" title="Log Errors" class="statuscell" />
			<cell name="debug-allow" title="Debugging" class="statuscell" />
			<cell name="profile-allow" title="Profiling" class="statuscell" />
			<cell name="threads" title="Threads" class="statuscell" />
			<cell name="requests" title="requests" class="statuscell" />
			<cell name="updates" title="Updates" class="statuscell" />
			<cell name="reqtime" title="Request Time" class="statuscell" />
		</format>
		{
		(: Return all application servers that can execute XQuery code. :)
		(: NOTE: XDBC servers don't have the gr:execute element so we do a little backwards logic to compensate. :)
		for $cfg in server:groupAppServerConfigs($gid)[fn:not(gr:execute eq fn:false())]
		let 
			$execute  := fn:data($cfg/gr:execute) ne fn:false(), 
			$kind 		:= (: if (data($cfg/gr:webDAV)) then "webdav-server" else :) fn:local-name($cfg),
			$sid      := if ($kind eq "xdbc-server") then $cfg/gr:xdbc-server-id else $cfg/gr:http-server-id,
			$name 		:= xdmp:server-name($sid),
			$modules  := if ($cfg/gr:modules eq 0) then "file-system" else xdmp:database-name($cfg/gr:modules),
			$database	:= xdmp:database-name($cfg/gr:database),
			$enabled  := $cfg/gr:enabled/text(),
			$root     := $cfg/gr:root/text(),
			$port     := $cfg/gr:port/text(),
			$connect  := 
			     if (server:connected($sid)) 
			     then <a target="resultFrame" href="/debug/connect.xqy?dis={ $sid }">Disconnect</a>
			     else <a target="resultFrame" href="/debug/connect.xqy?con={ $sid }">Connect</a>,
			$debug    := $cfg/gr:debug-allow/text(),
			$profile  := $cfg/gr:profile-allow/text(),
			$log      := $cfg/gr:log-errors/text(),
			$sstats 	:= for $hid in xdmp:group-hosts($gid) return xdmp:server-status($hid, $sid), 
			$threads 	:= fn:sum($sstats/ss:threads),
			$req-statuses := $sstats/ss:request-statuses/ss:request-status,
			$requests	:= fn:count($sstats/ss:request-statuses/ss:request-status),
			$updates 	:= fn:count($sstats/ss:request-statuses/ss:request-status[ss:update eq fn:true()]),
			$reqrate 	:= fn:round-half-to-even(fn:sum($sstats/ss:request-rate),2)
		order by $kind, $name
		return (	
		  <appserver ftype="row">
				<appserver-name>{$name}</appserver-name>
				<kind>{$kind}</kind>
				<port>{$port}</port>
				<database>{$database}</database>
				<modules>{$modules}</modules>
				<enabled>{$enabled}</enabled>
				<connect>{$connect}</connect>
				<root>{$root}</root>
				<log-errors>{$log}</log-errors>
				<debug-allow>{$debug}</debug-allow>
				<profile-allow>{$profile}</profile-allow>
				<threads>{$threads}</threads>
				<req-statuses>{$req-statuses}</req-statuses>
				<requests>{$requests}</requests>
				<updates>{$updates}</updates>
				<reqtime>{$reqrate}</reqtime>
			</appserver>
			)
		}
	</servers>
};

