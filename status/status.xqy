(:------------------------------------------------------------------------:
   Copyright (c) 2010, Intellectual Reserve, Inc.  All rights reserved. 
 :------------------------------------------------------------------------:)
xquery version "1.0-ml";
module namespace status="/xqdebug/status/status";
declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace cfginfo="/xqdebug/status/marklogic/config" at "config-info.xqy";

declare namespace gr="http://marklogic.com/xdmp/group";
declare namespace db="http://marklogic.com/xdmp/database";
declare namespace hs="http://marklogic.com/xdmp/status/host";
declare namespace ss="http://marklogic.com/xdmp/status/server";
declare namespace fs="http://marklogic.com/xdmp/status/forest";

(: HTML Table output :)
declare function status:outputTables($tables as element()) 
as element()+
{
	for $table in $tables/descendant-or-self::element()[@ftype eq "table"]
	return	status:outputTable($table)
};

declare function status:outputTable($parent as element()) 
as element()+
{
	let $format := $parent/format
	let $rows	:= $parent/*[name(.) ne "format"]
	let $last := count($rows)+1
	return 
	<table id={name($parent)} class="statustable" cellspacing="0" cellpadding="1" width="100%" border="1">
		<tr class="statusrowtitle" sortoncol="none">  {
			for $cell in $format/cell
			return (<th>{data($cell/@title)}</th>) 
		} </tr>
		{
		for $data at $row in $rows[1 to $last]
		return 
			<tr class={if($row mod 2 eq 0) then "statusevenrow" else "statusoddrow"}> {
				for $cell at $col in $format/cell
				let $content := $data/*[name(.) eq data($cell/@name)]
				return 
					<td> { 
						$cell/@style,
						if ( exists($content/*) ) then $content/* else data($content)
					} </td>
			} </tr>
		}
	</table>,<br />
};

(: Parse a comma seperate list of names after removing whitespace
   and return a sequence of names 
:)
declare function status:getListOfNames($list as xs:string)
as xs:string+
{
	if ($list eq "") 
	then ""
	else
	let $nlist := tokenize($list, "\s*,\s*")
	return if (count($nlist) gt 0)
		then $nlist
		else ""
};

(: Group Status  :)
declare function status:groupStatus()
as element()*
{
	status:groupStatus(xdmp:groups())
};

declare function status:groupStatusByName($gname as xs:string)
as element()*
{
	if (($gname eq "") or ($gname eq "*"))
	then status:groupStatus()
	else status:groupStatus(xdmp:group(status:getListOfNames($gname)))
};

declare function status:groupStatus($gids as xs:unsignedLong*)
as element()*
{
	<groups  ftype="table">
		<format name="group" title="Group" ftype="row">
			<cell name="group-name" title="Group Name" class="firstcell" />
			<cell name="list-cache-size" title="List Cache" class="statuscell" />
			<cell name="list-cache-partitions" title="List Partititions" class="statuscell" />
			<cell name="system-log-level" title="System Log Level" class="statuscell" />
			<cell name="file-log-level" title="FileLog Level" class="statuscell" />
			<cell name="failover-enable" title="FailOver" class="lastcell" />
		</format>
		{
		
		for $gid in $gids
		let 	$name 		:= xdmp:group-name($gid),
			$group		:= cfginfo:getGroup($gid),
			$list-cache-size := data($group/gr:list-cache-size),
			$list-cache-partitions := data($group/gr:list-cache-partitions),
			$system-log-level := data($group/gr:system-log-level),
			$file-log-level 	:= data($group/gr:file-log-level),
			$failover-enable := data($group/gr:failover-enable),
			$hids		:= xdmp:group-hosts($gid),
			$hoststatus 	:= status:hostStatusById($hids),
			$appstatus	:= status:groupServersStatus($gid)
		return (	<group>
				<group-name>{$name}</group-name>
				<list-cache-size>{$list-cache-size}</list-cache-size>
				<list-cache-partitions>{$list-cache-partitions}</list-cache-partitions>
				<system-log-level>{$system-log-level}</system-log-level>
				<file-log-level>{$file-log-level}</file-log-level>
				<failover-enable>{$failover-enable}</failover-enable>
				{$hoststatus, $appstatus}
			</group>
			)
		}
	</groups>
};

(: Status for Hosts :)
declare function status:hostStatus() 
as element()*
{
	status:hostStatusById(xdmp:hosts())
};

declare function status:hostStatusByGroupid($gid as xs:unsignedLong*) 
as element()*
{
	status:hostStatusById(xdmp:group-hosts($gid))
};

declare function status:hostStatusByName($hname as xs:string*) 
as element()*
{
	let $hids 	:=	if (($hname eq "") or ($hname eq "*"))
				then 	xdmp:hosts()
				else 	
					for $name in status:getListOfNames($hname) 
					return xdmp:host($name)
	return status:hostStatusById($hids)
};

declare function status:hostStatusByName($gid as xs:unsignedLong*, $hname as xs:string*) 
as element()*
{
	let $hids 	:=	if (($hname eq "") or ($hname eq "*"))
				then 	xdmp:group-hosts($gid)
				else 	
					for $name in status:getListOfNames($hname) 
					return xdmp:host($name)
	return status:hostStatusById($hids)
};

declare function status:hostStatusById($hids as xs:unsignedLong*) 
as element()*
{
	<hosts ftype="table">
		<format name="host" title="Hosts">
			<cell name="host-name" title="Host Name" class="firstcell" />
			<cell name="online" title="State" class="statuscell" />
			<cell name="since" title="Since" class="statuscell" />
			<cell name="host-size" title="Data Size" class="statuscell" />
			<cell name="data-dir-space" title="Data Space" class="statuscell" />
			<cell name="log-device-space" title="Log Space" class="statuscell" />
			<cell name="threads" title="Threads" class="statuscell" />
			<cell name="queries" title="Queries" class="statuscell" />
			<cell name="updates" title="Updates" class="statuscell" />
			<cell name="avtime" title="Average Time" class="statuscell" />
			<cell name="request-rate" title="Request Rate" class="statuscell" />
			<cell name="oldest" title="Oldest Request" class="statuscell" />
			<cell name="etc-hits" title="Hits" class="statuscell" />
			<cell name="etc-misses" title="Misses" class="statuscell" />
			<cell name="etc-ratio" title="Ratio" class="lastcell" />
		</format>
		{
    let  	$localstatus := xdmp:host-status(xdmp:host())
		for $hid in $hids
		let 	$hstat 		:= xdmp:host-status($hid),
			$name 		:= xdmp:host-name($hid),
			$sids		:= ($hstat//xs:unsignedLong(hs:http-server-id),$hstat//xs:unsignedLong(hs:xdbc-server-id)),
			$sstats 		:= for $sid in $sids return xdmp:server-status($hid, $sid), 
			$online 	:= if($localstatus/hs:hosts/hs:host[hs:host-id eq $hid]/hs:online eq true()) then "connected" else "disconnected",
			$since 		:= 	
						if($hid eq xdmp:host()) 
						then data($localstatus/hs:last-startup)
						else if($online eq "connected") 
						then data($localstatus/hs:hosts/hs:host[hs:host-id eq $hid]/hs:last-online)
						else data($localstatus/hs:hosts/hs:host[hs:host-id eq $hid]/hs:last-offline),
			$dataspace 	:= data($hstat/hs:data-dir-space),
			$usedspace	:= data($hstat/hs:host-size),
			$logspace	:= data($hstat/hs:log-device-space),
		    	$threads 	:= sum($sstats/ss:threads),
		    	$queries 	:= count($sstats/ss:request-statuses/ss:request-status),
		    	$updates 	:= count($sstats/ss:request-statuses/ss:request-status[ss:update eq true()]),
			$timenodes 	:= (
				for $sid in $sids
				return 
				<ss:times>
					<ss:request-statuses>{$sstats[ss:server-id eq $sid]/ss:request-statuses/ss:request-status}</ss:request-statuses>
					<ss:time>{$sstats[ss:server-id eq $sid]/ss:current-time}</ss:time>
				</ss:times>
			),
		    	$avtime 	:= status:averageTime($timenodes),
		    	$req-rate 	:= round-half-to-even(sum($sstats/ss:request-rate),2),
		    	$oldest 		:= status:oldest("",$timenodes),
		    	$hits 		:= sum($sstats/ss:expanded-tree-cache-hits),
		    	$misses 	:= sum($sstats/ss:expanded-tree-cache-misses),
		    	$ratio		:= status:hm-ratio($hits,$misses),
		    	$forests		:= status:forestStatusById(data($hstat/hs:assignments/hs:assignment/hs:forest-id))
		where empty($hstat/hs:error)
		order by $name
		return (	<host  ftype="row">
				<host-name>{$name}</host-name>
				<online>{$online}</online>
				<since>{$since}</since>
				<host-size>{$usedspace}</host-size>
				<data-dir-space>{$dataspace}</data-dir-space>
				<log-device-space>{$logspace}</log-device-space>
				<threads>{$threads}</threads>
				<queries>{$queries}</queries>
				<updates>{$updates}</updates>
				<avtime>{$avtime}</avtime>
				<request-rate>{$req-rate}</request-rate>
				<oldest>{$oldest}</oldest>
				<etc-hits>{$hits}</etc-hits>
				<etc-misses>{$misses}</etc-misses>
				<etc-ratio>{$ratio}</etc-ratio>
				{$forests}
			</host>
			)
		}
	</hosts>
};

(: Status for Application Servers :)
declare function status:groupServersStatusByName($gid as xs:unsignedLong, $sname as xs:string*) 
as element()*
{
	let 	$gsids	:=  	xdmp:group-servers($gid),
		$sids 	:= 	if (($sname eq "") or ($sname eq "*")) 
				then $gsids
				else (
					let	$sid :=	for $name in status:getListOfNames($sname) 
							return xdmp:server($name)
					return	$gsids[. = $sid]
				)
	return status:serverStatusById($sids, xdmp:group-hosts($gid))
};

declare function status:groupServersStatusById($gid as xs:unsignedLong, $sids as xs:string*) 
as element()*
{
	let $sids :=
			if (($sids eq "") or ($sids eq "*")) 
			then xdmp:group-servers($gid)
			else $sids
	return status:serverStatusById($sids, xdmp:group-hosts($gid))
};

declare function status:groupHttpServersStatus($gid as xs:unsignedLong, $sname as xs:string) 
as element()*
{
	let 	$sids := cfginfo:groupHttpServers($gid),
		$sids := if (($sname eq "") or ($sname eq "*")) 
			then $sids 
			else 	let $sid := xdmp:server($sname)
				return $sids[. eq $sid] 
	return status:serverStatusById($sids, xdmp:group-hosts($gid))
};

declare function status:groupXdbcServersStatus($gid as xs:unsignedLong, $sname as xs:string) 
as element()*
{
	let 	$sids := cfginfo:groupXdbcServers($gid),
		$sids := if (($sname eq "") or ($sname eq "*")) 
			then  $sids
			else 	let $sid := xdmp:server($sname)
				return $sids[. eq $sid]
	return status:serverStatusById($sids, xdmp:group-hosts($gid))
};

declare function status:serversStatus() 
as element()*
{
	status:serverStatusById(xdmp:servers(), xdmp:hosts())
};

declare function status:groupServersStatus($gid as xs:unsignedLong+) 
as element()*
{
	status:serverStatusById(xdmp:group-servers($gid), xdmp:group-hosts($gid))
};

declare function status:groupServersStatus($gid as xs:unsignedLong+, $sids as xs:unsignedLong+) 
as element()*
{
	status:serverStatusById($sids, xdmp:group-hosts($gid))
};

declare function status:serverStatusById($sids as xs:unsignedLong*, $hids as xs:unsignedLong*) 
as element()*
{
	<servers ftype="table">
		<format name="appserver" title="Application Servers">
			<cell name="appserver-name" title="App Server" class="firstcell" style="text-align:left" />
			<cell name="port" title="Port" class="statuscell" />
			<cell name="kind" title="Kind" class="statuscell" style="text-align:left" />
			<cell name="database" title="Database" class="statuscell" style="text-align:left" />
			<cell name="root" title="Root Dir" class="statuscell" style="text-align:left" />
			<cell name="available" title="Available" class="statuscell" />
			<cell name="hostErrors" title="Host Errors" class="statuscell" />
			<cell name="threads" title="Threads" class="statuscell" />
			<cell name="queries" title="Queries" class="statuscell" />
			<cell name="updates" title="Updates" class="statuscell" />
			<cell name="avtime" title="Average Time" class="statuscell" />
			<cell name="reqtime" title="Request Time" class="statuscell" />
			<cell name="oldest" title="Oldest" class="statuscell" />
			<cell name="etc-hits" title="ETC Hits" class="statuscell" />
			<cell name="etc-misses" title="ETC Misses" class="statuscell" />
			<cell name="etc-ratio" title="Ratio" class="lastcell" style="text-align:right" />
		</format>
		{
		let $numHosts		:= count($hids)
		for $sid in $sids
		let 	$sstats 		:= for $hid in $hids return xdmp:server-status($hid, $sid), 
			$cfg      := cfginfo:appServerConfig($sid),
			$kind 		:= if (data($cfg/gr:webDAV)) then "webdav-server" else local-name($cfg),
			$name 		:= xdmp:server-name($sid),
			$dbid		  := if ($kind eq ("task-server", "webdav-server")) then $cfg/gr:modules else $cfg/gr:database,
			$root     := $cfg/gr:root/text(),
			$port     := $cfg/gr:port/text(),
			$database	:= xdmp:database-name($dbid),
			$threads 	:= sum($sstats/ss:threads),
			$queries 	:= count($sstats/ss:request-statuses/ss:request-status),
			$updates 	:= count($sstats/ss:request-statuses/ss:request-status[ss:update eq true()]),
			$reqrate 	:= round-half-to-even(sum($sstats/ss:request-rate),2),
			$hits 		:= sum($sstats/ss:expanded-tree-cache-hits),
			$misses 	:= sum($sstats/ss:expanded-tree-cache-misses),
			$ratio 		:= status:hm-ratio($hits,$misses),
			$timenodes 	:= 	for $hid in $hids
						return 
						<ss:times>
							<ss:request-statuses>{$sstats[ss:host-id eq $hid]/ss:request-statuses/ss:request-status}</ss:request-statuses>
							<ss:time>{$sstats[ss:host-id eq $hid]/ss:current-time}</ss:time>
						</ss:times>,
		  $avtime 	:= status:averageTime($timenodes),
		  $oldest		:= status:oldest("",$timenodes),
			$error 		:= $sstats[exists(ss:error)],
			$numErrors	:= count($error), 
			(: ASSUMPTION: appserver would have to error out on every host in the cluster to be in a critical state. :) 
			$available	:= if (exists($error) and ($numHosts le $numErrors)) then false() else true()
			
		order by $kind, $name
		return (	<appserver ftype="row">
				<appserver-name>{$name}</appserver-name>
				<kind>{$kind}</kind>
				<available>{$available}</available>
				<hostErrors>{$numErrors}</hostErrors>
				<port>{$port}</port>
				<database>{$database}</database>
				<root>{$root}</root>
				<threads>{$threads}</threads>
				<queries>{$queries}</queries>
				<updates>{$updates}</updates>
				<avtime>{$avtime}</avtime>
				<reqtime>{$reqrate}</reqtime>
				<oldest>{$oldest}</oldest>
				<etc-hits>{$hits}</etc-hits>
				<etc-misses>{$misses}</etc-misses>
				<etc-ratio>{$ratio}</etc-ratio>
			</appserver>
			)
		}
	</servers>
};

(: Status for Forests :)
declare function status:forestStatus() 
as element()*
{
	status:forestStatusById(xdmp:forests())
};

declare function status:forestStatusByName($fname as xs:string*) 
as element()*
{
	let $fids := 	if (($fname eq "") or ($fname eq "*")) 
			then xdmp:forests()
			else for $name in status:getListOfNames($fname) return xdmp:forest($name)
	return status:forestStatusById($fids)
};

declare function status:forestStatusById($fids as xs:unsignedLong*) 
as element()*
{
	<forests ftype="table">
		<format name="forest" title="Forest">
			<cell name="forest-name" title="Forest" class="firstcell" style="text-align:left" />
			<cell name="host-name" title="Host" class="statuscell" style="text-align:left" />
			<cell name="dbname" title="Database" class="statuscell" style="text-align:left" />
			<cell name="state" title="State" class="statuscell" />
			<cell name="fsize" title="Size" class="statuscell" />
			<cell name="freespace" title="FreeSpace" class="statuscell" />
			<cell name="stands" title="Stands" class="statuscell" />
			<cell name="directories" title="Dirs" class="statuscell" />
			<cell name="documents" title="Docs" class="statuscell" />
			<cell name="last-backup" title="Last Backup" class="statuscell" />
			<cell name="lc-hits" title="LC Hits" class="statuscell" />
			<cell name="lc-misses" title="LC Misses" class="statuscell" />
			<cell name="lc-ratio" title="Ratio" class="statuscell" style="text-align:right" />
			<cell name="tc-hits" title="TC Hits" class="statuscell" />
			<cell name="tc-misses" title="TC Misses" class="statuscell" />
			<cell name="tc-ratio" title="Ratio" class="lastcell" style="text-align:right" />
		</format>
		{
		for $fid in $fids
		let 	$fname 	:= xdmp:forest-name($fid),
			$fstat 		:= xdmp:forest-status($fid),
			$fcount		:= if($fstat/fs:state eq "open") then xdmp:forest-counts($fid) else (),
            			$time 		:= $fstat/fs:current-time,
        			$error_state 	:= if ($fstat/fs:state = ("mount error", "error", "unmounted")) then true() else false(),
    			$dbname 	:=(
					if ($error_state and $fstat/fs:enabled eq fn:true()) 
					then "Not available during forest error or recovery"
					else if ($fstat/fs:enabled eq false()) 
					then xdmp:database-name(xdmp:forest-databases($fid))		      
					else if(empty($fstat/fs:database-id)) 
					then "none"
					else xdmp:database-name($fstat/fs:database-id)),
    			$size 		:= sum($fstat/fs:stands/fs:stand/fs:disk-size),
    			$free 		:= data($fstat/fs:device-space),
    			$stands		:= $fstat/fs:stands/fs:stand,
    			$directories	:= data($fcount/fs:directory-count),
    			$files		:= data($fcount/fs:document-count),
    			$numstands	:= count($stands),
    			$backup	:= data($fstat/fs:last-backup),
    			$lchits 		:= sum($stands/fs:list-cache-hits),
    			$lcmisses 	:= sum($stands/fs:list-cache-misses),
    			$lcrat 		:= status:hm-ratio($lchits,$lcmisses),
    			$tchits 		:= sum($stands/fs:compressed-tree-cache-hits),
    			$tcmisses 	:= sum($stands/fs:compressed-tree-cache-misses),
    			$tcrat 		:= status:hm-ratio($tchits,$tcmisses)
		order by $fname
		return (	<forest ftype="row">
				<forest-name>{$fname}</forest-name>
				<dbname>{$dbname}</dbname>
				<host-name>{xdmp:host-name($fstat/fs:host-id)}</host-name>
				<state>{data($fstat/fs:state)}</state>
				<fsize>{$size}</fsize>
				<freespace>{$free}</freespace>
				<stands>{$numstands}</stands>
				<directories>{$directories}</directories>
				<documents>{$files}</documents>
				<last-backup>{$backup}</last-backup>
				<lc-hits>{$lchits}</lc-hits>
				<lc-misses>{$lcmisses}</lc-misses>
				<lc-ratio>{$lcrat}</lc-ratio>
				<tc-hits>{$tchits}</tc-hits>
				<tc-misses>{$tcmisses}</tc-misses>
				<tc-ratio>{$tcrat}</tc-ratio>
			</forest>
			)
		}
	</forests>
};


(: Status for Databases :)
declare function status:databaseStatus() 
as element()*
{
	status:databaseStatus(xdmp:databases())
};

declare function status:databaseStatusByName($dbname as xs:string+) 
as element()*
{
	let 	$dbids 	:= 	if (($dbname eq "") or ($dbname eq "*")) 
				then xdmp:databases()
				else for $name in status:getListOfNames($dbname) return xdmp:database($name)
	return status:databaseStatus($dbids)
};

declare function status:databaseStatus($dbids as xs:unsignedLong*) 
as element()*
{
	<databases ftype="table">
		<format name="database" title="Database">
			<cell name="database-name" title="Database" class="firstcell" style="text-align:left"  />
			<cell name="last-backup" title="Last Backup" class="statuscell" />
			<cell name="size" title="Size" class="statuscell" />
			<cell name="enabled" title="Online" class="statuscell" />
			<cell name="since" title="Since" class="statuscell" />
			<cell name="num-forests" title="Forests" class="statuscell" />
			<cell name="merging" title="Merging" class="statuscell" />
			<cell name="backingup-or-restoring" title="Backing up or Restoring" class="statuscell" />
			<cell name="reindexing" title="Reindexing / Refactoring" class="lastcell" />
		</format>
		{
		for $dbid in $dbids
		let	$name 		:= xdmp:database-name($dbid),
		  $forests 	:= xdmp:database-forests($dbid),
			$fstats 		:= for $f in $forests return xdmp:forest-status($f),
			$available := empty($fstats/fs:state[. ne 'open']) and empty($fstats/fs:enabled[. ne true()]),
			$backup	:= max($fstats/fs:last-backup),
			$size 		:= sum($fstats/fs:stands/fs:stand/fs:disk-size),
	    $size 		:= if(empty($size)) then 0 else $size,
			$db		:= cfginfo:getDatabase($dbid),
			$enabled	:= data($db/db:enabled),
			$since		:= concat("",max($fstats/fs:last-state-change)),
			$merging	:= ($db/db:merge-enable eq true()) and ($db/db:merge-timestamp ne 0),
              			$backingup 	:= ( count($fstats/fs:backups/fs:backup) ne 0),
			$restoring	:= ( count($fstats/fs:restore) ne 0 ),
			$reif   := ($db/db:reindexer-enable eq true()) and ($db/db:reindexer-timestamp ne 0)

		order by $name
		return (	<database ftype="row">
				<database-name>{$name}</database-name>
				<available>{$available}</available>
				<size>{$size} MB</size>
				<last-backup>{$backup}</last-backup>
				<enabled>{$enabled}</enabled>
				<since>{$since}</since>
				<num-forests>{count($forests)}</num-forests>
				<merging>{$merging}</merging>
				<backingup-or-restoring>{$backingup or $restoring}</backingup-or-restoring>
				<reindexing>{$reif}</reindexing>
			</database>
			),
		status:forestStatusById(distinct-values(xdmp:database-forests($dbids)))
		}
	</databases>
};

(: Average the ss:request-status times :)
declare function status:averageTime($reqs as node()*)
as xs:string
{
	if(empty($reqs)) 
	then status:formatTime(xs:dayTimeDuration("PT0S"))
	else 
		let $times := 
				for $rnode in $reqs
				for $req in $rnode/ss:request-statuses/ss:request-status
				let $time := data($rnode/ss:time) - data($req/ss:start-time)
				where $time ge xs:dayTimeDuration("PT0S")
				return $time,
			$avg := avg($times)
		return
			if(empty($avg)) 
			then status:formatTime(xs:dayTimeDuration("PT0S"))
			else status:formatTime($avg)
};

(: Format an xs:dayTimeDuration item to a "hh:mm:ss.ms" time format :)
declare function status:formatTime($time as xs:dayTimeDuration)
as xs:string
{
  let $secs := 
  	seconds-from-duration($time) 
  	+ minutes-from-duration($time) * 60 + 
  	(hours-from-duration($time) + (days-from-duration($time) * 24)) * 3600 
  return concat( string(xs:integer($secs)), ".", string(xs:integer(($secs - xs:integer($secs))*1000) ) )
};

(: Find the oldest time value :)
declare function status:oldest($rtxt as xs:string, $reqs as node()*)
{
	if(empty($reqs)) 
	then status:formatTime(xs:dayTimeDuration("PT0S"))
	else 
		let $times := 
			if($rtxt ne "") 
			then 
				for $rnode in $reqs
				for $req in $rnode/ss:request-statuses/ss:request-status[ss:request-text eq $rtxt]
				return $rnode/ss:time - $req/ss:start-time
			else 	
				for $rnode in $reqs
				for $req in $rnode/ss:request-statuses/ss:request-status
				return $rnode/ss:time - $req/ss:start-time,
			$oldest := max($times)
		return
			if(empty($oldest)) 
			then status:formatTime(xs:dayTimeDuration("PT0S"))
			else status:formatTime($oldest)
};

(: Find the ratio of hits to misses :)
declare function status:hm-ratio($hits, $misses)
as xs:string
{
	try {
		if (empty($misses) or ($misses eq 0)) 
		then "100%"
		else if (empty($hits))
		then "0%"
		else concat(string(round-half-to-even((($hits*100) div ($hits + $misses)),0)),"%")
	} catch($e) { "n/a" }
};

