(:------------------------------------------------------------------------:
   Copyright (c) 2010, Intellectual Reserve, Inc.  All rights reserved. 
 :------------------------------------------------------------------------:)
xquery version "1.0-ml";
import module namespace setting = "/xqdebug/debug/session" at "/debug/session.xqy";

<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
		<title>XQDebug</title>
    <meta http-equiv="cache-control" content="no-cache"/> 
    <meta http-equiv="pragma" content="no-cache"/> 
    <link rel="icon" type="image/png" href="/favicon.png" />
	</head>
	<frameset cols="20%, *" framespacing="1" frameborder="1">
		<frame src="left.xqy" name="navFrame" marginheight="0">
			<frame src="/debug/connect.xqy" name="resultFrame"/>
		</frame>
	</frameset>
</html>

