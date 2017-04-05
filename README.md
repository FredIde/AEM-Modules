AEM-Modules
==========

### Welcome to CQ-Powershell-Modules
For my daily work I created this powershell module. With this module you can automate some cq step on a easy and simple way.

Example 1: Create a new page

`[ps] c:\foo> $cqobject = Get-CQHost -cqHost "myserver" -cqPort "5000" -cqUser "john" -cqPassword "deer"`    

`[ps] c:\foo> Add-CQPage -title "My Title" -parentPath "/content" -template "/apps/myapp/components/homepage" -cq $cqOject`

Example 2: Create a Group

`[ps] c:\foo> Add-CQGroup -groupName "mygroupname" -cq $cqOject`

### Help
Some wants to help for more funcationality? Then contact me.

### disclaimer of liability
The author does not assume liability for errors contained in or for damages arising from the use of the software.

### Support or Contact
Have you any question? Please contact me.
