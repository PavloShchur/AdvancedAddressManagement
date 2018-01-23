@isTest
private class BatchRepairAddressMappingsTest {

    @isTest static void runJob() {
        Utils.aamSettings.Disable_Account_Move_Delete_Function__c = false;
        UPSERT Utils.aamSettings;

        Test.startTest();
            Id batchId = Database.executebatch( new BatchRepairAddressMappings(), 20 );
        Test.stopTest();

        System.assert( batchId != null );
    }

    @isTest static void runJobWithData() {
        Utils.aamSettings.Disable_Account_Move_Delete_Function__c = false;
        UPSERT Utils.aamSettings;

        Account account = new Account( Name = 'First Account' );
        INSERT account;

        Address__c address = new Address__c();
        address.Account__c = account.Id;
        INSERT address;

        Address_Mapping__c mapping = new Address_Mapping__c( Address__c = address.Id, Account__c = account.Id );
        INSERT mapping;

        Test.startTest();
            Database.executebatch( new BatchRepairAddressMappings(), 20 );
        Test.stopTest();
    }

    @isTest static void runJobWithData2() {
        Utils.aamSettings.Disable_Account_Move_Delete_Function__c = false;
        Utils.aamSettings.Enforce_Contact_Address_Deactivation__c = true;
        UPSERT Utils.aamSettings;

        Account account1top = new Account( Name = 'account1top' );
        Account account2top = new Account( Name = 'account2top' );
        INSERT new List<Account>{ account1top, account2top };

        Account account1bot = new Account( Name = 'account1bot', ParentId = account1top.Id );
        INSERT new List<Account>{ account1bot };

        Contact contact1top = new Contact( LastName = 'contact1top', AccountId = account1top.Id );
        Contact contact2top = new Contact( LastName = 'contact2top', AccountId = account2top.Id );
        Contact contact1bot = new Contact( LastName = 'contact1bot', AccountId = account1bot.Id );
        INSERT new List<Contact>{ contact1top, contact2top, contact1bot };

        Address__c address_account1top1 = new Address__c( Account__c = account1top.Id, City__c = 'Lviv' );
        Address__c address_account1top2 = new Address__c( Account__c = account1top.Id, City__c = 'Kyiv' );
        Address__c address_account2top1 = new Address__c( Account__c = account2top.Id, City__c = 'Odessa' );
        INSERT new List<Address__c>{ address_account1top1, address_account1top2, address_account2top1 };

        Address_Mapping__c contact1top_address1top1_bill = new Address_Mapping__c( Contact__c = contact1top.Id, Address__c = address_account1top1.Id, Active__c = true, Primary__c = true, Address_Type__c = 'Billing Address' );
        Address_Mapping__c contact1top_address1top2_ship = new Address_Mapping__c( Contact__c = contact1top.Id, Address__c = address_account1top2.Id, Active__c = true, Primary__c = true, Address_Type__c = 'Shipping Address' );
        Address_Mapping__c contact1bot_address1top2_bill = new Address_Mapping__c( Contact__c = contact1bot.Id, Address__c = address_account1top2.Id, Active__c = true, Primary__c = true, Address_Type__c = 'Billing Address' );
        Address_Mapping__c contact2top_address2top1_bill = new Address_Mapping__c( Contact__c = contact2top.Id, Address__c = address_account2top1.Id, Active__c = true, Primary__c = true, Address_Type__c = 'Billing Address' );
        Address_Mapping__c account1top_account1top2_bill = new Address_Mapping__c( Account__c = account1top.Id, Address__c = address_account1top1.Id, Active__c = true, Primary__c = true, Address_Type__c = 'Billing Address' );
        Address_Mapping__c account1bot_account1top2_bill = new Address_Mapping__c( Account__c = account1bot.Id, Address__c = address_account1top2.Id, Active__c = true, Primary__c = true, Address_Type__c = 'Billing Address' );
        INSERT new List<Address_Mapping__c>{ contact1top_address1top1_bill, contact1top_address1top2_ship, contact1bot_address1top2_bill, contact2top_address2top1_bill, account1top_account1top2_bill, account1bot_account1top2_bill };

        UPDATE new Account( Id = account1bot.Id, ParentId = account2top.Id );

        Test.startTest();
            Id jobId = Database.executebatch( new BatchRepairAddresses() );
        Test.stopTest();

        List<AsyncApexJob> jobs = [ SELECT Status, ExtendedStatus FROM AsyncApexJob WHERE Id = :jobId ];
        System.assert( jobs.size() == 1 );
        System.assertEquals( 'Completed', jobs[0].Status );
        System.assertEquals( null, jobs[0].ExtendedStatus );
    }

}