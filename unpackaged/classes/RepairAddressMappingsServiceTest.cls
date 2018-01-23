@isTest
private class RepairAddressMappingsServiceTest {

    @isTest static void reparentBrokenAddressMappingss() {
        Account top1Account = new Account( Name = 'Top1' );
        Account top2Account = new Account( Name = 'Top2' );
        Account top3AccountToDelete = new Account( Name = 'DelAccount' );
        INSERT new List<Account>{ top1Account, top2Account, top3AccountToDelete };
        Account bot1AccountToTop2Account = new Account( Name = 'Bot1To2', ParentId = top1Account.Id );
        INSERT new List<Account>{ bot1AccountToTop2Account };

        Address__c addressTop1Single = new Address__c( City__c = 'Kyiv', Account__c = top1Account.Id );
        Address__c addressTop1Dupe1 = new Address__c( City__c = 'Lviv', Account__c = top1Account.Id );
        Address__c addressTop2Dupe1 = new Address__c( City__c = 'Lviv', Account__c = top2Account.Id );
        Address__c addressTop3Single = new Address__c( City__c = 'Wroclaw', Account__c = top3AccountToDelete.Id );
        List<Address__c> addresses = new List<Address__c>{ addressTop1Single, addressTop1Dupe1, addressTop2Dupe1, addresstop3Single };
        INSERT addresses;
        Set<Id> addressIds = new Map<Id, Address__c>( addresses ).keySet();

        Address_Mapping__c bot1AccountToTop2Account_addressTop1Dupe1  = new Address_Mapping__c( Account__c = bot1AccountToTop2Account.Id, Address__c = addressTop1Dupe1.Id,  Address_Type__c = AddressMappingServices.ADDRESS_TYPE_BILLING_ADDRESS );
        Address_Mapping__c bot1AccountToTop2Account_addressTop1Single = new Address_Mapping__c( Account__c = bot1AccountToTop2Account.Id, Address__c = addressTop1Single.Id, Address_Type__c = AddressMappingServices.ADDRESS_TYPE_SHIPPING_ADDRESS );
        Address_Mapping__c top2Account_addressTop2Dupe1  = new Address_Mapping__c( Account__c = top2Account.Id, Address__c = addressTop2Dupe1.Id,  Address_Type__c = AddressMappingServices.ADDRESS_TYPE_BILLING_ADDRESS );
        Address_Mapping__c top1Account_addressTop1Dupe1  = new Address_Mapping__c( Account__c = top1Account.Id, Address__c = addressTop1Dupe1.Id,  Address_Type__c = AddressMappingServices.ADDRESS_TYPE_BILLING_ADDRESS );
        Address_Mapping__c orphaned_addressTop1Dupe1     = new Address_Mapping__c( Account__c = top3AccountToDelete.Id, Address__c = addressTop1Dupe1.Id,  Address_Type__c = AddressMappingServices.ADDRESS_TYPE_BILLING_ADDRESS );
        List<Address_Mapping__c> mappings = new List<Address_Mapping__c>{ bot1AccountToTop2Account_addressTop1Dupe1, bot1AccountToTop2Account_addressTop1Single, top2Account_addressTop2Dupe1, top1Account_addressTop1Dupe1, orphaned_addressTop1Dupe1 };
        INSERT mappings;

        DELETE top3AccountToDelete;
        bot1AccountToTop2Account.ParentId = top2Account.Id;
        UPDATE new List<Account>{ bot1AccountToTop2Account };

        Test.startTest();
            RepairAddressMappingsService service = new RepairAddressMappingsService( Database.query( RepairAddressMappingsService.BATCH_ADDRESS_QUERY ) );
            service.start();
        Test.stopTest();

        List<Address__c> addressesFromDb = [ SELECT City__c, Account__c FROM Address__c ];
        System.assertEquals( addresses.size() + 1, addressesFromDb.size() );
        Set<String> cities = new Set<String>();
        for( Address__c address : addressesFromDb ) {
            if( address.Id != addresstop3Single.Id ) {
                System.assert( address.Account__c != null );
                cities.add( address.City__c );
            } else {
                System.assert( address.Account__c == null );
                System.assertEquals( addresstop3Single.City__c, address.City__c );
            }
        }
        System.assertEquals( 2, cities.size() );
        Set<Id> addressesFromDbIds = new Map<Id, Address__c>( addressesFromDb ).keySet();
        Set<Id> newAddressIds = addressesFromDbIds.clone();
        System.assert( addressesFromDbIds.contains( addressTop1Single.Id ) );
        System.assert( addressesFromDbIds.contains( addressTop1Dupe1.Id ) );
        System.assert( addressesFromDbIds.contains( addressTop2Dupe1.Id ) );
        System.assert( addressesFromDbIds.contains( addressTop3Single.Id ) );
        newAddressIds.removeAll( new Map<Id, Address__c>( addresses ).keySet() );
        System.assertEquals( 1, newAddressIds.size() ); //new address

        Address__c newAddress = new Map<Id, Address__c>( addressesFromDb ).get( new List<Id>( newAddressIds )[0] );

        System.assertEquals( top2Account.Id, newAddress.Account__c );
        System.assertEquals( addressTop1Single.City__c, newAddress.City__c );

        List<Address_Mapping__c> mappingsFromDb = [ SELECT Account__c, Address__c FROM Address_Mapping__c ];
        System.assertEquals( mappings.size() - 1, mappingsFromDb.size() );
        Set<Id> mappingsFromDbIds = new Map<Id, Address_Mapping__c>( mappingsFromDb ).keySet();
        System.assert( mappingsFromDbIds.contains( bot1AccountToTop2Account_addressTop1Dupe1.Id ) );
        System.assert( mappingsFromDbIds.contains( bot1AccountToTop2Account_addressTop1Single.Id ) );
        System.assert( mappingsFromDbIds.contains( top2Account_addressTop2Dupe1.Id ) );
        System.assert( mappingsFromDbIds.contains( top1Account_addressTop1Dupe1.Id ) );
        System.assert( !mappingsFromDbIds.contains( orphaned_addressTop1Dupe1.Id ) );

        Set<Id> mappingAddressIds = new Set<Id>();
        for( Address_Mapping__c mapping : mappingsFromDb ) {
            mappingAddressIds.add( mapping.Address__c );
        }
        System.assertEquals( addresses.size() - 1, mappingAddressIds.size() );
        System.assert( mappingAddressIds.contains( addressTop1Dupe1.Id ) );
        System.assert( mappingAddressIds.contains( addressTop2Dupe1.Id ) );
        System.assert( mappingAddressIds.contains( newAddress.Id ) );
    }
}