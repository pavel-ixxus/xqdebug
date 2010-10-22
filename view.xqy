(:------------------------------------------------------------------------:
   Copyright (c) 2010, Intellectual Reserve, Inc.  All rights reserved. 
 :------------------------------------------------------------------------:)
xquery version "1.0-ml";

declare default element namespace "http://www.w3.org/1999/xhtml";
import module namespace security = "/xqdebug/security/security" at "/security/security.xqy";
import module namespace status = "/xqdebug/status/status" at "/status/status.xqy";
import module namespace tables="/xqdebug/html/tables" at "/html/tables.xqy";

declare option xdmp:mapping "false";

let $fields := xdmp:get-request-field-names()
(: Set session info and return key/value pairs :)
let $values := 
	for $field in $fields
	return ($field, xdmp:set-session-field($field, xdmp:get-request-field($field)))
let $title := 
	if (exists(index-of($fields, "amps")))
	then "Amps"
	else if (fn:exists(fn:index-of($fields,"collection")))
	then "Collections"
	else if (fn:exists(fn:index-of($fields,"db")))
	then "Database"
	else if (fn:exists(fn:index-of($fields, 'h')))
	then (
		if (fn:exists(fn:index-of($fields,"f")))
		then "Forest"
		else "Host"
	)
	else if (exists(index-of($fields, "r")))
	then "Roles"
	else if (exists(index-of($fields, "uripriv")))
	then "URI Privileges"
	else if (exists(index-of($fields, "execpriv")))
	then "Execute Privileges"
	else if (exists(index-of($fields, "u")))
	then "Users"
	else if (fn:exists(fn:index-of($fields,"svr")))
	then "App Server"
	else if (fn:exists(fn:index-of($fields,"hsn")))
	then "HTTP Server"
	else if (fn:exists(fn:index-of($fields,"xsn")))
	then "XDBC Server"
	else "Group"
let $banner := 	concat($title, " Status for ")
          
return (
xdmp:set-response-content-type("text/html"),


<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<title>{$banner} Page</title>
	<meta name="robots" content="noindex,nofollow"/>
  <meta http-equiv="cache-control" content="no-cache"/> 
  <meta http-equiv="pragma" content="no-cache"/> 
	<link rel="stylesheet" href="/assets/styles/xqdebug.css"/>
</head>
<body> {
	let $groupname	:= xdmp:get-session-field("g", "Default")
	let $gid 		:= xdmp:group($groupname)
	let $hostname 	:= xdmp:get-session-field("h", '*') 
	return
	if ( $title eq "Group") 
	then (
		<h3>{$banner} <em>{$groupname}</em></h3>,<br />,
		status:outputTables(status:groupStatusByName($groupname))
	)
	else if ($title eq "Users") 
	then (
		let $name := xdmp:get-request-field("u", "*")
		return 	(	
			<h3>{$banner} <em>{$name}</em></h3>,<br />,
			status:outputTables(security:users($name))
		)
	)
	else if ($title eq "Roles") 
	then (
		let $id := xdmp:get-request-field("r", "*")
		return 	(	
			<h3>{$banner} <em>{$id}</em></h3>,<br />,
			status:outputTables(security:roles($id))
		)
	)
	else if ($title eq "Amps") 
	then (
		let $id := xdmp:get-request-field("amps", "*")
		return 	(	
			<h3>{$banner} <em>{$id}</em></h3>,<br />,
			status:outputTables(security:amps($id))
		)
	)
	else if ($title eq "Collections") 
	then (
		let $id := xdmp:get-request-field("collection", "*")
		return 	(	
			<h3>{$banner} <em>{$id}</em></h3>,<br />,
			status:outputTables(security:collections($id))
		)
	)
	else if ($title eq "Execute Privileges") 
	then (
		let $id := xdmp:get-request-field("execpriv", "*")
		return 	(	
			<h3>{$banner} <em>{$id}</em></h3>,<br />,
			status:outputTables(security:executePrivilege($id))
		)
	)
	else if ($title eq "URI Privileges") 
	then (
		let $id := xdmp:get-request-field("uripriv", "*")
		return 	(	
			<h3>{$banner} <em>{$id}</em></h3>,<br />,
			status:outputTables(security:uriPrivilege($id))
		)
	)
	else if ($title eq "Host") 
	then (
		<h3>{$banner} <em>{$hostname}</em></h3>,<br />,
		status:outputTables(status:hostStatusByName($gid, $hostname)) 
	)
	else if ( $title eq "Forest" )
	then (
		let $forestname := xdmp:get-request-field("f", "*")
		return 	(	
			<h3>{$banner} <em>{$hostname}</em></h3>,<br />,
			status:outputTables(status:forestStatusByName($forestname))
		)
	)
	else if ( $title eq "App Server" )
	then (
		let $sidstr := xdmp:get-request-field("svr", "*")
		let $sids := 
		    	if ($sidstr = "*") 
		    	then xdmp:group-servers($gid) 
		    	else 
		    		for $sid in status:getListOfNames($sidstr)
		    		return xs:unsignedLong($sid)
		let $snames := if ($sidstr eq "*") then $sidstr else string-join( for $sid in $sids return xdmp:server-name($sid) , ",")
		return 	(	
			<h3>{$banner} <em>{$snames}</em></h3>,<br />,
			status:outputTables(status:serverStatusById($sids, xdmp:group-hosts($gid)))
		)
	)
	else if ( $title eq "HTTP Server" )
	then (
		let $sname := xdmp:get-request-field("hsn", "*")
		return 	(	
			<h3>{$banner} <em>{$sname}</em></h3>,<br />,
			status:outputTables(status:groupHttpServersStatus($gid, $sname))
		)
	)
	else if ( $title eq "XDBC Server" )
	then (
		let 	$sname as xs:string := xdmp:get-request-field("xsn", "*")
		return 	(	
			<h3>{$banner} <em>{$sname}</em></h3>,<br />,
			status:outputTables(status:groupXdbcServersStatus($gid, $sname))
		)
	)
	else if ( $title eq "Database" )
	then (
		let $dbname := xdmp:get-request-field("db", "*")
		return 	(	
			<h3>{$banner} <em>{$dbname}</em></h3>,<br />,
			status:outputTables(status:databaseStatusByName($dbname))
		)
	)
	else <p>Unknown Status request: {$title}</p>
}</body>
  <head>
    <!-- NOTE: This header IS a work around for and IE bug (http://support.microsoft.com/kb/222064) -->
    <META HTTP-EQUIV="PRAGMA" CONTENT="NO-CACHE"/>
  </head>
</html>
)