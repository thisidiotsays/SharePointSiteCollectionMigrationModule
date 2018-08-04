
# SharePoint Site Collection Migration Module

This module was built as part of a project I am working on to migrate a number of site collections between content databases.

**It is currently still under development as I look to add more features and tighten up the error handling.**

The module exposes a number of functions which mimic the steps I would follow to move multiple site collections:

1. Set the site collection(s) status to read-only
2. Run Backup-SPSite prior to moving each site incase we need to restore the site
3. Run Move-SPSite to carry out the actual site collection move to the target content database
4. Do an IIS Reset on all the servers in the SharePoint farm
5. Set the status of the site collections to Unlock

## What the module does



At the moment I don't load the SharePoint Snap-in as part of the module as I noticed this could cause issues when reloading the module. Although I think this is more an issue during development rather than just running the module.
