(:------------------------------------------------------------------------:
   Copyright (c) 2010, Intellectual Reserve, Inc.  All rights reserved. 
 :------------------------------------------------------------------------:)
xquery version "1.0-ml";
declare namespace this = "this";
import module namespace perm = "/xqdebug/security/permissions" at "/security/permissions.xqy";

declare function this:nbsp($x) { if (exists($x) and string-length($x) > 0) then $x else "&nbsp;" };

declare function this:img($img) {
	element img { 
		attribute border {"0"}, 
        attribute hspace {"4"},
		attribute src { concat("images/",$img) }     
	} 
};

declare function this:data-join($x,$y)
{
	for $k at $i in $x
	return ($k, if($i=count($x)) then () else $y)
};

declare function this:bg($c) {
	attribute style { concat("background-image:url('images/",$c,"')") }
};

declare function this:trheader($bg,$c,$t) {
	element tr { element td { this:bg($bg), attribute colspan { "3" }, attribute align { "center" }, element h2 { this:img($c), $t } } }
};

declare function this:header($img,$txt) {
	element tr { element td { 
		attribute colspan { "3" }, 
		attribute align { "center" }, 
		this:img($img)
	}}
};

declare function this:tr($u,$bg,$full,$db) {
    element tr { 
    	this:bg($bg),
        attribute valign {"top"},
    	element td { 
            attribute width { "40%"},
            attribute style { "text-align: left;"},
    		element a { 
    			attribute href { concat("explore.xqy?uri=",$u/@all,"&amp;db=",$db) }, 
    			if(data($u/@dir)="true") 
    			then this:img("folder.png") 
    			else this:img("file.png"),
    			if($full) then data($u/@all) else data($u/@name) 
    		}
    	},
    	element td { 
            attribute width { "20%"},
            attribute align { "center" },
            attribute style { "text-align: left;"},
    		this:nbsp(data($u/@lastModified)) 
    	},
    	element td { 
            attribute width { "40%"},
            attribute style { "text-align: left;"},
    		if(exists($u//role))
    		then
    			this:data-join(
    				for $i at $index in $u//role
    				return text { concat(data($i/@name),":",data($i/@permissions)) }, 
    				element br {}
    			)
    		else "&nbsp;"
    	}
    }
};

try {
	let $uri := xdmp:get-request-field("uri","/")
	let $db := xdmp:get-request-field("db","Documents")
	let $stuff := 
		let $parents:= perm:getDirectParents($db,$uri)
		let $children:= perm:getDirectChildren($db,$uri)
		return (
            element h3 { concat("Exploring (", $db, ") ", $uri) },
            <span>
                <h3>{ this:img("folder.png") } Ancestors</h3>
            </span>,
            <table cellspacing="0" cellpadding="1" border="1" width="100%" class="statustable">
                <tbody>
                    <tr class="statusrowtitle">
                        <th class="statustitle">URI</th>
                        <th class="statustitle">Last Updated</th>
                        <th class="statustitle">Permissions</th>
                    </tr>
                    {                
                        for $u in $parents/child
                        return 
                            this:tr($u, (), true(),$db)
                    }
                </tbody>
            </table>,
            <span>
                <h3>{ this:img("folder.png") } Child Folders</h3>
            </span>,
            <table cellspacing="0" cellpadding="1" border="1" width="100%" class="statustable">
                <tbody>
                    <tr class="statusrowtitle">
                        <th class="statustitle">URI</th>
                        <th class="statustitle">Last Updated</th>
                        <th class="statustitle">Permissions</th>
                    </tr>
                    {                
                        for $u in $children//child[@dir="true"] 
                        order by $u/@name
                        return 
                            this:tr($u, (), false(),$db)
                    }
                </tbody>
            </table>,
            <span>
                <h3>{ this:img("file.png") } Child Documents</h3>
            </span>,
            <table cellspacing="0" cellpadding="1" border="1" width="100%" class="statustable">
                <tbody>
                    <tr class="statusrowtitle">
                        <th class="statustitle">URI</th>
                        <th class="statustitle">Last Updated</th>
                        <th class="statustitle">Permissions</th>
                    </tr>
                    {                
                        for $u in $children//child[@dir="false"] 
                        order by $u/@name
                        return 
                            this:tr($u, (), false(),$db)
                    }
                </tbody>
            </table>
        )
	return
	<html xmlns="http://www.w3.org/1999/xhtml" >
        <head>
            <link href="/assets/styles/xqdebug.css" rel="stylesheet"/>
        </head>
		<body>
			{ $stuff }
		</body>
	</html>
} catch($e) {
	if($e//error:code = "XDMP-URILXCNNOTFOUND")
	then 
		<html xmlns="http://www.w3.org/1999/xhtml" >
			<body>
				<h1>Database '{xdmp:get-request-field("db","Documents")}' has no URI lexicon. Cannot explore.</h1>
			</body>
		</html>
	else $e
}