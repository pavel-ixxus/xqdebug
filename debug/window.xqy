(:------------------------------------------------------------------------:
  Copyright (c) 2010, Intellectual Reserve, Inc.  All rights reserved. 
 :------------------------------------------------------------------------:)
xquery version "1.0-ml";

import module namespace win="/xqdebug/debug/window-expressions" at "/debug/window-functions.xqy";
declare option xdmp:mapping "false";

(: Update Window Dimensions :)
let $winId := xdmp:get-request-field("winId")
return if ( fn:exists($winId) ) 
then (
   let $width := xs:integer(xdmp:get-request-field("width", "100" ))
   let $height := xs:integer(xdmp:get-request-field("height", "400" ))
   let $result := win:setDimension( $winId, $width, $height )
   return 
     <html>{$result}</html>
)
else 
  <html>Not Found</html>

