@isTest
private class BatchRepairAddressesTest {

	@isTest static void schedule() {
        BatchRepairAddresses.schedule();

        List<CronTrigger> cronTriggers = [ SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE : '%' + BatchRepairAddresses.JOB_NAME + '%' ];
        System.assertEquals( 1, cronTriggers.size() );
	}

	@isTest static void cancel() {
        BatchRepairAddresses.schedule();
        BatchRepairAddresses.cancel();

        List<CronTrigger> cronTriggers = [ SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE : '%' + BatchRepairAddresses.JOB_NAME + '%' ];
        System.assertEquals( 0, cronTriggers.size() );
	}

    @isTest static void reSchedule() {
        BatchRepairAddresses.schedule();
        BatchRepairAddresses.schedule();

        List<CronTrigger> cronTriggers = [ SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE : '%' + BatchRepairAddresses.JOB_NAME + '%' ];
        System.assertEquals( 1, cronTriggers.size() );
    }

    @isTest static void runJob() {
        Utils.aamSettings.Disable_Account_Move_Delete_Function__c = false;
        UPSERT Utils.aamSettings;

        Test.startTest();
            Id batchId = Database.executebatch( new BatchRepairAddresses(), 20 );
        Test.stopTest();

        System.assert( batchId != null );
    }

    @isTest static void runJobWithData() {
        Utils.aamSettings.Disable_Account_Move_Delete_Function__c = false;
        UPSERT Utils.aamSettings;

        Account account = new Account( Name = 'First Account' );
        INSERT account;

        Account account2 = new Account( Name = 'Second Account', ParentId = account.Id );
        INSERT account2;

        Address__c address = new Address__c();
        address.Account__c = account.Id;
        INSERT address;

        Test.startTest();
            Database.executebatch( new BatchRepairAddresses(), 20 );
        Test.stopTest();
    }

}