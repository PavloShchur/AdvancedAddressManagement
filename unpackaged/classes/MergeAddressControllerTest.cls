@isTest
private class MergeAddressControllerTest {

    public static Account account;
    public static Address__c address1;
    public static Address__c address2;
    public static List<Address__c> allAddresses { get { return new List<Address__c>{ address1, address2 }; } }
    public static Address_Mapping__c addressMapping1;
    public static Address_Mapping__c addressMapping2;
    public static MergeAddressController controller;

    public static void setup() {
        Utils.updateCustomSettings( true );
        CountryServices.recreateCountryMappings();

        account = new Account( Name = 'test' );
        INSERT account;

        address1 = new Address__c( Account__c = account.Id,
                                   Address_Line_1__c = '1 London Str. long long long long long long long long long long long long long long long long long',
                                   City__c = 'London',
                                   Postcode__c = '123',
                                   Country__c = 'GB' );
        address2 = new Address__c( Account__c = account.Id,
                                   Address_Line_1__c = '1 New York Str.',
                                   City__c = 'New York',
                                   Postcode__c = '123',
                                   Country__c = 'US' );
        INSERT new List<Address__c>{ address1, address2 };

        addressMapping1 = new Address_Mapping__c( Address__c = address1.Id,
                                                  Account__c = account.Id,
                                                  Active__c = true,
                                                  Primary__c = true,
                                                  Address_Type__c = 'Billing Address' );
        addressMapping2 = new Address_Mapping__c( Address__c = address2.Id,
                                                  Account__c = account.Id,
                                                  Active__c = true,
                                                  Primary__c = true,
                                                  Address_Type__c = 'Shipping Address' );
        INSERT new List<Address_Mapping__c>{ addressMapping1, addressMapping2 };

        controller = new MergeAddressController();
    }

    @isTest static void init() {
        setup();

        Test.startTest();
            Aam_Settings__c settings = controller.settings;
            settings = controller.getSettings();
            System.assert( settings != null );

            controller.cancel();

            List<MergeAddressController.AccountSearchResult> accountSearchResults = MergeAddressController.findAccounts( account.Name );
            System.assert( accountSearchResults != null );
            System.assert( accountSearchResults.size() == 1 );

            Id accountId = accountSearchResults[0].Id;
            System.assertEquals( account.Id, accountId );

            controller.goToStep2();
            controller.accountId = accountId;
            controller.goToStep2();

            controller.filterTextRelatedAddresses = '123';
            controller.filterRelatedAddresses();

            List<Address__c> addresses = controller.filteredRelatedAddresses;
            addresses = controller.getFilteredRelatedAddresses();
            System.assert( addresses != null );
            System.assert( addresses.size() == 2 );
            for( Address__c address : allAddresses ) {
                System.assert( new Map<Id, Address__c>( allAddresses ).containsKey( address.Id ) );
            }

            controller.goToStep3();
            controller.chosenAddresses = String.join( new List<String>{ addresses[0].Id, addresses[1].Id }, ',' );
            controller.goToStep3();

            MergeAddressController.AddressesWrapper chosenRelatedAddresses = controller.chosenRelatedAddresses;
            System.assert( chosenRelatedAddresses != null );

            Map<Id, String> recordIdToAddress = chosenRelatedAddresses.recordIdToAddress;
            recordIdToAddress = chosenRelatedAddresses.getRecordIdToAddress();
            System.assert( recordIdToAddress != null );
            System.assert( recordIdToAddress.size() == 2 );

            Map<Id, String> recordIdToAddressConcat = chosenRelatedAddresses.recordIdToAddressConcat;
            recordIdToAddressConcat = chosenRelatedAddresses.getRecordIdToAddressConcat();
            System.assert( recordIdToAddressConcat != null );
            System.assert( recordIdToAddressConcat.size() == 2 );

            System.assert( chosenRelatedAddresses.records != null );
            System.assert( chosenRelatedAddresses.records.size() == 2 );

            System.assert( chosenRelatedAddresses.fields != null );
            for( MergeAddressController.FieldWrapper field : chosenRelatedAddresses.fields ) {
                System.assert( field.selectors != null );
                System.assert( field.selectors.size() == 2 );
                System.assert( field.name != null );
                System.assert( field.editable != null );
                System.assert( field.label != null );
                System.assert( field.isCustom != null );
                System.assert( field.isDifferent != null );
                if( field.name == MergeAddressController.MASTER_RECORD_LABEL ) {
                    System.assert( field.selectors[0].selected == true );
                    System.assert( field.selectors[1].selected == false );
                }
            }

            DELETE allAddresses;
            controller.mergeAddresses();
            System.assert( ApexPages.hasMessages() );
        Test.stopTest();
    }

    @isTest static void mergeAddresses() {
        setup();

        Test.startTest();
            List<MergeAddressController.AccountSearchResult> accountSearchResults = MergeAddressController.findAccounts( account.Name );
            Id accountId = accountSearchResults[0].Id;
            controller.accountId = accountId;
            controller.goToStep2();

            List<Address__c> addresses = controller.getFilteredRelatedAddresses();
            controller.chosenAddresses = String.join( new List<String>{ addresses[0].Id, addresses[1].Id }, ',' );
            controller.goToStep3();

            Id addressIdRemaining;
            MergeAddressController.AddressesWrapper chosenRelatedAddresses = controller.chosenRelatedAddresses;
            for( MergeAddressController.FieldWrapper field : chosenRelatedAddresses.fields ) {
                if( field.name == MergeAddressController.MASTER_RECORD_LABEL ) {
                    field.selectors[0].selected = false;
                    field.selectors[1].selected = true;
                    addressIdRemaining = field.selectors[1].recordId;
                }
            }
            System.assert( addressIdRemaining != null );

            controller.mergeAddresses();
        Test.stopTest();

        List<Address__c> addressesRemaining = [ SELECT Id, Address_Line_1__c, City__c, Country__c, Postcode__c, Account__c
                                                FROM Address__c
                                                WHERE Id IN :allAddresses ];
        System.assert( !addressesRemaining.isEmpty() );
        System.assert( addressesRemaining.size() == 1 );

        Address__c addressRemaining = addressesRemaining[0];
        System.assert( addressRemaining.Id == addressIdRemaining );
        Address__c addressWithValues;
        for( Address__c address : allAddresses ) {
            if( address.Id != addressRemaining.Id ) {
                addressWithValues = address;
                break;
            }
        }
        System.assert( addressWithValues != null );
        //System.assert( addressRemaining.Address_Line_1__c == addressWithValues.Address_Line_1__c );
        //System.assert( addressRemaining.City__c == addressWithValues.City__c );
        //System.assert( addressRemaining.Country__c == addressWithValues.Country__c );
        //System.assert( addressRemaining.Postcode__c == addressWithValues.Postcode__c );
        //System.assert( addressRemaining.Account__c == account.Id );

        account = [ SELECT BillingStreet, BillingCity, BillingCountry, BillingPostalCode,
                           ShippingStreet, ShippingCity, ShippingCountry, ShippingPostalCode
                    FROM Account
                    WHERE Id = :account.Id ];

        List<Address_Mapping__c> addressMappings = [ SELECT Address__c, Address_Type__c, Primary__c, Active__c,
                                                            Address_Line_1__c, City__c, Country_Name__c, Postcode__c
                                                     FROM Address_Mapping__c
                                                     WHERE Address__c = :addressRemaining.Id ];
        System.assert( !addressMappings.isEmpty() );
        System.assert( addressMappings.size() == 2 );
        for( Address_Mapping__c addressMapping : addressMappings ) {
            System.assert( new Set<Id>{ addressMapping1.Id, addressMapping2.Id }.contains( addressMapping.Id ) );
            if( !addressMapping.Primary__c || !addressMapping.Active__c ) continue;
            if( addressMapping.Address_Type__c == 'Billing Address' ) {
                System.assert( account.BillingStreet == addressMapping.Address_Line_1__c );
                System.assert( account.BillingCity == addressMapping.City__c );
                System.assert( account.BillingCountry == addressMapping.Country_Name__c );
                System.assert( account.BillingPostalCode == addressMapping.Postcode__c );
            } else if( addressMapping.Address_Type__c == 'Shipping Address' ) {
                System.assert( account.ShippingStreet == addressMapping.Address_Line_1__c );
                System.assert( account.ShippingCity == addressMapping.City__c );
                System.assert( account.ShippingCountry == addressMapping.Country_Name__c );
                System.assert( account.ShippingPostalCode == addressMapping.Postcode__c );
            }
        }

    }

}