(:------------------------------------------------------------------------:
   Copyright (c) 2010, Intellectual Reserve, Inc.  All rights reserved. 
 :------------------------------------------------------------------------:)
xquery version "1.0-ml";

import module namespace mhtml = "/xqdebug/html/html" at "/html/html.xqy";
import module namespace security = "/xqdebug/security/security" at "security/security.xqy";
import module namespace tables="/xqdebug/html/tables" at "/html/tables.xqy";

declare namespace as="http://marklogic.com/xdmp/assignments";
declare namespace db="http://marklogic.com/xdmp/database";
declare namespace fs="http://marklogic.com/xdmp/status/forest";
declare namespace gr="http://marklogic.com/xdmp/group";
declare namespace ho="http://marklogic.com/xdmp/hosts";
declare namespace hs="http://marklogic.com/xdmp/status/host";
declare namespace mi="http://marklogic.com/xdmp/mimetypes";
declare namespace sec = "http://marklogic.com/xdmp/security";
declare namespace ss="http://marklogic.com/xdmp/status/server";
declare namespace xhtml="http://www.w3.org/1999/xhtml";

declare option xdmp:mapping "false";

(: Store all request fields to session fields :)
let $isAdmin  := xdmp:has-privilege("http://marklogic.com/xdmp/privileges/debug-any-requests", "execute")
let $fields := xdmp:get-request-field-names()
let $session := for $field in $fields return xdmp:set-session-field($field, xdmp:get-request-field($field))

return (
xdmp:set-response-content-type("text/html"),

<html>
<head xmlns="http://www.w3.org/1999/xhtml">
	<title>XQDebug</title>
	<link rel="stylesheet" href="/assets/styles/xqdebug.css"/>
</head>

<body>
<table style="background-color:#E2E2E2; width:100%; border: 1px solid black;" cellspacing="0" cellpadding="0">
  <tr>
    <td align="left" width="100" style="border: 0;">
      <img src="/assets/images/XQDebug-in-crosshairs.jpg" vspace="3" width="50" height="50"/>
    </td>
    <td class="banner" style="text-align: left; vertical-align: middle;;">
      <strong>XQDebug</strong>
    </td>
  </tr>
</table>
<!-- 
<h4>Commands</h4>
-->
<div style="clear:both">
{
  if ($isAdmin) 
  then (
  	mhtml:fieldset( "Security", "collapse", 
  		<b>Security</b>,  
  		(
      mhtml:fieldset( "Permissions Explorer", "collapse", 
      	<a target="resultFrame" href="view.xqy?db=*">Permissions Explorer</a>,
      	for $id in xdmp:databases()
      	let $dbname := xdmp:database-name($id)
      	order by $dbname
      	return  <li><a target="resultFrame" href="security/explore.xqy?db={ $dbname }">{ $dbname }</a></li>
      	)
      ,
  		mhtml:fieldset("Users", "collapse", 
  			<span><a target="resultFrame" href="view.xqy?u=*">Users</a></span>,  
  			for $user in security:getUsers()
  			let $name := string($user/sec:user-name)
  			order by $name
  			return  <li><a target="resultFrame" href="view.xqy?u={ $name }">{ $name }</a></li>
  			),
  		mhtml:fieldset("Roles", "collapse", 
  			<span><a target="resultFrame" href="view.xqy?r=*">Roles</a></span>,  
  			for $role in security:getRoles()
  			let $name := string($role/sec:role-name)
  			order by $name
  			return  <li><a target="resultFrame" href="view.xqy?r={ data($role/sec:role-id) }">{ $name }</a></li>
  			),
  		mhtml:fieldset("Amps", "collapse", 
  			<span><a target="resultFrame" href="view.xqy?amps=*">Amps</a></span>,  
  			for $amp in security:getAmps()
  			let $name := string($amp/sec:local-name)
  			order by $name
  			return  <li><a target="resultFrame" href="view.xqy?amps={ data($amp/sec:amp-id) }">{ $name }</a></li>
  			),
  		mhtml:fieldset("Collections", "collapse", 
  			<span><a target="resultFrame" href="view.xqy?collection=*">Collections</a></span>,  
  			for $coll in security:getCollections()
  			let $uri := string($coll/sec:uri)
  			order by $uri
  			return  <li><a target="resultFrame" href="view.xqy?collection={ data($coll/sec:collection-id) }">{ $uri }</a></li>
  			),
  		mhtml:fieldset("Execute Privileges", "collapse", 
  			<span><a target="resultFrame" href="view.xqy?execpriv=*">Execute Privileges</a></span>,  
  			for $priv in security:getExecutePrivileges()
  			let $name := string($priv/sec:privilege-name)
  			order by $name
  			return  <li><a target="resultFrame" href="view.xqy?execpriv={ data($priv/sec:privilege-id) }">{ $name }</a></li>
  			),
  		mhtml:fieldset("URI Privileges", "collapse", 
  			<span><a target="resultFrame" href="view.xqy?uripriv=*">URI Privileges</a></span>,  
  			for $priv in security:getUriPrivileges()
  			let $name := string($priv/sec:privilege-name)
  			order by $name
  			return  <li><a target="resultFrame" href="view.xqy?uripriv={ data($priv/sec:privilege-id) }">{ $name }</a></li>
  			)
  		)
  	)
  	,
  	mhtml:fieldset("Debugger", "expand",
  	 <b>Debugger</b>,
  	 <ul id="dbg_session">
  	   <li  id="dbg_connect"><a href="/debug/connect.xqy" target="resultFrame">Connect / Disconnect</a></li>
  	   <li  id="dbg_stopped_requests"><a href="/debug/requestList.xqy#currentExpr" target="resultFrame">Debug Window</a></li>
  	   <li  id="dbg_breakpoints"><a href="/debug/breakpoints.xqy?display=true" target="resultFrame">Breakpoints</a></li>
  	   <li  id="dbg_watchexp"><a href="/debug/watch.xqy?display" target="resultFrame">Watch Expressions</a></li>
  	   <li  id="dbg_stack"><a href="/debug/stack.xqy" target="resultFrame">Stack</a></li>
  	   <li id="dbg_stepping">Execution
  	     <ul>
    	   <li  id="dbg_step"><a href="/debug/step.xqy?op=step" target="resultFrame">Step</a></li>
    	   <li  id="dbg_out"><a href="/debug/step.xqy?op=out" target="resultFrame">Next Expression</a></li>
    	   <li  id="dbg_next"><a href="/debug/step.xqy?op=next" target="resultFrame">Next Statement</a></li>
    	   <li  id="dbg_finish"><a href="/debug/step.xqy?op=finish" target="resultFrame">Finish Function</a></li>
    	   <li  id="dbg_continue"><a href="/debug/step.xqy?op=continue" target="resultFrame">Continue</a></li>
    	   </ul>
  	   </li>
  	 </ul>
  	)
	)
	else ()
}
</div>
</body>
</html>
)