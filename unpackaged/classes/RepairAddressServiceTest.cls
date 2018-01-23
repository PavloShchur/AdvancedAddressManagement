@isTest
private class RepairAddressServiceTest {

	@isTest static void reparentBrokenAddresses() {
		Account topAccount = new Account( Name = 'Top' );
        Account midAccount = new Account( Name = 'Mid' );
        Account botAccount = new Account( Name = 'Bot' );
        INSERT new List<Account>{ topAccount, midAccount, botAccount };

        Address__c addressTopSingle = new Address__c( City__c = 'Lviv', Account__c = topAccount.Id );
        Address__c addressMidSingle = new Address__c( City__c = 'Kyiv', Account__c = midAccount.Id );
        Address__c addressTopDupe1 = new Address__c( City__c = 'Wroclaw', Account__c = topAccount.Id );
        Address__c addressMidDupe1 = new Address__c( City__c = 'Wroclaw', Account__c = midAccount.Id );
        Address__c addressMidDupe2 = new Address__c( City__c = 'Odessa', Account__c = midAccount.Id );
        Address__c addressBotDupe2 = new Address__c( City__c = 'Odessa', Account__c = botAccount.Id );
        INSERT new List<Address__c>{ addressTopSingle, addressMidSingle, addressTopDupe1, addressMidDupe1, addressMidDupe2, addressBotDupe2 };

        Address_Mapping__c addressTopSingleMapping = new Address_Mapping__c( Account__c = topAccount.Id, Address__c = addressTopSingle.Id );
        Address_Mapping__c addressMidSingleMapping = new Address_Mapping__c( Account__c = midAccount.Id, Address__c = addressMidSingle.Id );
        Address_Mapping__c addressTopDupe1Mapping = new Address_Mapping__c( Account__c = topAccount.Id, Address__c = addressTopDupe1.Id );
        Address_Mapping__c addressMidDupe1Mapping = new Address_Mapping__c( Account__c = midAccount.Id, Address__c = addressMidDupe1.Id );
        Address_Mapping__c addressMidDupe2Mapping = new Address_Mapping__c( Account__c = midAccount.Id, Address__c = addressMidDupe2.Id );
        Address_Mapping__c addressBotDupe2Mapping = new Address_Mapping__c( Account__c = botAccount.Id, Address__c = addressBotDupe2.Id );
        INSERT new List<Address_Mapping__c>{ addressTopSingleMapping, addressMidSingleMapping, addressTopDupe1Mapping, addressMidDupe1Mapping, addressMidDupe2Mapping, addressBotDupe2Mapping };

        midAccount.ParentId = topAccount.Id;
        botAccount.ParentId = midAccount.Id;
        UPDATE new List<Account>{ midAccount, botAccount };

        Test.startTest();
            RepairAddressService service = new RepairAddressService( Database.query( RepairAddressService.BATCH_ADDRESS_QUERY ) );
            service.start();
        Test.stopTest();

        List<Address__c> addressesFromDb = [ SELECT City__c, Account__c FROM Address__c ];
        System.assertEquals( 4, addressesFromDb.size() );
        Set<String> cities = new Set<String>();
        for( Address__c address : addressesFromDb ) {
            System.assert( address.Account__c != null );
            System.assertEquals( topAccount.Id, address.Account__c );
            cities.add( address.City__c );
        }
        System.assertEquals( 4, cities.size() );
        Set<Id> addressesFromDbIds = new Map<Id, Address__c>( addressesFromDb ).keySet();
        System.assert( addressesFromDbIds.contains( addressTopSingle.Id ) );
        System.assert( addressesFromDbIds.contains( addressMidSingle.Id ) );
        System.assert( addressesFromDbIds.contains( addressTopDupe1.Id ) || addressesFromDbIds.contains( addressMidDupe1.Id ) );
        System.assert( !addressesFromDbIds.contains( addressTopDupe1.Id ) || !addressesFromDbIds.contains( addressMidDupe1.Id ) );
        System.assert( addressesFromDbIds.contains( addressMidDupe2.Id ) || addressesFromDbIds.contains( addressBotDupe2.Id ) );
        System.assert( !addressesFromDbIds.contains( addressMidDupe2.Id ) || !addressesFromDbIds.contains( addressBotDupe2.Id ) );

        List<Address_Mapping__c> amsInDb = [ SELECT Account__c, Address__c FROM Address_Mapping__c ];
        System.assertEquals( 6, amsInDb.size() );
        Set<Id> addressIds = new Set<Id>();
        for( Address_Mapping__c am : amsInDb ) {
            addressIds.add( am.Address__c );
        }
        System.assertEquals( 4, addressIds.size() );
	}

}