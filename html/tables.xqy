(:------------------------------------------------------------------------:
   Copyright (c) 2010, Intellectual Reserve, Inc.  All rights reserved. 
 :------------------------------------------------------------------------:)
xquery version "1.0-ml";

module namespace tables="/xqdebug/html/tables";

declare default function namespace "http://www.w3.org/2005/xpath-functions";
declare option xdmp:mapping "false";


declare function tables:outputTables($tables as element()) 
as element()+
{
	for $table in $tables/descendant-or-self::element()[@ftype eq "table"]
	return	tables:outputTable($table)
};


declare function tables:outputTable($parent as element())
as element()+
{
	let $fcells := $parent/format/cell
	let $footer := $parent/footer/cell
	let $rows	:= $parent/*[@ftype eq "row"]
	let $class := $parent/@class/data(.)
	let $sortcol := if ($parent/@sortcol) then $parent/@sortcol/data(.) else $fcells/cell[1]/@name/data(.)
	return 
	<table id="{name($parent)}" style="width:100%;" border="1" cellspacing="0" cellpadding="1">
	  {
	    if ( fn:exists( $class ) ) then attribute class {$class} else (),
	    if ( fn:exists( $sortcol ) ) then attribute sortcol {$sortcol} else (),
	    $parent/caption
	  }
		<thead><tr>  {
			for $cell in $fcells
			return (<th>{$cell/@title/data(.)}</th>) 
		} </tr></thead>
		<tfoot>{(: TODO :)}</tfoot>
		<tbody>{
		for $data at $row in $rows[1 to last()]
		order by $sortcol
		return 
			<tr >
			{
			  if($row mod 2 ne 0) 
			  then attribute class {"odd"}
			  else ()
			  ,
				for $cell in $fcells
				let $content := $data/*[fn:local-name(.) eq fn:data($cell/@name)]
				return 
					<td> { 
						$cell/@style,
						if ( exists($content/*) ) then $content/* else data($content)
					} </td>
			} </tr>
		}</tbody>
	</table>
};

