# XQDebug - MarkLogic XQuery Debugger #
## Project Overview: ##
The goal of the XQDebug Project is to provide a Browser based debugger that is independent of any editor or browser, that can be installed and available for developers and administrators to develop and debug applications.

XQDebug uses the MarkLogic debugging (dbg) API as much as possible to accomplish debugging tasks. Where the dbg library does not yet provide functionality, or we encounter bugs, we may need to create workarounds until a fix or update is available.

XQDebug must run from and write to a database that is independent of any application or XQuery code that it is debugging. Otherwise it is possible to introduce changes in the state of the application that is being debugged. Therefore the install must create a database named XQDebug and copy all code and write all persisted information to that database.

## Prioritized Feature List: ##
The priority order of this feature list is only approximate because features are also grouped logically and some features in a group have a lower priority of being implemented.

The <font color='red'>features which are listed in red have not been implemented yet</font>.

  1. Windowing and window Layout (As functionality is added ...)
  1. Debug environment
    * Debugger role ("_xqdebug-role")
      * Inherits "admin" role
    * Debugger user ("xqdebug")
      * with "_xqdebug-role" role
    * Create "XQDebug" database"
      * collectionLexicon = "true"
      * wordLexicon = collation: http://marklogic.com/collation/codepoint
      * Create "/content/xqdebug/" directory
        * Clear permissions and privileges on directory
        * Set URI privilege with "_xqdebug-role" role
        * Set riu pemissions for "_xqdebug-role" role
    * In Debug database create "/code/xqdebug/" directory
      * URI Lexicon = true
      * Clear permissions and privileges on directory
      * Set URI privilege with "_xqdebug-role" role
      * Set rx pemissions for "_xqdebug-role" role
      * Load code from zip file
    * HTTP Server ("_xqdebug-http")
      * Port = 9800
      * Database = "XQDebug"
      * Modules = "XQDebug"
      * Digest authentication
      * Nobody default user
      * Debugging disallowed
      * Profiling disallowed
  1. Connect to and Disconnect from application server
    * List of Application Servers in a table or window listing
      * The number of currently stopped and running requests
      * Application server settings for debug, profile & logging
      * Default modules and content databases
    * On connect create list of all .xqy URIs available for debugging on that server.
  1._<font color='red'>Attach</font>/Detach/<font color='red'>Break into Request</font>
    * List of Requests (table or window): stopped, debugging
    * <font color='red'>List of Running requests with link or button to stop or break into the request for debugging</font>
  1. Expression Display
    * Retrieve and Persist Expression IDs
      * Retrieve & display source line(s)
      * Page
      * Source File
        * Source for current expression
        * <font color='red'>Select source file to display from application servers .xqy list.</font>
  1. Execution
    * Display
      * Scroll source window so to current line.
    * Stop & Continue
      * <font color='red'>jQuery for step/wait/eval</font>
    * Step
      * Step
      * Step Out (Next Expression)
      * Next Statement
      * Finish (function)
      * Run/Continue
  1. Breakpoints
    * Set
    * Display
    * Clear
    * <font color='red'>Persist Breakpoints between sessions</font>
  1. Stack Trace Frames with:
    * Source Line
    * Variables
    * <font color='red'>Global variables</font>
    * <font color='red'>External variables</font>
  1. Standalone Deployment program
  1. Watch window expressions <font color='red'>
<ol><li>Invoke module for debugging<br>
<ul><li>browser style URL for HTTP 'GET<br>
</li><li>setup 'POST' frame<br>
</li><li>jQuery select from application source files<br>
</li></ul></li><li>Eval() expression for debugging<br>
<ul><li>CQ style textbox to edit and expression<br>
</li><li>Button to run an expression ... except on execution expression is stopped on first line for debugging<br>
</li><li>Results window </font>
</li></ul></li><li>Windows & tables<br>
<ul><li>Resize, Expand & collapse<br>
<ul><li>Persist size between sessions<br>
</li></ul></li><li><font color='red'>Placement (rearrange) on screen<br>
<ul><li>Persist location between sessions<br>
</li></ul></li></ul></li><li>Source Editing:<br>
<ul><li>jQuery source editor<br>
</li><li>Edit<br>
</li><li>Save<br>
</li><li>Source Syntax highlighting<br>
</li><li>Hover display of:<br>
<ul><li>Variable value<br>
</li><li>Expression value<br>
</li><li>Function return value<br>
</li></ul></li><li>Select and Right click (jQuery) to:<br>
<ul><li>Variable type<br>
</li><li>Add to watch expressions<br>
</li><li>Run to cursor<br>
</li></ul></li><li>...</font>
</li></ul></li><li>CSS for display styles:<br>
<ul><li>Breakpoints<br>
</li><li><font color='red'>Hover on expression (highlight containing expression)</font></li></ul></li></ol>

### Debug Information Persisted to User Session File in XQDebug Database (As needed): ###

  1. All debug information associated with User Name
  1. App Server(s) State (Connected/Disconnected)
    * On Connect: <font color='red'>
<ul><li>Create list of all .xqy files in app-server modules DB below modules root<br>
</li><li>Save last expr-id of each line of each file </font>
</li></ul>  1. Current request
  1. Watch expressions <font color='red'>
<ol><li>Breakpoints<br>
</li><li>Associate Applications with their servers, databases and XQuery modules<br>
</li><li>Eval Expression<br>
</li><li>Invoke target/expression<br>
</li><li>Source File Information<br>
<ul><li>Media - DB or file-system<br>
</li><li>URI<br>
</li><li>Expression IDs by line #<br>
</li><li>Breakpoints<br>
</li><li>Functions - line, expr Id<br>
</li></ul></li><li>A link for each expression and it's text </font>
</li><li>Window sizes<font color='red'> and placement </font></li></ol>

### Display of Configuration information ###
  1. Users
  1. Roles
  1. Amps
  1. Collections
  1. Execute Privileges
  1. URI Privileges
  1. Permissions: <font color='red'>(Explorer like tree view of directories and files)<br>
<ul><li>Side by side view with users and roles<br>
</li><li>Highlight users with or without necessary roles to view/access files and directories. </font>