(:------------------------------------------------------------------------:
   Copyright (c) 2010, Intellectual Reserve, Inc.  All rights reserved. 
 :------------------------------------------------------------------------:)
xquery version "1.0-ml";
module namespace security="/xqdebug/security/security";
declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace iv="/xqdebug/shared/common/invoke" at "/shared/common/invoke/invokeFunctions.xqy";
import module namespace status="/xqdebug/status/status" at "/status/status.xqy";
import module namespace sec="http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";

declare namespace as="http://marklogic.com/xdmp/assignments";
declare namespace gr="http://marklogic.com/xdmp/group";
declare namespace ho="http://marklogic.com/xdmp/hosts";
declare namespace db="http://marklogic.com/xdmp/database";
declare namespace hs="http://marklogic.com/xdmp/status/host";
declare namespace ss="http://marklogic.com/xdmp/status/server";

declare function security:users($name as xs:string)
as element(users)
{
  if ( xdmp:database-name(xdmp:database()) ne "Security" )
  then iv:invoke( "Security", xdmp:function(xs:QName("security:users"), "/security/security.xqy"), $name )
	else
  	let 	$users := security:getUsers()
  	let 	$roles := security:getRoles()
  	return
  	element users {
  		attribute ftype {"table"},
  		<format name="user" title="Users">
  			<cell name="name" title="User" class="firstcell" />
  			<cell name="description" title="Description" class="statuscell" />
  			<hidden name="user-id" title="ID" class="statuscell" />
  			<cell name="roles" title="All Inherited Roles" class="statuscell" />
  			<cell name="permissions" title="Permissions" class="statuscell" />
  			<cell name="collections" title="Collections" class="lastcell" />
  		</format>,
  		for $user in if ($name = ("*", "")) then $users else $users[sec:user-name eq $name]
  		let $ur := xdmp:user-roles($user/sec:user-name),
          $roleNames := for $rn in $roles[sec:role-id = $ur]/sec:role-name order by $rn ascending return $rn,
          $permissions := $user/sec:permissions/sec:permission/sec:capability,
    			$collections := $user/sec:collections/sec:collection/sec:uri
   		return (
  			element user {
  				<name>{string($user/sec:user-name)}</name>,
  				<description>{string($user/sec:description)}</description>,
  				<user-id>{xs:unsignedLong($user/sec:user-id)}</user-id>,
  				<roles>{string-join($roleNames,  ", ")}</roles>,
  				<permissions>{string-join($permissions, ", ")}</permissions>,
  				<collections>{string-join($collections, ", ")}</collections>
  			}
  		)
  	}
};

declare function security:roles($id as xs:string)
as element(roles)
{
	let 	$roles := security:getRoles()
	return
	element roles {
		attribute ftype {"table"},
		<format name="role" title="Roles">
			<cell name="name" title="Role" class="firstcell" />
			<cell name="description" title="Description" class="statuscell" />
			<hidden name="role-id" title="ID" class="statuscell" />
			<cell name="roles" title="Roles" class="statuscell" />
			<cell name="permissions" title="Permissions" class="statuscell" />
			<cell name="collections" title="Collections" class="lastcell" />
		</format>,
		for $role in if (($id eq "") or ($id eq "*")) then $roles else $roles[string(sec:role-id) eq $id]
		let 	$name := string($role/sec:role-name),
			$roles := for $rid in $role/sec:role-ids/sec:role-id return $roles[sec:role-id eq $rid]/sec:role-name,
			$permissions := $role/sec:permissions/sec:permission/sec:capability,
			$collections := $role/sec:collections/sec:collection/sec:uri
		order by $name
 		return (
			element role {
				<name>{$name}</name>,
				<description>{string($role/sec:description)}</description>,
				<role-id>{xs:unsignedLong($role/sec:role-id)}</role-id>,
				<roles>{ string-join($roles,  ", ")}</roles>,
				<permissions>{string-join($permissions, ", ")}</permissions>,
				<collections>{string-join($collections, ", ")}</collections>
			}
		)
	}
};

declare function security:amps($id as xs:string)
as element(amps)
{
	let 	$amps := security:getAmps()
	let 	$roles := security:getRoles()
	return
	element amps {
		attribute ftype {"table"},
		<format name="amp" title="Amps">
			<cell name="name" title="Name" />
			<hidden name="amp-id" title="ID" />
			<cell name="database" title="Database" />
			<cell name="uri" title="URI" />
			<cell name="namespace" title="Namespace" />
			<cell name="roles" title="Roles" />
		</format>,
		for $amp in if (($id eq "") or ($id eq "*")) then $amps else $amps[string(sec:amp-id) eq $id]
		let 	$name := string($amp/sec:local-name),
			$database	:= $amp/sec:database,
			$database	:= if ($database eq 0) then "filesystem" else xdmp:database-name($database),
			$roles := for $rid in $amp/sec:role-ids/sec:role-id return $roles[sec:role-id eq $rid]/sec:role-name
		order by $name
 		return (
			element role {
				<name>{$name}</name>,
				<namespace>{string($amp/sec:namespace)}</namespace>,
				<amp-id>{xs:unsignedLong($amp/sec:amp-id)}</amp-id>,
				<roles>{ string-join($roles,  ", ")}</roles>,
				<database>{string-join($database, ", ")}</database>,
				<uri>{string-join($amp/sec:document-uri, ", ")}</uri>
			}
		)
	}
};

declare function security:collections($id as xs:string)
as element(collections)
{
	let 	$collections := security:getCollections()
	let 	$roles := security:getRoles()
	return (
	element collections {
		attribute ftype {"table"},
		<format name="collection" title="Collections">
			<cell name="uri" title="URI" />
			<hidden name="collection-id" title="ID" />
			<cell name="roles" title="Role(Permissions)" />
		</format>,
		for $coll in if (($id eq "") or ($id eq "*")) then $collections else $collections[string(sec:collection-id) eq $id]
		let 	$uri 	:= string($coll/sec:uri),
			$cid	:= $coll/sec:collection-id,
			$roleIds as xs:string* := $coll/sec:roles,
			$perms:= string-join($coll/sec:permissions/sec:permission/sec:capability , ", "),
			$rstrings := 
					for $id in $roleIds 
					return concat($roles[string(sec:role-id) eq $id]/sec:role-name, "(", $perms, ")") 
		order by $uri
 		return (
			element collection {
				<uri>{$uri}</uri>,
				<collection-id>{string($cid)}</collection-id>,
				<roles>{string-join($rstrings,", ")}</roles>
			}
		)
	}
	)
};

declare function security:executePrivilege($id as xs:string)
as element(executePrivileges)
{
	let 	$privs := security:getExecutePrivileges()
	let 	$roles := security:getRoles()
	return (
	element executePrivileges {
		attribute ftype {"table"},
		<format name="executePrivilege" title="Execute Privileges">
			<cell name="name" title="Name" />
			<cell name="action" title="Action" />
			<hidden name="privilege-id" title="ID" />
			<cell name="roles" title="Roles" />
		</format>,
		for $priv in if (($id eq "") or ($id eq "*")) then $privs else $privs[string(sec:privilege-id) eq $id]
		let 	$name 	:= string($priv/sec:privilege-name),
			$action	:= $priv/sec:action,
			$rnames := for $rid in $priv/sec:role-ids/sec:role-id return string($roles[sec:role-id eq $rid]/sec:role-name)
		order by $name
 		return (
			element uriPrivilege {
				<name>{$name}</name>,
				<action>{string($action)}</action>,
				<privilege-id>{string($priv/sec:privilege-id)}</privilege-id>,
				<roles>{string-join($rnames,", ")}</roles>
			}
		)
	}
	)
};

declare function security:uriPrivilege($id as xs:string)
as element(uriPrivileges)
{
	let 	$privs := security:getUriPrivileges()
	let 	$roles := security:getRoles()
	return (
	element uriPrivileges {
		attribute ftype {"table"},
		<format name="uriPrivilege" title="URI Privileges">
			<cell name="name" title="Name" />
			<cell name="action" title="Action" />
			<hidden name="privilege-id" title="ID" />
			<cell name="roles" title="Roles" />
		</format>,
		for $priv in if (($id eq "") or ($id eq "*")) then $privs else $privs[string(sec:privilege-id) eq $id]
		let 	$name 	:= string($priv/sec:privilege-name),
			$action	:= $priv/sec:action,
			$rnames := for $rid in $priv/sec:role-ids/sec:role-id return string($roles[sec:role-id eq $rid]/sec:role-name)
		order by $name
 		return (
			element uriPrivilege {
				<name>{$name}</name>,
				<action>{string($action)}</action>,
				<privilege-id>{string($priv/sec:privilege-id)}</privilege-id>,
				<roles>{string-join($rnames,", ")}</roles>
			}
		)
	}
	)
};

(: Return user configuration information :)
declare function security:getUsers()
{
  if ( xdmp:database-name(xdmp:database()) ne "Security" )
  then
  	(: Need to read user info from the "Security" database. :)
  	iv:invoke( "Security", xdmp:function(xs:QName("security:getUsers"), "/security/security.xqy") )
	else
    for $user in fn:collection(sec:users-collection())/sec:user
    return 
      element sec:user {
      	$user/( sec:user-id | sec:user-name | sec:description | sec:role-ids | sec:permissions | sec:collections)
      }
};

(: Return role configuration information :)
declare function security:getRoles()
{
  if ( xdmp:database-name(xdmp:database()) ne "Security" )
  then
  	(: Need to read roles info from the "Security" database. :)
  	iv:invoke( "Security", xdmp:function(xs:QName("security:getRoles"), "/security/security.xqy") )
  else
    for $role in fn:collection(sec:roles-collection())/sec:role
    return 
    element sec:role {
    	$role/( sec:role-id | sec:role-name | sec:description | sec:role-ids | sec:permissions | sec:collections)
    }
};

(: Return amp configuration information :)
declare function security:getAmps()
{
	(: Need to read amp info from the "Security" database. :)
	if ( xdmp:database-name( xdmp:database() ) ne "Security" )
	then iv:invoke( "Security", xdmp:function(xs:QName("security:getAmps"),"/security/security.xqy") )
	else (
    for $amp in fn:collection(sec:amps-collection())/sec:amp
    return 
    element sec:amp {
    	$amp/( sec:amp-id | sec:local-name | sec:namespace | sec:document-uri | sec:database | sec:role-ids)
    }
	)
};

(: Return collection configuration information :)
declare function security:getCollections()
{
	(: Need to read collection info from the "Security" database. :)
	if ( xdmp:database-name( xdmp:database() ) ne "Security" )
	then iv:invoke( "Security", xdmp:function(xs:QName("security:getCollections"),"/security/security.xqy") )
	else (
    for $collection in fn:collection(sec:collections-collection())/sec:collection
    let $uri := $collection/sec:uri
    let $permissions := try { sec:collection-get-permissions($uri) } catch($x) { $x }
    let $roles := distinct-values($permissions/sec:role-id)
    return 
    element sec:collection {
    	$collection/( sec:uri | sec:collection-id),
    	<sec:roles>{$roles}</sec:roles>,
    	<sec:permissions>{$permissions}</sec:permissions>
    }
	)
};

(: Return all privilege configuration information :)
declare function security:getPrivileges()
{
	(: Need to read privilege info from the "Security" database. :)
	if ( xdmp:database-name( xdmp:database() ) ne "Security" )
	then iv:invoke( "Security", xdmp:function(xs:QName("security:getPrivileges"),"/security/security.xqy") )
	else (
    for $priv in fn:collection(sec:privileges-collection())/sec:privilege
    order by $priv/sec:privilege-name
    return $priv
  )
};

(: Return execute privilege configuration information :)
declare function security:getExecutePrivileges()
{
	(: Need to read execute privilege info from the "Security" database. :)
	security:getPrivileges()[sec:kind eq "execute"]
};

(: Return URI privilege configuration information :)
declare function security:getUriPrivileges()
{
	(: Need to read URI privilege info from the "Security" database. :)
	security:getPrivileges()[sec:kind eq "uri"]
};
