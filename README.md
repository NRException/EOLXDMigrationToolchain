# EOLXDMigrationToolchain
(Exchange online Cross Domain Migration Toolchain)
This toolchain was designed to migrate mailboxes from a legacy domain to a hybrid exchange deployment with a higher functional level.

There are a few things to keep in mind if you're going to use this toolchain, it was designed to be copied to the following path on the root C:\ drive of an exchange 2013 hybrid server; "C:\Scripts\Exchange Migration".
As this deployment comes in a ZIP format, you'll need to create the directory yourself and extract the files to that directory.

To set up the toolchain, please follow these steps (keeping in mind, this will need to be performed on one of your hybrid exchange servers):

1:  Ensure a powershell version level of 5.1 or greater, if you need to upgrade, please install the following package: https://www.microsoft.com/en-us/download/details.aspx?id=54616
  
2:  Create the following directory on your C:\ drive; "C:\Scripts\Exchange Migration"

3:  Extract the master ZIP on this github to the directory in step 2.
