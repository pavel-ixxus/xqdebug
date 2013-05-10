(:------------------------------------------------------------------------:
  Copyright (c) 2010, Intellectual Reserve, Inc.  All rights reserved. 
 :------------------------------------------------------------------------:)
(: ***************************************************************************************************
  XQDebug install is a sequence of multiple transactions that must occur in a specific order.
  **** DO NOT reorder or combine transactions in this script!!! ****  
  The transactions are seperate, ordered and distinct for a reason.
****************************************************************************************************** :)

(: ***** Create '_debug' Role ***** :)
xquery version "1.0-ml";
import module namespace iv="/xqdebug/shared/common/invoke" at "../shared/common/invoke/invokeFunctions.xqy";
import module namespace sec="http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
declare variable $dbg-role-name := "_xqdebug-role";

let $file := fn:concat( xdmp:install-directory(), "/", xdmp:modules-root(), "xqdebug/versions.xml")
return fn:concat( "XQDebug ", xdmp:document-get( $file )/project/version/text(), " Install Start ..." )
,

(: ********************* Create Roles ********************* :)
"", fn:concat( "Creating Role: '", $dbg-role-name, "' ... " )
,
try {
  let $role-id := 
        iv:invoke( "Security", 
           xdmp:function( xs:QName("sec:create-role"), "/MarkLogic/security.xqy" ),
           $dbg-role-name, "Role for using XQDebug debugger", "admin", (), ()
         )
  return
    fn:concat( "Created '", $dbg-role-name, "' Role - '", xs:string($role-id), "'" )
}
catch( $ex ) {

  if ( $ex/error:code eq "SEC-ROLEEXISTS" )
  then (
    (: Verify that role has 'admin' role :)
    let $admin-id := xdmp:role( "admin" )
    return
      if ( fn:not( $admin-id = xdmp:role-roles( $dbg-role-name ) ) )
      then (
        let $role-id := 
            iv:invoke( "Security", 
                     xdmp:function( xs:QName("sec:role-add-roles"), "/MarkLogic/security.xqy" ),
                     $dbg-role-name, ("admin")
                   )
        return
          fn:concat( "Role '", $dbg-role-name, "' already exists, added 'admin' role." )
      )
      else 
        fn:concat( "Role '", $dbg-role-name, "' already exists." )
  )
  (: What exception did we throw? :)
  else xdmp:rethrow()
}
;

(: ********************* Create Users ********************* :)
(: ***** Create 'xqdebug' User ***** :)
xquery version "1.0-ml";
import module namespace iv="/xqdebug/shared/common/invoke" at "../shared/common/invoke/invokeFunctions.xqy";
import module namespace sec="http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";

declare variable $dbg-role-name := "_xqdebug-role";
declare variable $dbg-user-name := "xqdebug";

"", fn:concat( "Creating User: '", $dbg-user-name, "' ... " )
,
try {
  let $user-id := 
    iv:invoke( "Security", 
             xdmp:function( xs:QName("sec:create-user"), "/MarkLogic/security.xqy" ),
             $dbg-user-name, "XQDebug User", "debug", $dbg-role-name, (), ()
           )
  return
    fn:concat( "Created '", $dbg-user-name, "' User: '", xs:string($user-id), "'" )
}
catch( $ex ) {

  if ( $ex/error:code eq "SEC-USEREXISTS" )
  then (
    (: Verify that user has correct xqdebug role :)
    if ( fn:not( xdmp:role( $dbg-role-name ) = xdmp:user-roles( $dbg-user-name ) ) )
    then (
      let $user-id := 
          iv:invoke( "Security", 
                   xdmp:function( xs:QName("sec:user-add-roles"), "/MarkLogic/security.xqy" ),
                   $dbg-user-name, $dbg-role-name
                 )
      return
        fn:concat( "User '", $dbg-user-name, "' already exists, added role'", $dbg-role-name, "'" )
    )
    else
      fn:concat( "User '", $dbg-user-name, "' already exists." )
  )
  else xdmp:rethrow()
  
}
;


(: ********************* Create Databases then Forests then attach forests to databases ********************* :)

(: ***** Create 'XQDebug' database ***** :)
xquery version "1.0-ml";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
declare variable $dbg-db-name := "XQDebug";

"", fn:concat( "Creating Database: '", $dbg-db-name, "' ... " )
,
try {
  (: If the DB doesn't exist xdmp:database() will throw an exception and we will create the DB in the catch block :)
  let $dbid := xdmp:database( $dbg-db-name )
  return fn:concat( "Database '", $dbg-db-name, "' already exists." )
}
catch($ex) {
  (: if database doesn't exist create it. :)
  if ( $ex/error:code eq "XDMP-NOSUCHDB" )
  then (
    admin:save-configuration( 
        admin:database-create( admin:get-configuration(), $dbg-db-name, xdmp:database("Security"), xdmp:database("Schemas")) 
    )
    ,
    fn:concat( "Database '", $dbg-db-name, "' Created." )
  )
  else xdmp:rethrow()
}
;


(: ***** Configure 'XQDebug' database ***** :)
xquery version "1.0-ml";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
declare variable $dbg-db-name := "XQDebug";

"", fn:concat( "Configuring Database: '", $dbg-db-name, "' ... " )
,
(: We already created the DB.  If it doesn't exist now xdmp:database() will throw an exception ... let it. :)
let $dbId := xdmp:database( $dbg-db-name )
let $config := admin:database-set-uri-lexicon( admin:get-configuration(), $dbId, fn:true())
let $config := admin:database-set-collection-lexicon( $config, $dbId, fn:true())
let $config := admin:database-set-triggers-database( $config, $dbId, $dbId ) (: Set triggers DB to XQDebug DB :)
(: Adding a lexicon that already exists will throw a exception ... check existence and add. :)
let $config := 
    if ( fn:not( "http://marklogic.com/collation/codepoint" = admin:database-get-word-lexicons( $config, $dbId ) ) )
    then admin:database-add-word-lexicon($config, $dbId, admin:database-word-lexicon("http://marklogic.com/collation/codepoint"))
    else $config
return
  admin:save-configuration( $config )
,
fn:concat( "Database '", $dbg-db-name, "' Configured" )
;


(: ***** Create 'XQDebug' Forest ***** :)
xquery version "1.0-ml";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
declare variable $dbg-db-name := "XQDebug";

"", fn:concat( "Creating Forest: '", $dbg-db-name, "' ... " )
,
try {
  (: If the forest doesn't exist xdmp:forest() will throw an exception and we will create the forest in the catch block :)
  let $dbid := xdmp:forest( $dbg-db-name )
  return fn:concat( "Forest '", $dbg-db-name, "' already exists." )
}
catch($ex) {
  (: if forest doesn't exist create it. :)
  if ( $ex/error:code eq "XDMP-NOSUCHFOREST" )
  then (
    admin:save-configuration( 
        admin:forest-create( admin:get-configuration(), $dbg-db-name, xdmp:host(), () ) 
    )
    ,
    fn:concat( "Forest '", $dbg-db-name, "' Created." )
  )
  else xdmp:rethrow()
}
;


(: ***** Attach 'XQDebug' forest to database ***** :)
xquery version "1.0-ml";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
declare variable $dbg-db-name := "XQDebug";

"", fn:concat( "Attaching '", $dbg-db-name, "' Forest to Database... " )
,
(: We already created the DB.  If it doesn't exist now xdmp:database() will throw an exception ... let it. :)
let $dbId := xdmp:database( $dbg-db-name )
let $fId  := xdmp:forest( $dbg-db-name )
let $config := admin:get-configuration()
return
  if ( fn:not( $fId = admin:database-get-attached-forests( $config, $dbId ) ) )
  then (
    admin:save-configuration( admin:database-attach-forest( $config, $dbId, $fId ) )
    ,
    fn:concat( "Forest '", $dbg-db-name, "' Attached to Database." )
  )
  else "Forest Already Attached."
;

(: ********************* Setup the Database: Clear and then provision folders ********************* :)

(: ***** Delete the Database Contents ***** :)
xquery version "1.0-ml";
import module namespace iv="/xqdebug/shared/common/invoke" at "../shared/common/invoke/invokeFunctions.xqy";
declare variable $dbg-db-name := "XQDebug";

"", fn:concat( "Deleting all data in '", $dbg-db-name, "' Database... " )
,
try {
  iv:invoke( $dbg-db-name, xdmp:function( xs:QName("xdmp:directory-delete"), "" ), "/" )
  ,
  "Directory '/' successfully deleted."
}
catch ($ex) {
  (: If it doesn't exist ... it doesn't exist :)
  if ( $ex/error:code eq "XDMP-DOCNOTFOUND" )
  then "Database is empty."
  else xdmp:rethrow()
}
;

(: ***** Create Directories ***** :)
xquery version "1.0-ml";
import module namespace iv="/xqdebug/shared/common/invoke" at "../shared/common/invoke/invokeFunctions.xqy";
declare variable $dbg-db-name := "XQDebug";
declare variable $dbg-modules-dir := "/code/xqdebug/";
declare variable $dbg-session-dir := "/content/xqdebug/session/";

"", fn:concat( "Creating Directories... " )
,
try {
  iv:invoke( $dbg-db-name, xdmp:function( xs:QName("xdmp:directory-create"), "" ), $dbg-modules-dir ),
  iv:invoke( $dbg-db-name, xdmp:function( xs:QName("xdmp:directory-create"), "" ), $dbg-session-dir ),
  "Directories Created."
}
catch ($ex) {
  (: If any of these directories exist ... then we missed a step. :)
  if ( $ex/error:code eq "XDMP-DIREXISTS" )
  then fn:error( $ex/error:code, "Directories should have been deleted in previous step.", $ex )
  else xdmp:rethrow()
}
;


(: ***** Create URI Privileges ***** :)
xquery version "1.0-ml";
import module namespace iv="/xqdebug/shared/common/invoke" at "../shared/common/invoke/invokeFunctions.xqy";
declare variable $dbg-role-name := "_xqdebug-role";
declare variable $root-dir := "/code/xqdebug/";
declare variable $dbg-content-dir := "/content/xqdebug/";
declare variable $dbg-content-priv := "_uri__content_xqdebug";
declare variable $dbg-code-priv := "_uri__code_xqdebug";

"", fn:concat( "Creating URI Privileges ... " )
,
try {
  let $priv := iv:invoke( "Security", xdmp:function( xs:QName("sec:get-privilege"), "/MarkLogic/security.xqy" ), $root-dir, "uri" )
  return fn:concat( "'", $dbg-code-priv, "' URI privilege exists." )
}
catch ($ex) {
  (: If it doesn't exist ... create it. :)
  if ( $ex/error:code eq "SEC-PRIVDNE" )
  then (
    let $priv := iv:invoke( "Security", xdmp:function( xs:QName("sec:create-privilege"), "/MarkLogic/security.xqy" ), 
                            $dbg-code-priv, $root-dir, "uri", $dbg-role-name 
                 )
    return fn:concat( "URI privilege '", $dbg-code-priv, "' created." )
  ) 
  else xdmp:rethrow()
}
,
try {
  let $priv := iv:invoke( "Security", xdmp:function( xs:QName("sec:get-privilege"), "/MarkLogic/security.xqy" ), $dbg-content-dir, "uri" )
  return fn:concat( "'", $dbg-content-priv, "' URI privilege exists." )
}
catch ($ex) {
  (: If it doesn't exist ... create it. :)
  if ( $ex/error:code eq "SEC-PRIVDNE" )
  then (
    let $priv := iv:invoke( "Security", xdmp:function( xs:QName("sec:create-privilege"), "/MarkLogic/security.xqy" ), 
                            $dbg-content-priv, $dbg-content-dir, "uri", $dbg-role-name 
                 )
    return fn:concat( "URI privilege '", $dbg-content-priv, "' created." )
  ) 
  else xdmp:rethrow()
}
;

(: ***** Delete Old Zip file if it exists ***** :)
xquery version "1.0-ml";

"", fn:concat( "Delete old xqdebug.zip file if it exists in Database... " )
,
try {
  let $zipname := "/code/xqdebug/xqdebug.zip"
  return
    if ( fn:exists( fn:doc-available( $zipname ) ) )
    then (
      xdmp:document-delete( $zipname )
      ,
      "Old Zip file deleted."
      )
    else "Verified old zip does not exist."
}
catch ($ex) {
  (: We only get here if either document-properties() or document-delete() throws an exception...
     Which only happens of the file does not exist.
  :)
  "Verified old zip does not exist."
}
;


(: ***** Load Modules into Database ***** :)
xquery version "1.0-ml";
import module namespace install="xqdebug/install-functions" at "/xqdebug/install/install-functions.xqy";
declare variable $dbg-db-name := "XQDebug";
declare variable $modules-dir := "/code/xqdebug/";
"", fn:concat( "Load ZIP or XAR File into Database... " )
,
try {
  let $filename := "/code/xqdebug/xqdebug.zip"
  let $dir := fn:concat( xdmp:install-directory(), "/", xdmp:modules-root(), "xqdebug")
  let $file := (xdmp:filesystem-directory( $dir )/*:entry[fn:ends-with(*:filename, ".zip") or fn:ends-with(*:filename, ".xar")][fn:starts-with(*:filename, "xqdebug")])[1]/*:pathname/fn:data(.)
  let $assert := 
        if ( fn:empty($file) ) 
        then 
          fn:error( xs:QName("ZIP-MISSING"), fn:concat("Could not find XQDebug zip file in ", $dir, "'") )
        else ()
  let $options := <options xmlns="xdmp:document-load"><uri>{$filename}</uri></options>
  let $load := xdmp:document-load($file, $options)
  return (
    fn:concat( "Loaded zip file '", $file, "' into database at '", $filename, "'" )
  )
}
catch ($ex) {
    xdmp:rethrow()
}
;

(: ***** Load Modules into Database ***** :)
xquery version "1.0-ml";
import module namespace install="xqdebug/install-functions" at "/xqdebug/install/install-functions.xqy";
declare variable $dbg-db-name := "XQDebug";
declare variable $modules-dir := "/code/xqdebug/";
"", fn:concat( "Load Modules from ZIP/XAR file into Database... " )
,
try {
    install:loadZip( $dbg-db-name, $modules-dir, fn:doc( "/code/xqdebug/xqdebug.zip" ) )
    ,
    "Modules Loaded."
}
catch ($ex) {
  xdmp:rethrow()
}
;


(: ************************* Initialize User Session Files ************************* :)
xquery version "1.0-ml";
import module namespace install="xqdebug/install-functions" at "/xqdebug/install/install-functions.xqy";
import module namespace iv="/xqdebug/shared/common/invoke" at "/xqdebug/shared/common/invoke/invokeFunctions.xqy";
import module namespace sec="http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
import module namespace setting = "/xqdebug/debug/session" at "/xqdebug/debug/session.xqy";
declare variable $dbg-db-name := "XQDebug";

"", fn:concat( "Initialize XQDebug config files for all users with 'admin' role ... " )
,
let $admin-id := xdmp:role("admin" )
let $users := 
      for $username in install:getUsers()[$admin-id = xdmp:user-roles(sec:user-name)]/sec:user-name/fn:data(.)
      return 
        iv:invoke( $dbg-db-name, xdmp:function( xs:QName("setting:initSessionForUser"), "" ), $username )/user/fn:data(.)
return
  fn:concat( "Initalized XQDebug for the following users: ", fn:string-join( $users, "," ) )
;


(: ***** Create Application servers ***** :)
xquery version "1.0-ml";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
declare variable $dbg-db-name := "XQDebug";
declare variable $server-name := "_xqdebug-http_9800";
declare variable $root-dir := "/code/xqdebug/";
declare variable $http-port := 9800;

"", fn:concat( "Creating HTTP Server '", $server-name, "'... " )
,
try {
  (: If the appserver doesn't exist xdmp:server() will throw an exception and we will create the appserver in the catch block :)
  let $sid := xdmp:server( $server-name )
  return fn:concat( "Server '", $server-name, "' already exists." )
}
catch($ex) {
  (: if appserver doesn't exist create it. :)
  if ( $ex/error:code eq "XDMP-NOSUCHSERVER" )
  then (
    let $dbId := xdmp:database( $dbg-db-name )
    let $config := admin:http-server-create( admin:get-configuration(), xdmp:group(), $server-name, $root-dir, $http-port, $dbId, $dbId )
    return admin:save-configuration( $config  )
    ,
    fn:concat( "Created Appserver '", $server-name, "'." )
  )
  else xdmp:rethrow()
}
;


(: ***** Configure Application servers ***** :)
xquery version "1.0-ml";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
declare variable $dbg-db-name := "XQDebug";
declare variable $server-name := "_xqdebug-http_9800";

"", fn:concat( "Configuring HTTP Server '", $server-name, "'... " )
,
(: 
  The appserver should have been created before now, if not something is wrong.
  xdmp:server() will throw an exception if appserver does not exist. 
:)
let $config := admin:get-configuration()
let $gids := admin:get-group-ids( $config )
return
  if ( admin:appserver-exists( $config, $gids, $server-name ) )
  then (
    let $sid := xdmp:server( $server-name )
    let $config := admin:appserver-set-debug-allow( admin:get-configuration(), $sid, fn:false() )
    let $config := admin:appserver-set-profile-allow( $config, $sid, fn:false() )
    return admin:save-configuration( $config  )
  )
  else (
  )
,
fn:concat( "Configured Appserver '", $server-name, "'." )
;


(: ********************************** FINISHED ***************************************** :)
let $file := fn:concat( xdmp:install-directory(), "/", xdmp:modules-root(), "xqdebug/versions.xml")
return (
  "", 
  fn:concat( "XQDebug ", xdmp:document-get( $file )/project/version/text(),  " Install: Finished!!!" )
)