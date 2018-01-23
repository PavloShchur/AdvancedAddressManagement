@isTest
private class AddressMappingWrapperTest {

    @isTest static void updateVerifiedFields() {
        UtilsTest.createTestDataForAccount( 1 );
        Address_Mapping__c addressMapping = AddressMappingServices.getAddressMappingRecord( UtilsTest.addressMappingsAccount[0].Id,
                                                                                            null,
                                                                                            AddressMappingWrapper.FIELDS_NEEDED_ADDRESS_WRAPPER );
        AddressMappingWrapper aw;

        Test.startTest();
            aw = new AddressMappingWrapper( addressMapping );
        Test.stopTest();

        System.assert( aw != null );
        System.assert( aw.hasContactsWithMappings == false );
        System.assert( aw.recordsOfSameType == 0 );
    }

    @isTest static void getFilteredAddressesForRelatedAddresses() {
        UtilsTest.createTestDataForAccount( 3 );
        Set<Id> addressMappingIds = new Map<Id, Address_Mapping__c>( UtilsTest.addressMappingsAccount ).keySet();
        String query = 'SELECT ' + String.join(
                                       new List<String>(
                                           Utils.getFieldsFromFieldSet(
                                               SObjectType.Address_Mapping__c.FieldSets.New_Address_Account_Addresses_Fields.getFields(),
                                               new List<Schema.SObjectField>{ Address_Mapping__c.Primary__c, Address_Mapping__c.Address_Type__c }
                                           )
                                       ), ', '
                                   ) + ' ';
        query += 'FROM Address_Mapping__c ';
        query += 'WHERE Id IN :addressMappingIds';
        List<Address_Mapping__c> addressMappingRecords = Database.query( query );

        List<AddressMappingWrapper> addressMappingWrappers = new List<AddressMappingWrapper>();
        for( Address_Mapping__c addressMappingRecord : addressMappingRecords ) {
            addressMappingRecord.Primary__c = true;
            addressMappingWrappers.add( new AddressMappingWrapper( addressMappingRecord ) );
        }

        List<AddressMappingWrapper> filteredAddressesForRelatedAddressesAddressType;
        List<AddressMappingWrapper> filteredAddressesForRelatedAddressesAddressLine;

        Test.startTest();
            filteredAddressesForRelatedAddressesAddressType = AddressMappingWrapper.getFilteredAddressesForRelatedAddresses( addressMappingWrappers,
                                                                                                                             UtilsTest.amAddressType,
                                                                                                                             NewAddressController.PRIMARY_OPTION );
            filteredAddressesForRelatedAddressesAddressLine = AddressMappingWrapper.getFilteredAddressesForRelatedAddresses( addressMappingWrappers,
                                                                                                                             UtilsTest.aAddressLine1,
                                                                                                                             NewAddressController.PRIMARY_OPTION );
        Test.stopTest();

        System.assert( filteredAddressesForRelatedAddressesAddressType != null );
        System.assert( filteredAddressesForRelatedAddressesAddressLine != null );
    }

    @isTest static void sort() {
        UtilsTest.amAddressType = AddressMappingServices.ADDRESS_TYPE_VISITING_ADDRESS;

        UtilsTest.createTestDataForAccount( 10 );
        UtilsTest.addressMappingsAccount[0].Address_Type__c = AddressMappingServices.ADDRESS_TYPE_VISITING_ADDRESS;
        UtilsTest.addressMappingsAccount[0].Primary__c = true;

        UtilsTest.addressMappingsAccount[1].Address_Type__c = AddressMappingServices.ADDRESS_TYPE_VISITING_ADDRESS;
        UtilsTest.addressMappingsAccount[1].Primary__c = false;

        UtilsTest.addressMappingsAccount[2].Address_Type__c = AddressMappingServices.ADDRESS_TYPE_OTHER_ADDRESS;
        UtilsTest.addressMappingsAccount[2].Primary__c = false;

        UtilsTest.addressMappingsAccount[3].Address_Type__c = AddressMappingServices.ADDRESS_TYPE_BILLING_ADDRESS;
        UtilsTest.addressMappingsAccount[3].Primary__c = true;

        UtilsTest.addressMappingsAccount[4].Address_Type__c = null;
        UtilsTest.addressMappingsAccount[4].Primary__c = true;

        UtilsTest.addressMappingsAccount[5].Address_Type__c = AddressMappingServices.ADDRESS_TYPE_OTHER_ADDRESS;
        UtilsTest.addressMappingsAccount[5].Primary__c = true;

        UtilsTest.addressMappingsAccount[6].Address_Type__c = null;
        UtilsTest.addressMappingsAccount[6].Primary__c = false;

        UtilsTest.addressMappingsAccount[7].Address_Type__c = AddressMappingServices.ADDRESS_TYPE_BILLING_ADDRESS;
        UtilsTest.addressMappingsAccount[7].Primary__c = false;

        UtilsTest.addressMappingsAccount[8].Address_Type__c = AddressMappingServices.ADDRESS_TYPE_OTHER_ADDRESS;
        UtilsTest.addressMappingsAccount[8].Primary__c = false;

        UtilsTest.addressMappingsAccount[9].Address_Type__c = AddressMappingServices.ADDRESS_TYPE_VISITING_ADDRESS;
        UtilsTest.addressMappingsAccount[9].Primary__c = true;

        List<AddressMappingWrapper> addressMappingWrappers = new List<AddressMappingWrapper>();
        for( Address_Mapping__c addressMappingRecord : UtilsTest.addressMappingsAccount ) {
            addressMappingWrappers.add( new AddressMappingWrapper( addressMappingRecord ) );
        }

        Test.startTest();
            addressMappingWrappers.sort();
        Test.stopTest();

        System.assert( addressMappingWrappers != null );
    }

    @isTest static void sortByAddressLine() {
        UtilsTest.aAddressLine1 = 'test3';
        UtilsTest.amAddressType = AddressMappingServices.ADDRESS_TYPE_VISITING_ADDRESS;

        UtilsTest.createTestDataForAccount( 1 );
        List<Address_Mapping__c> addressMappings = new List<Address_Mapping__c>();
        addressMappings.addAll( UtilsTest.addressMappingsAccount );

        UtilsTest.aAddressLine1 = 'test2';
        UtilsTest.createAddress();
        addressMappings.addAll( UtilsTest.createAddressMappings( 1 ) );

        UtilsTest.aAddressLine1 = 'test2';
        UtilsTest.createAddress();
        addressMappings.addAll( UtilsTest.createAddressMappings( 1 ) );

        UtilsTest.aAddressLine1 = null;
        UtilsTest.createAddress();
        addressMappings.addAll( UtilsTest.createAddressMappings( 1 ) );

        UtilsTest.aAddressLine1 = 'test1';
        UtilsTest.createAddress();
        addressMappings.addAll( UtilsTest.createAddressMappings( 1 ) );

        List<Address_Mapping__c> addressMappingsToSort = [ SELECT Primary__c, Address_Line_1__c, Address_Type__c
                                                           FROM Address_Mapping__c
                                                           WHERE Id IN : new Map<Id, Address_Mapping__c>( addressMappings ).keySet() ];

        List<AddressMappingWrapper> addressMappingWrappers = new List<AddressMappingWrapper>();
        for( Address_Mapping__c addressMappingRecord : addressMappingsToSort ) {
            addressMappingWrappers.add( new AddressMappingWrapper( addressMappingRecord ) );
        }

        Test.startTest();
            addressMappingWrappers.sort();
        Test.stopTest();

        System.assert( addressMappingWrappers != null );
    }

}