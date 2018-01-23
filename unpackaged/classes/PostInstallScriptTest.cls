@isTest
private class PostInstallScriptTest {

    @isTest static void postInstallSetupNewSettings() {
        Aam_Settings__c settings = Aam_Settings__c.getOrgDefaults();
        if( settings.Id != null ) {
            DELETE settings;
        }

        PostInstallScript postInstall = new PostInstallScript();

        Test.startTest();
            Test.testInstall( postInstall, null );
        Test.stopTest();

        Aam_Settings__c result = Aam_Settings__c.getOrgDefaults();
        System.assert( settings.Id == null );
        System.assert( result.Id != null );
        List<Country_Mapping__c> mappings = [ SELECT Id FROM Country_Mapping__c LIMIT 1 ];
        System.assert( !mappings.isEmpty() );

        System.assertEquals( 1, [ SELECT CronExpression, CronJobDetail.Name, CronJobDetail.JobType
                                  FROM CronTrigger
                                  WHERE CronJobDetail.Name LIKE : '%' + BatchRepairAddresses.JOB_NAME + '%' ].size() );
    }

    @isTest static void postInstallUpdateFrom116To117() {
        Aam_Settings__c settings = Aam_Settings__c.getOrgDefaults();
        if( settings.Id != null ) {
            DELETE settings;
        }

        PostInstallScript postInstall = new PostInstallScript();
        Test.testInstall( postInstall, new Version( 1, 16 ) );

        Test.startTest();
            Test.testInstall( postInstall, new Version( 1, 17 ) );
        Test.stopTest();

        System.assertEquals( 1, [ SELECT CronExpression, CronJobDetail.Name, CronJobDetail.JobType
                                  FROM CronTrigger
                                  WHERE CronJobDetail.Name LIKE : '%' + BatchRepairAddresses.JOB_NAME + '%' ].size() );

    }

}