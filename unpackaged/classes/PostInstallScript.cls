public without sharing class PostInstallScript implements InstallHandler {

    public void onInstall( InstallContext context ) {
        Boolean isInstall = context.previousVersion() == null;
        Utils.updateCustomSettings( isInstall );
        if( isInstall ) {
            CountryServices.recreateCountryMappings();
            BatchRepairAddresses.schedule();
        } else {
            if( context.previousVersion().compareTo( new Version( 1, 16 ) ) <= 0 ) { //when upgrading from versions 1.0-1.16 inclusive
                BatchRepairAddresses.schedule();
                Database.executeBatch( new BatchUpdateAddresses(), (Integer)Utils.aamSettings.Chunk_Size_For_Address_Batch__c );
            }
        }
    }

}