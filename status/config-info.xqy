(:------------------------------------------------------------------------:
   Copyright (c) 2010, Intellectual Reserve, Inc.  All rights reserved. 
 :------------------------------------------------------------------------:)
xquery version "1.0-ml";
(: Library of functions for accessing cluster configuration information. :)

module namespace cfginfo="/xqdebug/status/marklogic/config";
declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace as="http://marklogic.com/xdmp/assignments";
declare namespace db="http://marklogic.com/xdmp/database";
declare namespace gr="http://marklogic.com/xdmp/group";
declare namespace ho="http://marklogic.com/xdmp/hosts";

declare variable $groups.xml 		as element(gr:groups) 		:= xdmp:read-cluster-config-file("groups.xml")/gr:groups;
declare variable $hosts.xml		as element(ho:hosts)		:= xdmp:read-cluster-config-file("hosts.xml")/ho:hosts;
declare variable $assignments.xml 	as element(as:assignments) 	:= xdmp:read-cluster-config-file("assignments.xml")/as:assignments;
declare variable $databases.xml 	as element(db:databases) 	:= xdmp:read-cluster-config-file("databases.xml")/db:databases;


(: Return the configuration information for all groups in cluster. :)
declare function cfginfo:getGroups()
as element(gr:groups)
{
	$groups.xml
};

(: Return the configurations for the specified groups in the cluster, wrapped in a gr:groups element. :)
declare function cfginfo:getGroups($gids as gr:group-id+)
as element(gr:groups)
{
	let $groups := cfginfo:getGroups()
	return element gr:groups {
		$groups/@*,
		$groups/gr:group[gr:group-id = $gids]
	}
};

(: Return the configurations for the specified groups in the cluster. :)
declare function cfginfo:getGroup($gids as gr:group-id+)
as element(gr:group)
{
	cfginfo:getGroups()/gr:group[gr:group-id = $gids]
};

declare function cfginfo:groupEventInfo($gid as xs:unsignedLong)
as element()*
{
	cfginfo:getGroup($gid)/(gr:events-activated | gr:events)
};

declare function cfginfo:groupXdbcServers($gid as xs:unsignedLong)
as xs:unsignedLong*
{
	cfginfo:getGroup($gid)/gr:xdbc-servers/gr:xdbc-server/gr:xdbc-server-id
};

declare function cfginfo:groupHttpServers($gid as xs:unsignedLong)
as xs:unsignedLong*
{
	cfginfo:getGroup($gid)/gr:http-servers/gr:http-server/gr:http-server-id
};

declare function cfginfo:groupAppServers($gid as xs:unsignedLong)
as xs:unsignedLong*
{
	let $grp := cfginfo:getGroup($gid)
	return (
		$grp/gr:http-servers/gr:http-server/gr:http-server-id
		,
		$grp/gr:xdbc-servers/gr:xdbc-server/gr:xdbc-server-id
		,
		$grp/gr:task-server/gr:task-server-id
	)
};

declare function cfginfo:appServerConfig($sid as xs:unsignedLong)
{
	let $grp := cfginfo:getGroups()/gr:group
	let $httpsvr := $grp/gr:http-servers/gr:http-server[data(gr:http-server-id) eq $sid]
	let $xdbcsvr := $grp/gr:xdbc-servers/gr:xdbc-server[data(gr:xdbc-server-id) eq $sid]
	let $tasksvr := $grp/gr:task-server[data(gr:task-server-id) eq $sid]
	return
		if (exists($httpsvr)) 
		then $httpsvr
		else if (exists($xdbcsvr))
		then $xdbcsvr
		else $tasksvr
};

declare function cfginfo:groupDatabaseIds($gid as xs:unsignedLong)
as xs:unsignedLong*
{
	let $fids		:= cfginfo:hostForestIds(xdmp:group-hosts($gid))
	let $dbs 	:= cfginfo:getDatabases()/db:database
	return $dbs[db:forests/db:forest-id = $fids]/db:database-id
};

declare function cfginfo:getHosts()
as element(ho:hosts)
{
	$hosts.xml
};

declare function cfginfo:getHosts($hids as ho:host-id*)
as element(ho:hosts)
{
	let $hosts := cfginfo:getHosts()
	return element ho:hosts {
		$hosts/@*,
		$hosts/ho:host[ho:host-id = $hids]
	}
};

declare function cfginfo:getHost($hids as ho:host-id*)
as element(ho:hosts)
{
	cfginfo:getHosts()/ho:host[ho:host-id = $hids]
};

declare function cfginfo:getHostForests($hids as xs:unsignedLong*)
as element(as:assignment)*
{
	cfginfo:getForests()/as:assignment[as:host = $hids]
};

declare function cfginfo:hostForestIds($hids as xs:unsignedLong*)
as xs:unsignedLong*
{
	cfginfo:getHostForests($hids)/as:forest-id
};

(: Return all as:assignments in the system. :)
declare function cfginfo:getForests()
as element(as:assignments)
{
	$assignments.xml
};

(: Return the as:assignment config for the specified forest ids wrapped in as:assignments element. :)
declare function cfginfo:getForests($fids as as:forest-id*)
as element(as:assignments)
{
	let $assigns := cfginfo:getForests()
	return element as:assignments {
		$assigns/@*,
		$assigns/as:assignment[as:forest-id = $fids]
	}
};

(: Return the as:assignment config for the specified forest ids. :)
declare function cfginfo:getForest($fids as as:forest-id+)
as element(as:assignment)*
{
	cfginfo:getForests()/as:assignment[as:forest-id = $fids]
};

(: Return the data directory used by the specified forest.  
    If none is found is is the forest is using the default data directory below the MarkLogic installation directory. 
    In this case return "private"
 :)
declare function cfginfo:forestDataDirectory($fid as xs:unsignedLong)
as xs:string
{
	let	$fcfg	:= cfginfo:getForest($fid),
		$dir 	:= $fcfg/as:assignment/as:data-directory
	return 	if ($dir ne "") then $dir else "private"
};

(: Return the database configuration for all databases in the system :)
declare function cfginfo:getDatabases()
as element(db:databases)
{
	$databases.xml
};

(: Return the configurations for the specified databases wrapped in a db:databases element. :)
declare function cfginfo:getDatabases($dbids as db:database-id+)
as element(db:databases)
{
	let $dbs := cfginfo:getDatabases()
	return element db:databases {
		$dbs/@*,
		$dbs/db:database[db:database-id = $dbids]
	}
};

(: Return the configurations for the specified databases. :)
declare function cfginfo:getDatabase($dbids as db:database-id+)
as element(db:database)
{
	cfginfo:getDatabases()/db:database[db:database-id = $dbids]
};
