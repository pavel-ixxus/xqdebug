(:------------------------------------------------------------------------:
   Copyright (c) 2010, Intellectual Reserve, Inc.  All rights reserved. 
 :------------------------------------------------------------------------:)
xquery version "1.0-ml";
module namespace perm="/xqdebug/security/permissions";

import module namespace iv="/xqdebug/shared/common/invoke" at "/shared/common/invoke/invokeFunctions.xqy";

declare option xdmp:mapping "false";

(:--------------------------------------------------------------------------------------------------------------------------------------------------------------------
  get explore information about the files 
  --------------------------------------------------------------------------------------------------------------------------------------------------------------------:)

declare function perm:getUriElement($uri)
{
	let $child := perm:removeEmptyStrings(fn:tokenize($uri,"/"))[fn:last()]
	let $parent := fn:substring($uri,0,1 + (fn:string-length($uri) - fn:string-length($child)))
  	let $props := xdmp:document-properties($uri)
	return element child { 
	  			attribute all { $uri }, 
	  			attribute parent { $parent }, 
	  			attribute name { $child }, 
	  			attribute dir { if(fn:exists($props/prop:properties/prop:directory)) then "true" else "false" },
	  			attribute lastModified { $props/prop:properties/prop:last-modified/text() },
	  			element  roles { perm:documentListPermissions($uri) },
	  			$props
	  		}
};

declare function perm:getDirectChildren($db,$dir)
{
  iv:invoke($db, xdmp:function(xs:QName("perm:getDirectChildren"),"/security/permissions.xqy"), $dir)
};

declare function perm:getDirectChildren($dir)
{
	element results {
	  	for $uri in cts:uri-match( fn:concat($dir,"*") ) 
	  	let $child := fn:substring( $uri, fn:string-length($dir) + 1)
	  	let $endsWithSlash := fn:ends-with($child,"/")
	  	let $slashes := fn:count( fn:tokenize($child,"/") ) - 1
	  	return 
	  		if((($slashes = 0) or ($endsWithSlash and $slashes = 1)) and fn:not($uri = $dir)) 
	  		then perm:getUriElement($uri)
	  		else ()
	}
};

declare function perm:getDirectParents($db,$dir)
{
  iv:invoke($db, xdmp:function(xs:QName("perm:getDirectParents"),"/security/permissions.xqy"), $dir)
};
declare function perm:getDirectParents($dir)
{
	element results {
	  	for $uri in perm:getParentFolders($dir)
	  	return perm:getUriElement($uri)
	}
};

declare function perm:getParentFolders($uri as xs:string)  {
	let $map:= map:map()
	return 
		for $n at $i in ("",perm:removeEmptyStrings(perm:tokenize($uri,"/")))
		let $noop := map:put($map,"uri", fn:concat(map:get($map,"uri"),$n,"/"))
		return map:get($map,"uri")
};

(:~
	Remove all empty strings from the sequence

	@param $str The string sequence

	@return The new sequence with no empty strings in it
~:)
declare function perm:removeEmptyStrings($str as xs:string*)
{
    for $s in $str
    return if (fn:string-length($s) > 0) then $s else ()
};

(:~
	Split a string into tokens enumerated by the seperator $sep.  
	Then remove all whitespace from the tokens.
	NOTE:  The order of removing whitespace after tokenizing is significant because the seperator may be whitespace.

	@param $string The string to tokenize
	@param $sep The separator character (xs:string) to tokenize on

	@return the sequence os tokens
~:)
declare function perm:tokenize($string as xs:string*,$sep as xs:string)
{
	if(fn:exists($string))
	then
		for $s in for $str in $string return fn:tokenize($str,$sep)
		return perm:removeWhiteSpace($s)
	else ()
};

(:~
	Remove all whitespace from a string

	@param $str The string to strip whitespace from

	@return The string with whitespace removed
~:)
declare function perm:removeWhiteSpace($str as xs:string)
as xs:string
{
	fn:replace($str, "(^\s+|\s+$)", "")
};


(:--------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Returns an element listing all the permissions assigned to a document. 
  --------------------------------------------------------------------------------------------------------------------------------------------------------------------:)
(:
::      perm:documentListPermissions("/some/doc.xml")
::            returns ->
::                    <role privs="insert read update" role="security" id="10537665952050657762"/>
:)

declare function perm:documentListPermissions($documentUri as xs:string) as element(role)* 
{
	let $map := map:map()
	let $permissions  := xdmp:document-get-permissions($documentUri)
	let $roleIds           := fn:distinct-values($permissions//sec:role-id)
	(: load the role map :)
	let $noop := 
		for $r at $i in $roleIds
		let $n := try { iv:invoke("Security", xdmp:function(xs:QName("sec:get-role-names"), "/MarkLogic/security.xqy"), $r) } catch($x) { $r }
		let $n := if(fn:exists($n)) then $n else $i
		return map:put($map,xs:string($n),$r)
	return
		if( fn:count(map:keys($map)) > 0)
		then
			for $role in map:keys($map)
			order by $role
			return element role { 
				attribute name { $role }, 
				attribute permissions {
					let $prms :=
						for $p in $permissions[./sec:role-id = map:get($map,$role)]/./sec:capability
						return typeswitch(element {fn:data($p)}{})
							case element(read) return "r"
							case element(insert) return "i"
							case element(update) return "u"
							case element(execute) return "x"
							default return ()                        
					let $shortPerms := perm:permissionsValidate( fn:string-join($prms,"") )
					return $shortPerms
		 		}
			}
		else () (: element role { attribute name { "no permissions" } } :)
};

declare function perm:permissionsValidate( $permissions as xs:string ) 
{
    let $valid := "riux-"
    let $format := "riux"
    let $p := fn:lower-case($permissions)
    let $onlyContainsValidPermissions := 
        every $z in 
            for $c in 1 to fn:string-length($p)
            return fn:contains( $valid, fn:substring($p,$c,1)) 
        satisfies $z
    return
        if ( fn:not($onlyContainsValidPermissions) )
        then fn:error(xs:QName("INVALID_PERM_FORMAT"),"Invalid permissions format. Should be of the form 'riux'.",$permissions) 
        else
            let $formatted := 
                fn:string-join(
                    for $i in 1 to fn:string-length($format)
                    let $x:= fn:substring($format,$i,1)
                    return if( fn:contains($p,$x)) then $x else () (:"-":)
                ,"")
            let $needsReadToo := 
                fn:not( fn:contains($formatted,"r") ) and
                    ( some $z in 
                        for $c in 1 to fn:string-length($formatted)
                        return fn:contains($valid, fn:substring($p,$c,1)) 
                    satisfies $z )
            return 
                if($needsReadToo and (fn:string-length($formatted) > 0)) 
                then perm:permissionsValidate( fn:concat($formatted,"r") )
                else $formatted
};
