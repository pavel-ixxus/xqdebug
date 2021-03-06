XQDebug is a web-based debugger for MarkLogic XQuery applications that is 
independent of any editor or browser.  It is useful for debugging native 
XQuery applications, RESTful web services and XQuery code in general. 
You can connect to any MarkLogic application server which will stop all 
requests to that appserver for debugging.  From the main XQDebug window 
you can select the stopped request to debug and can view the current 
expression, the call stack, variables, set breakpoints and watch 
expressions and step through the XQuery code.

To install XQDebug, copy the zip file to a directory named 'xqdebug' under
the Apps directory of the MarkLogic install directory for versions 4.6+ and 
the Docs directory for all versions before 4.6, unzip the contents
of the zip file into that directory then run the XQDebug install program.
For example, if you installed MarkLogic 5.0 in the "C:\Program Files\MarkLogic\" 
directory you would create the directory "C:\Program Files\MarkLogic\Apps\xqdebug\", 
then copy the zip file to that directory and unzip the file to that directory, 
then open a new browser windows and run: 
"http://localhost:8000/xqdebug/install/install.xqy".  

The install program creates the "xqdebug" user with "_xqdebug-role" role, sets 
up the XQDebug database, copies the code to that database, sets up an http 
appserver named 'xqdebug-http_9800' and initializes the debugger environment 
for all users that have the 'admin' role.

Once XQDebug is installed you can log into the debugger on port 9800 as any 
user with 'admin' role; for instance "http://localhost:9800/".

Please note that XQDebug should probably not be used to debug applications in
a production environment.  When XQDebug connects to an application server port 
all requests to that application server port will be stopped waiting to be debugged.
This would most likely not be good if your production server has a large amount
of traffic.

The XQDebug source code is included in the download and licensed under the 
BSD open source license. Feel free to make improvements and contribute them back 
to the project.

XQDebug was developed using Mozilla Firefox versions 8 through 15, Chrome versions
18 through 21 and Microsoft Internet Explorer versions 8 and 9.  Other browsers were 
not tested and may not work. If you find incompatibilities please send email to 
xqdebug@googlegroups.com and we will fix it as soon as possible.

A project description with current features and a roadmap for planned features 
and enhancements is contained in the file: 
"/docs/XQDebug Project Description.html" Unimplemented features are listed in red.

Enjoy!

******************************* Known Issues ******************************************
- Can't get or set breakpoints if the code has been called through one of xdmp:invoke()
  xdmp:eval() or xdmp:apply() or if the module resides in a protected filesystem 
  directory. If breakpoint information is not available for a particular line of 
  source code a dash "-" will appear in the breakpoint column of the source window.
  
  This is a limitation of the MarkLogic debug API and MarkLogic has been notified.
  

******************************** Change Log *******************************************

Version 1.0.7:
- Replace xdmp:properties() calls with fn:doc-available() for better compatibility with MarkLogic 6.
- Reworked stepping functionality to force sequentialization.
- Reworked installation to work better with MarkLogic 6.

Version 1.0.6:
- Display Debugger version
- Allow debugging by any user with execute privilege "http://marklogic.com/xdmp/privileges/debug-any-requests"
  (Used to restrict to admin role.)

Version 1.0.5:
- Support for MarkLogic Server 5.0-1
- Remove unused editarea javascript code.
- Fix for redirect cycle issue.

Version 1.0.3:
- Better tracking of current request.
- Improved install information.

Version 1.0.2:
- Database Explorer no longer requires a URI Lexicon on the target database.
- Added ability to resize windows and persist window sizes between sessions. 
    (Special thanks to Michael Fagan for the resize enhancement.)
- Fixed 404 error after running install.(Workaround, run install a second time.)
- Can now display source modules on file system in MarkLogic's Modules directory.
- Added no-cache directives to all pages so browsers don't cache debugger pages.
