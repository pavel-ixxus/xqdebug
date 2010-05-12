XQDebug is a web-based debugger for MarkLogic XQuery applications that is 
independent of any editor or browser.  It is
useful for debugging native XQuery applications, RESTful web services and 
XQuery code in general. You can connect to any MarkLogic application server
which will stop all requests to that appserver for debugging.  From the main
XQDebug window you can select the stopped request to debug and can view 
the current expression, the call stack, variables, set breakpoints and 
watch expressions and step through the XQuery code.

To install XQDebug, copy the zip file to a directory named 'xqdebug' under
the Docs directory of the MarkLogic install directory, unzip the contents
of the zip file into that directory then run the XQDebug install program.
For example, if you installed MarkLogic in the "C:\Program Files\MarkLogic\" 
directory you would create the directory "C:\Program Files\MarkLogic\Docs\xqdebug\", 
copy the zip file to that directory, unzip the file to that directory, then 
open a new browser windows and run: 
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
BSD open source license. If you make improvements, you are welcome to 
contribute them back to the project.

XQDebug is developed using Mozilla Firefox 3.6 and MS Internet Explorer 8.
Other browsers are not tested, and may not work, but patches are welcome.

A project description with current features and a roadmap for planned 
features and enhancements is contained in the file: 
"/docs/XQDebug Project Description.html" Unimplemented features are listed in red.

Enjoy!

