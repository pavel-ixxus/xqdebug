(:------------------------------------------------------------------------:
   Copyright (c) 2010, Intellectual Reserve, Inc.  All rights reserved. 
 :------------------------------------------------------------------------:)
xquery version "1.0-ml";

module namespace mhtml = "/xqdebug/html/html";
import module namespace setting = "/xqdebug/debug/session" at "/debug/session.xqy";

declare namespace xhtml="http://www.w3.org/1999/xhtml";

declare default function namespace "http://www.w3.org/2005/xpath-functions";
declare option xdmp:mapping "false";

declare function mhtml:link( $href as xs:string, $target as xs:string, $desc as item() )
as element(a)
{
  if ( empty($target) or $target eq "")
  then <a href="{$href}">{$desc}</a>
  else <a href="{$href}" target="{$target}">{$desc}</a>
};

declare function mhtml:listItem( $item as item() )
as element(li)
{
  mhtml:listItem( "none", $item )
};
  
declare function mhtml:listItem( $class as xs:string, $item as item() )
as element(li)
{
  <li class="{$class}">{$item}</li>
};

declare function mhtml:list( $name as item()?, $default as xs:string, $list as element(li)*)
as element(ul)
{
  let $listId := xdmp:integer-to-hex(xdmp:hash32($name))
  let $display := xdmp:get-session-field($listId, if ($default ne "") then $default else "collapse")
  return
    if (empty($list) or ($display eq "none"))
    then <span>&times;&nbsp;{$name}</span>
    else 
      if ($display eq "expand")
      then <span><a text-decoration="none" href="left.xqy?{$listId}=collapse" target="_self">&minus;</a>&nbsp;{$name}<ul>{$list}</ul></span>
      else <span><a href="left.xqy?{$listId}=expand" target="_self">&plus;</a>&nbsp;{$name}<ul></ul></span>
};

declare function mhtml:legend($name as node())
as element(legend)
{
	mhtml:legend($name, "", "")
};

declare function mhtml:legend($name as node(), $displayId as xs:string, $default as xs:string)
as element(legend)
{
	<legend>
	{
		(: if $displayId is empty then revert to simple legend :)
		if ("" = ($displayId))
		then ()
		else 
			let $display := xdmp:get-session-field($displayId, if ($default ne "") then $default else () )
			return 
				if ($display eq "expand")
				then <a class="expand" href="left.xqy?{$displayId}=collapse" target="_self">-</a>
				else <a class="collapse" href="left.xqy?{$displayId}=expand" target="_self">+</a>
		,
		$name
	}
	</legend>
};

declare function mhtml:fieldset($legend, $data as element()*)
as element(fieldset)
{
	<fieldset>
	{
		mhtml:legend($legend)
		,  
		<div>{ $data }</div>
	}	
	</fieldset>
};

declare function mhtml:fieldset($fieldname as xs:string, $default as xs:string, $legendname,  $fieldData as element()*)
as element(fieldset)
{
	<fieldset>
	{
			let $legend := mhtml:legend($legendname, $fieldname, $default)
			return (
				$legend
				,
				if ($legend[1]/a/@class eq "expand")
				then $fieldData
				else ()
				)
	}	
	</fieldset>
};

declare function mhtml:radioInput($name as xs:string, $value as xs:string, $desc as xs:string, $check)
{
	if ($value eq $check) 
	then <input type="radio" name="{$name}" value="{$value}" checked="checked">{$desc}</input>
	else <input type="radio" name="{$name}" value="{$value}">{$desc}</input>
};

