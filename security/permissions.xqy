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
	  	for $uri in xdmp:directory-properties( $dir, "1")/fn:base-uri(.) 
	  	return perm:getUriElement($uri)
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

declare function perm:getParentFolders($uri as xs:string)
{
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
    return if ( $s ) then $s else ()
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
declare private variable $pnames := ("read", "insert", "update", "execute");
declare private variable $pchars := ("r", "i", "u", "x");
declare function perm:documentListPermissions($documentUri as xs:string) as element(role)* 
{
	let $map := map:map()
	let $permissions := xdmp:document-get-permissions($documentUri)
	let $roleIds     := fn:distinct-values($permissions//sec:role-id)
	(: load the role map :)
	let $noop := 
		for $r at $i in $roleIds
		let $n := try { iv:invoke( "Security", xdmp:function(xs:QName("sec:get-role-names"), "/MarkLogic/security.xqy"), $r) } catch($x) { $r }
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
						let $perm := fn:data($p)
						return $pchars[ fn:index-of( $pnames, $p ) ]
					return perm:permissionsValidate( fn:string-join($prms,"") )
		 		}
			}
		else () (: element role { attribute name { "no permissions" } } :)
};

declare private variable $valid := ("r", "i", "u", "x", "-");
declare private variable $format := ("r", "i", "u", "x");
declare function perm:permissionsValidate( $permissions as xs:string ) 
{
    let $p := for $c in fn:string-to-codepoints( fn:lower-case($permissions) ) 
              return fn:codepoints-to-string( $c )
    let $onlyContainsValidPermissions := 
        every $z in 
            for $c in $p
            return ($c = $valid) 
        satisfies $z
    return
        if ( fn:not($onlyContainsValidPermissions) )
        then fn:error(xs:QName("INVALID_PERM_FORMAT"),"Invalid permissions format. Should be of the form 'riux'.",$permissions) 
        else
            let $formatted := 
                    for $x in $format
                    return if( $x = $p ) then $x else () (:"-":)
            return 
                if( fn:not( "r" = $formatted ) and fn:exists( $formatted ) ) 
                then fn:string-join( ( "r", $formatted ), "" )
                else fn:string-join( $formatted, "" )
};
