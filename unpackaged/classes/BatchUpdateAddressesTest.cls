@isTest
private class BatchUpdateAddressesTest {

    @isTest static void runJob() {
        Test.startTest();
            Id batchId = Database.executebatch( new BatchUpdateAddresses(), 20 );
        Test.stopTest();

        System.assert( batchId != null );
    }

    @isTest static void runJobWithData() {
        Account account = new Account( Name = 'First Account' );
        INSERT account;

        Address__c address = new Address__c();
        address.Account__c = account.Id;
        INSERT address;

        Test.startTest();
            Id batchId = Database.executebatch( new BatchUpdateAddresses(), 20 );
        Test.stopTest();

        System.assert( batchId != null );
    }

}