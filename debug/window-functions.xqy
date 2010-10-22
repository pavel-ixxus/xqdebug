(:------------------------------------------------------------------------:
  Copyright (c) 2010, Intellectual Reserve, Inc.  All rights reserved. 
 :------------------------------------------------------------------------:)
(: Window Functions :)
xquery version "1.0-ml";

module namespace winexp="/xqdebug/debug/window-expressions";

import module namespace setting = "/xqdebug/debug/session" at "/debug/session.xqy";

(:~
  Return the window diminsions by its id
  @param $winId Window ID in the dom
  return win element containing width and height attributes
~:)
declare function winexp:getWindow( $winId as xs:string )
as element( win )*
{
  setting:getField("windows")/win[@*:name=$winId]
};

(:~
  Set the diminsions of a window in session
  @param $winId Window ID in the dom
  @param $width The new window width
  @param $height The new window height
~:)
declare function winexp:setDimension( $winId as xs:string, $width as xs:integer, $height as xs:integer )
{
   let $wins := setting:getField("windows" )
   let $newWin := element { "win" } { 
                  attribute { "name" } { $winId },
                  attribute { "width" } { $width },
                  attribute { "height" } { $height } }

   return if ( fn:exists( $wins ) ) 
   then 
     let $win := $wins/win[@*:name=$winId]

     let $result := if ( fn:exists( $win ) )
     then xdmp:node-replace( $win, $newWin )
     else xdmp:node-insert-child( $wins, $newWin )
     return $result
   else 
     setting:setField( "windows", $newWin ) 
     
};

(:~
  Return the style attribute for parent div
  @param $winId Window ID in the dom
  return style attribute containing the user defined dimensions
~:)
declare function winexp:getParentStyle( $winId as xs:string? ) 
as xs:string
{
  let $win := winexp:getWindow( $winId ) 
  return 
    if ( fn:exists( $win ) )
    then fn:concat("left:0px; top:0px; width:",$win/@*:width,"px; height:",$win/@*:height,"px;")
    else "" 
};


(:~
  Return the style attribute for div
  @param $winId Window ID in the dom
  return style attribute containing the user defined dimensions
~:)
declare function winexp:getStyle( $winId as xs:string? ) 
as xs:string
{
  let $win := winexp:getWindow( $winId ) 
  return 
    if ( fn:exists( $win ) )
    then (
      fn:concat("width:",($win/@*:width)-2,"px; height:",($win/@*:height)-2,"px;")
    )
    else "" 
};

