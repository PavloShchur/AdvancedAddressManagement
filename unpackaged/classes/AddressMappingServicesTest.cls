@isTest
private class AddressMappingServicesTest {

	private static final Integer NUMBER_OF_RECORDS = 3;

    @isTest static void updateRemovedFields() {
        UtilsTest.createTestDataForAccount( 1 );

        Test.startTest();
            UPDATE new Address_Mapping__c( Id = UtilsTest.addressMappingsAccount[0].Id,
                                           Active__c = false );
        Test.stopTest();

        List<Address_Mapping__c> addressMappings = [ SELECT Removed_Date__c, Removed_By__c
                                                     FROM Address_Mapping__c ];
        System.assert( !addressMappings.isEmpty() );
        for( Address_Mapping__c addressMapping : addressMappings ) {
            if( addressMapping.Id == UtilsTest.addressMappingsAccount[0].Id ) {
                System.assert( addressMapping.Removed_Date__c != null );
                System.assert( addressMapping.Removed_Date__c == Date.today() );
                System.assert( addressMapping.Removed_By__c != null );
                System.assert( addressMapping.Removed_By__c == UserInfo.getUserId() );
            }
        }
    }

    @isTest static void getAddress() {
        UtilsTest.createTestDataForAccount( 1 );
        Address_Mapping__c addressMapping = AddressMappingServices.getAddressMappingRecord( UtilsTest.addressMappingsAccount[0].Id,
                                                                                            null,
                                                                                            AddressMappingWrapper.FIELDS_NEEDED_ADDRESS_WRAPPER );
        String addressLines;

        Test.startTest();
            addressLines = AddressMappingServices.getAddress( addressMapping );
        Test.stopTest();

        System.assert( !String.isEmpty( addressLines ) );
    }

    @isTest static void getAddressMappingRecord() {
        UtilsTest.createTestDataForAccount( 1 );
        Address_Mapping__c addressMapping;

        Test.startTest();
            addressMapping = AddressMappingServices.getAddressMappingRecord( UtilsTest.addressMappingsAccount[0].Id,
                                                                             null,
                                                                             AddressMappingWrapper.FIELDS_NEEDED_ADDRESS_WRAPPER );
        Test.stopTest();

        System.assert( addressMapping != null );
        System.assert( addressMapping.Id != null );
    }

    @isTest static void getAddressMappingRecords() {
        UtilsTest.createTestDataForContact( 1, 1 );
        List<Address_Mapping__c> addressMappings;

        Test.startTest();
            addressMappings = AddressMappingServices.getAddressMappingRecords( UtilsTest.address,
                                                                               UtilsTest.addressMappingsContact[0],
                                                                               null,
                                                                               AddressMappingWrapper.FIELDS_NEEDED_ADDRESS_WRAPPER );
        Test.stopTest();

        System.assert( addressMappings != null );
        System.assert( !addressMappings.isEmpty() );
        for( Address_Mapping__c addressMapping : addressMappings ) {
            System.assert( addressMapping.Id != null );
        }
    }

    @isTest static void deactivateAddressMappings() {
        UtilsTest.createTestDataForAccount( 1 );

        Test.startTest();
            AddressMappingServices.deactivateAddressMappings( new Set<Id>{ UtilsTest.addressMappingsAccount[0].Id } );
        Test.stopTest();

        List<Address_Mapping__c> addressMappings = [ SELECT Active__c
                                                     FROM Address_Mapping__c
                                                     WHERE Id = : UtilsTest.addressMappingsAccount[0].Id ];
        System.assert( !addressMappings.isEmpty() );
        for( Address_Mapping__c addressMapping : addressMappings ) {
            System.assert( addressMapping.Active__c == false );
        }
    }

    @isTest static void resetPrimaryForNewRecords() {
        UtilsTest.amPrimary = true;
        //UtilsTest.createTestDataForAccount( 2 );
        Account account = new Account( Name = 'test' );
        INSERT account;

        Address__c address = new Address__c(
            Account__c = account.Id,
            Address_Line_1__c = UtilsTest.aAddressLine1,
            City__c = UtilsTest.aCity,
            Country__c = UtilsTest.aCountry
        );
        INSERT address;

        Integer numberToCreate = 10;
        List<Address_Mapping__c> addressMappings = new List<Address_Mapping__c>();
        for( Integer i = 0; i < numberToCreate; i++ ) {
            addressMappings.add(
                new Address_Mapping__c(
                    Address__c = address.Id,
                    Account__c = account.Id,
                    Address_Type__c = UtilsTest.amAddressType,
                    Active__c = UtilsTest.amActive,
                    Primary__c = UtilsTest.amPrimary
                )
            );
        }
        Test.startTest();
            INSERT addressMappings;
            //UtilsTest.createTestDataForAccount( 2 );
        Test.stopTest();

        List<Address_Mapping__c> addressMappingsDb = [ SELECT Primary__c
                                                       FROM Address_Mapping__c
                                                       WHERE Id IN :addressMappings ];
        System.assertEquals( numberToCreate, addressMappingsDb.size() );

        Integer numberOfPrimaryrecords = 0;
        for( Address_Mapping__c addressMapping : addressMappingsDb ) {
            numberOfPrimaryrecords += addressMapping.Primary__c ? 1 : 0;
        }
        System.assertEquals( 1, numberOfPrimaryrecords );
    }

    @isTest static void resetPrimaryForOldRecords() {
        UtilsTest.amPrimary = true;
        //UtilsTest.createTestDataForAccount( 2 );
        Account account = new Account( Name = 'test' );
        INSERT account;

        Address__c address = new Address__c(
            Account__c = account.Id,
            Address_Line_1__c = UtilsTest.aAddressLine1,
            City__c = UtilsTest.aCity,
            Country__c = UtilsTest.aCountry
        );
        INSERT address;

        Integer numberToCreate = 2;
        List<Address_Mapping__c> addressMappings = new List<Address_Mapping__c>();
        for( Integer i = 0; i < numberToCreate; i++ ) {
            addressMappings.add(
                new Address_Mapping__c(
                    Address__c = address.Id,
                    Account__c = account.Id,
                    Address_Type__c = UtilsTest.amAddressType,
                    Active__c = UtilsTest.amActive,
                    Primary__c = UtilsTest.amPrimary
                )
            );
        }
        INSERT addressMappings;

        List<Address_Mapping__c> addressMappingsUpd = [ SELECT Primary__c
                                                        FROM Address_Mapping__c
                                                        WHERE Id IN :addressMappings ];
        Id primaryAddressId;
        for( Address_Mapping__c addressMapping : addressMappingsUpd ) {
            if( !addressMapping.Primary__c ) {
                addressMapping.Primary__c = true;
                primaryAddressId = addressMapping.Id;
                break;
            }
        }

        Test.startTest();
            UPDATE addressMappingsUpd;
        Test.stopTest();

        List<Address_Mapping__c> addressMappingsDb = [ SELECT Primary__c
                                                       FROM Address_Mapping__c
                                                       WHERE Id IN :addressMappings ];
        System.assertEquals( numberToCreate, addressMappingsDb.size() );

        Integer numberOfPrimaryrecords = 0;
        for( Address_Mapping__c addressMapping : addressMappingsDb ) {
            numberOfPrimaryrecords += addressMapping.Primary__c ? 1 : 0;
            if( addressMapping.Id == primaryAddressId ) {
                System.assertEquals( true, addressMapping.Primary__c );
            } else {
                System.assertEquals( false, addressMapping.Primary__c );
            }
        }
        System.assertEquals( 1, numberOfPrimaryrecords );
    }

    @isTest static void standardAddressPopulation() {
        CountryServices.recreateCountryMappings();
        Utils.updateCustomSettings( true );

        //create new billing address (used in mappings) = populate standard billing address
        UtilsTest.amAddressType = AddressMappingServices.ADDRESS_TYPE_BILLING_ADDRESS;
        UtilsTest.amPrimary = true;
        UtilsTest.amActive = true;
        UtilsTest.createTestDataForAccount( 1 );

        Account acc = [ SELECT BillingStreet, BillingCity, BillingCountry, Billing_Country_AAM__c, Billing_Country_AAM__r.Iso_Code__c, Billing_Country_AAM__r.Country_Name__c,
                               ShippingStreet, ShippingCity, ShippingCountry, Shipping_Country_AAM__c, Shipping_Country_AAM__r.Iso_Code__c, Shipping_Country_AAM__r.Country_Name__c
                        FROM Account
                        WHERE Id =: UtilsTest.account.Id ];

        System.assert( acc.BillingStreet != null );
        System.assert( acc.BillingStreet.contains( UtilsTest.aAddressLine1 ) );
        System.assert( acc.BillingCity != null );
        System.assert( acc.BillingCity == UtilsTest.aCity );
        System.assert( acc.Billing_Country_AAM__c != null );
        System.assert( acc.Billing_Country_AAM__r.Iso_Code__c == UtilsTest.aCountry );
        System.assert( acc.BillingCountry != null );
        System.assert( acc.BillingCountry == acc.Billing_Country_AAM__r.Country_Name__c );
        System.assert( acc.ShippingStreet == null );
        System.assert( acc.ShippingCity == null );
        System.assert( acc.ShippingCountry == null );
        System.assert( acc.Shipping_Country_AAM__c == null );

        //update mapping's primary status to false
        UPDATE new Address_Mapping__c( Id = UtilsTest.addressMappingsAccount[0].Id, Primary__c = false );

        acc = [ SELECT BillingStreet, BillingCity, BillingCountry, Billing_Country_AAM__c, Billing_Country_AAM__r.Iso_Code__c, Billing_Country_AAM__r.Country_Name__c,
                       ShippingStreet, ShippingCity, ShippingCountry, Shipping_Country_AAM__c, Shipping_Country_AAM__r.Iso_Code__c, Shipping_Country_AAM__r.Country_Name__c
                FROM Account
                WHERE Id =: UtilsTest.account.Id ];

        //the system sets primary = true for this address mapping automatically
        System.assert( acc.BillingStreet != null );
        System.assert( acc.BillingStreet.contains( UtilsTest.aAddressLine1 ) );
        System.assert( acc.BillingCity != null );
        System.assert( acc.BillingCity == UtilsTest.aCity );
        System.assert( acc.Billing_Country_AAM__c != null );
        System.assert( acc.Billing_Country_AAM__r.Iso_Code__c == UtilsTest.aCountry );
        System.assert( acc.BillingCountry != null );
        System.assert( acc.BillingCountry == acc.Billing_Country_AAM__r.Country_Name__c );
        System.assert( acc.ShippingStreet == null );
        System.assert( acc.ShippingCity == null );
        System.assert( acc.ShippingCountry == null );
        System.assert( acc.Shipping_Country_AAM__c == null );

        /*System.assert( acc.BillingStreet == null );
        System.assert( acc.BillingCity == null );
        System.assert( acc.Billing_Country_AAM__c == null );
        System.assert( acc.BillingCountry == null );
        System.assert( acc.ShippingStreet == null );
        System.assert( acc.ShippingCity == null );
        System.assert( acc.ShippingCountry == null );
        System.assert( acc.Shipping_Country_AAM__c == null );*/

        Test.startTest();
            //update mapping's primary status to true
            UPDATE new Address_Mapping__c( Id = UtilsTest.addressMappingsAccount[0].Id, Primary__c = true );

            acc = [ SELECT BillingStreet, BillingCity, BillingCountry, Billing_Country_AAM__c, Billing_Country_AAM__r.Iso_Code__c, Billing_Country_AAM__r.Country_Name__c,
                           ShippingStreet, ShippingCity, ShippingCountry, Shipping_Country_AAM__c, Shipping_Country_AAM__r.Iso_Code__c, Shipping_Country_AAM__r.Country_Name__c
                    FROM Account
                    WHERE Id =: UtilsTest.account.Id ];

            System.assert( acc.BillingStreet != null );
            System.assert( acc.BillingStreet.contains( UtilsTest.aAddressLine1 ) );
            System.assert( acc.BillingCity != null );
            System.assert( acc.BillingCity == UtilsTest.aCity );
            System.assert( acc.Billing_Country_AAM__c != null );
            System.assert( acc.Billing_Country_AAM__r.Iso_Code__c == UtilsTest.aCountry );
            System.assert( acc.BillingCountry != null );
            System.assert( acc.BillingCountry == acc.Billing_Country_AAM__r.Country_Name__c );
            System.assert( acc.ShippingStreet == null );
            System.assert( acc.ShippingCity == null );
            System.assert( acc.ShippingCountry == null );
            System.assert( acc.Shipping_Country_AAM__c == null );

            //update mapping's active status to false
            UPDATE new Address_Mapping__c( Id = UtilsTest.addressMappingsAccount[0].Id, Active__c = false );

            acc = [ SELECT BillingStreet, BillingCity, BillingCountry, Billing_Country_AAM__c, Billing_Country_AAM__r.Iso_Code__c, Billing_Country_AAM__r.Country_Name__c,
                           ShippingStreet, ShippingCity, ShippingCountry, Shipping_Country_AAM__c, Shipping_Country_AAM__r.Iso_Code__c, Shipping_Country_AAM__r.Country_Name__c
                    FROM Account
                    WHERE Id =: UtilsTest.account.Id ];

            System.assert( acc.BillingStreet == null );
            System.assert( acc.BillingCity == null );
            System.assert( acc.Billing_Country_AAM__c == null );
            System.assert( acc.BillingCountry == null );
            System.assert( acc.ShippingStreet == null );
            System.assert( acc.ShippingCity == null );
            System.assert( acc.ShippingCountry == null );
            System.assert( acc.Shipping_Country_AAM__c == null );
        Test.stopTest();
    }

    @isTest static void standardAddressPopulationMappingChanged() {
        CountryServices.recreateCountryMappings();
        Utils.updateCustomSettings( true );

        //create new billing address (used in mappings) = populate standard billing address
        UtilsTest.amAddressType = AddressMappingServices.ADDRESS_TYPE_BILLING_ADDRESS;
        UtilsTest.amPrimary = true;
        UtilsTest.amActive = true;
        UtilsTest.createTestDataForAccount( 1 );
        Id billingAddressMappingId = UtilsTest.addressMappingsAccount[0].Id;

        Account acc = [ SELECT BillingStreet, BillingCity, BillingCountry, Billing_Country_AAM__c, Billing_Country_AAM__r.Iso_Code__c, Billing_Country_AAM__r.Country_Name__c,
                               ShippingStreet, ShippingCity, ShippingCountry, Shipping_Country_AAM__c, Shipping_Country_AAM__r.Iso_Code__c, Shipping_Country_AAM__r.Country_Name__c
                        FROM Account
                        WHERE Id =: UtilsTest.account.Id ];

        String address1 = UtilsTest.aAddressLine1;
        String country1 = UtilsTest.aCountry;
        System.assert( acc.BillingStreet != null );
        System.assert( acc.BillingStreet.contains( address1 ) );
        System.assert( acc.BillingCity != null );
        System.assert( acc.BillingCity == UtilsTest.aCity );
        System.assert( acc.Billing_Country_AAM__c != null );
        System.assert( acc.Billing_Country_AAM__r.Iso_Code__c == country1 );
        System.assert( acc.BillingCountry != null );
        System.assert( acc.BillingCountry == acc.Billing_Country_AAM__r.Country_Name__c );
        System.assert( acc.ShippingStreet == null );
        System.assert( acc.ShippingCity == null );
        System.assert( acc.ShippingCountry == null );
        System.assert( acc.Shipping_Country_AAM__c == null );

        //create new visiting address (not used in mappings) = does nothing
        UtilsTest.amAddressType = AddressMappingServices.ADDRESS_TYPE_VISITING_ADDRESS;
        UtilsTest.aAddressLine1 += UtilsTest.aAddressLine1;
        UtilsTest.aCountry = 'MX';
        UtilsTest.createTestDataForAccount( 1 );
        Id visitingAddressMappingId = UtilsTest.addressMappingsAccount[0].Id;

        acc = [ SELECT BillingStreet, BillingCity, BillingCountry, Billing_Country_AAM__c, Billing_Country_AAM__r.Iso_Code__c, Billing_Country_AAM__r.Country_Name__c,
                       ShippingStreet, ShippingCity, ShippingCountry, Shipping_Country_AAM__c, Shipping_Country_AAM__r.Iso_Code__c, Shipping_Country_AAM__r.Country_Name__c
                FROM Account
                WHERE Id =: UtilsTest.account.Id ];

        String address2 = UtilsTest.aAddressLine1;
        String country2 = UtilsTest.aCountry;
        System.assert( acc.BillingStreet != null );
        System.assert( acc.BillingStreet.contains( address1 ) );
        System.assert( acc.BillingCity != null );
        System.assert( acc.BillingCity == UtilsTest.aCity );
        System.assert( acc.Billing_Country_AAM__c != null );
        System.assert( acc.Billing_Country_AAM__r.Iso_Code__c == country1 );
        System.assert( acc.BillingCountry != null );
        System.assert( acc.BillingCountry == acc.Billing_Country_AAM__r.Country_Name__c );
        System.assert( acc.ShippingStreet == null );
        System.assert( acc.ShippingCity == null );
        System.assert( acc.ShippingCountry == null );
        System.assert( acc.Shipping_Country_AAM__c == null );

        //update visiting address mapping primary status to false (mapped = changes standard fields)
        Aam_Settings__c aamSettings = Utils.aamSettings;
        aamSettings.Acc_Billing_Addr_Source__c = AddressMappingServices.ADDRESS_TYPE_VISITING_ADDRESS;
        UPSERT aamSettings Aam_Settings__c.Id;
        AddressMappingServices.objectNameToFieldToAddressType = null; //reset static variable to repopulate correct settings

        UPDATE new Address_Mapping__c( Id = visitingAddressMappingId, Primary__c = false );

        acc = [ SELECT BillingStreet, BillingCity, BillingCountry, Billing_Country_AAM__c, Billing_Country_AAM__r.Iso_Code__c, Billing_Country_AAM__r.Country_Name__c,
                       ShippingStreet, ShippingCity, ShippingCountry, Shipping_Country_AAM__c, Shipping_Country_AAM__r.Iso_Code__c, Shipping_Country_AAM__r.Country_Name__c
                FROM Account
                WHERE Id =: UtilsTest.account.Id ];

        //the system sets primary = true for this address mapping automatically
        System.assert( acc.BillingStreet != null );
        System.assert( acc.BillingStreet.contains( address1 ) );
        System.assert( acc.BillingCity != null );
        System.assert( acc.BillingCity == UtilsTest.aCity );
        System.assert( acc.Billing_Country_AAM__c != null );
        System.assert( acc.Billing_Country_AAM__r.Iso_Code__c == country1 );
        System.assert( acc.BillingCountry != null );
        System.assert( acc.BillingCountry == acc.Billing_Country_AAM__r.Country_Name__c );
        System.assert( acc.ShippingStreet == null );
        System.assert( acc.ShippingCity == null );
        System.assert( acc.ShippingCountry == null );
        System.assert( acc.Shipping_Country_AAM__c == null );

        /*System.assert( acc.BillingStreet == null );
        System.assert( acc.BillingCity == null );
        System.assert( acc.Billing_Country_AAM__c == null );
        System.assert( acc.BillingCountry == null );
        System.assert( acc.ShippingStreet == null );
        System.assert( acc.ShippingCity == null );
        System.assert( acc.ShippingCountry == null );
        System.assert( acc.Shipping_Country_AAM__c == null );*/

        Test.startTest();
            //update visiting address mapping primary status to true (mapped = changes standard fields)
            aamSettings = Utils.aamSettings;
            aamSettings.Acc_Billing_Addr_Source__c = AddressMappingServices.ADDRESS_TYPE_VISITING_ADDRESS;
            aamSettings.Acc_Shipping_Addr_Source__c = AddressMappingServices.ADDRESS_TYPE_VISITING_ADDRESS;
            UPSERT aamSettings Aam_Settings__c.Id;
            AddressMappingServices.objectNameToFieldToAddressType = null; //reset static variable to repopulate correct settings

            UPDATE new Address_Mapping__c( Id = visitingAddressMappingId, Primary__c = true );

            acc = [ SELECT BillingStreet, BillingCity, BillingCountry, Billing_Country_AAM__c, Billing_Country_AAM__r.Iso_Code__c, Billing_Country_AAM__r.Country_Name__c,
                           ShippingStreet, ShippingCity, ShippingCountry, Shipping_Country_AAM__c, Shipping_Country_AAM__r.Iso_Code__c, Shipping_Country_AAM__r.Country_Name__c
                    FROM Account
                    WHERE Id =: UtilsTest.account.Id ];

            //was already primary, so nothing has changed
            System.assert( acc.BillingStreet != null );
            System.assert( acc.BillingStreet.contains( address1 ) );
            System.assert( acc.BillingCity != null );
            System.assert( acc.BillingCity == UtilsTest.aCity );
            System.assert( acc.Billing_Country_AAM__c != null );
            System.assert( acc.Billing_Country_AAM__r.Iso_Code__c == country1 );
            System.assert( acc.BillingCountry != null );
            System.assert( acc.BillingCountry == acc.Billing_Country_AAM__r.Country_Name__c );
            System.assert( acc.ShippingStreet == null );
            System.assert( acc.ShippingCity == null );
            System.assert( acc.ShippingCountry == null );
            System.assert( acc.Shipping_Country_AAM__c == null );

            /*System.assert( acc.BillingStreet != null );
            System.assert( acc.BillingStreet.contains( address2 ) );
            System.assert( acc.BillingCity != null );
            System.assert( acc.BillingCity == UtilsTest.aCity );
            System.assert( acc.Billing_Country_AAM__c != null );
            System.assert( acc.Billing_Country_AAM__r.Iso_Code__c == country2 );
            System.assert( acc.BillingCountry != null );
            System.assert( acc.BillingCountry == acc.Billing_Country_AAM__r.Country_Name__c );
            System.assert( acc.ShippingStreet != null );
            System.assert( acc.ShippingStreet.contains( address2 ) );
            System.assert( acc.ShippingCity != null );
            System.assert( acc.ShippingCity == UtilsTest.aCity );
            System.assert( acc.Shipping_Country_AAM__c != null );
            System.assert( acc.Shipping_Country_AAM__r.Iso_Code__c == country2 );
            System.assert( acc.ShippingCountry != null );
            System.assert( acc.ShippingCountry == acc.Shipping_Country_AAM__r.Country_Name__c );*/

            //update billing address mapping primary status to false (mapped = changes standard fields)
            aamSettings = Utils.aamSettings;
            aamSettings.Acc_Billing_Addr_Source__c = AddressMappingServices.ADDRESS_TYPE_BILLING_ADDRESS;
            aamSettings.Acc_Shipping_Addr_Source__c = AddressMappingServices.ADDRESS_TYPE_VISITING_ADDRESS;
            UPSERT aamSettings Aam_Settings__c.Id;
            AddressMappingServices.objectNameToFieldToAddressType = null; //reset static variable to repopulate correct settings

            UPDATE new Address_Mapping__c( Id = billingAddressMappingId, Primary__c = false );

            acc = [ SELECT BillingStreet, BillingCity, BillingCountry, Billing_Country_AAM__c, Billing_Country_AAM__r.Iso_Code__c, Billing_Country_AAM__r.Country_Name__c,
                           ShippingStreet, ShippingCity, ShippingCountry, Shipping_Country_AAM__c, Shipping_Country_AAM__r.Iso_Code__c, Shipping_Country_AAM__r.Country_Name__c
                    FROM Account
                    WHERE Id =: UtilsTest.account.Id ];

            //was already primary, so nothing has changed
            System.assert( acc.BillingStreet != null );
            System.assert( acc.BillingStreet.contains( address1 ) );
            System.assert( acc.BillingCity != null );
            System.assert( acc.BillingCity == UtilsTest.aCity );
            System.assert( acc.Billing_Country_AAM__c != null );
            System.assert( acc.Billing_Country_AAM__r.Iso_Code__c == country1 );
            System.assert( acc.BillingCountry != null );
            System.assert( acc.BillingCountry == acc.Billing_Country_AAM__r.Country_Name__c );
            System.assert( acc.ShippingStreet == null );
            System.assert( acc.ShippingCity == null );
            System.assert( acc.ShippingCountry == null );
            System.assert( acc.Shipping_Country_AAM__c == null );

            /*System.assert( acc.BillingStreet == null );
            System.assert( acc.BillingCity == null );
            System.assert( acc.Billing_Country_AAM__c == null );
            System.assert( acc.BillingCountry == null );
            System.assert( acc.ShippingStreet != null );
            System.assert( acc.ShippingStreet.contains( address2 ) );
            System.assert( acc.ShippingCity != null );
            System.assert( acc.ShippingCity == UtilsTest.aCity );
            System.assert( acc.Shipping_Country_AAM__c != null );
            System.assert( acc.Shipping_Country_AAM__r.Iso_Code__c == country2 );
            System.assert( acc.ShippingCountry != null );
            System.assert( acc.ShippingCountry == acc.Shipping_Country_AAM__r.Country_Name__c );*/
        Test.stopTest();
    }

	@isTest
	private static void setPrimaryAddressesIfNoOtherPrimaryExistsForAccounts(){
		UtilsTest.amPrimary = false;
        Test.startTest();
        	UtilsTest.createTestDataForAccount( NUMBER_OF_RECORDS );
        Test.stopTest();
        List<Address_Mapping__c> selectedMappings = [Select Id From Address_Mapping__c Where Id In : UtilsTest.addressMappingsAccount And Primary__c = true];
        System.assertEquals( 1, selectedMappings.size() );
	}

	@isTest
	private static void setPrimaryAddressesIfNoOtherPrimaryExistsForContacts(){
		UtilsTest.amPrimary = false;
        Test.startTest();
        	UtilsTest.createTestDataForContact( NUMBER_OF_RECORDS, NUMBER_OF_RECORDS );
        Test.stopTest();
        List<Address_Mapping__c> selectedMappings = [Select Id From Address_Mapping__c Where Id In : UtilsTest.addressMappingsAccount And Primary__c = true];
        System.assertEquals( 1, selectedMappings.size() );
	}

	@isTest
	private static void setPrimaryAddressesIfNoOtherPrimaryExistsForAccountsNoActive(){
		UtilsTest.amPrimary = false;
		UtilsTest.amActive = false;
        Test.startTest();
        	UtilsTest.createTestDataForAccount( NUMBER_OF_RECORDS );
        Test.stopTest();
        List<Address_Mapping__c> selectedMappings = [Select Id From Address_Mapping__c Where Id In : UtilsTest.addressMappingsAccount And Primary__c = true];
        System.assertEquals( 0, selectedMappings.size() );
	}

	@isTest
	private static void setPrimaryAddressesIfNoOtherPrimaryExistsForContactsNoActive(){
		UtilsTest.amPrimary = false;
		UtilsTest.amActive = false;
        Test.startTest();
        	UtilsTest.createTestDataForContact( NUMBER_OF_RECORDS, NUMBER_OF_RECORDS );
        Test.stopTest();
        List<Address_Mapping__c> selectedMappings = [Select Id From Address_Mapping__c Where Id In : UtilsTest.addressMappingsAccount And Primary__c = true];
        System.assertEquals( 0, selectedMappings.size() );
	}

	@isTest
	private static void setPrimaryToAnotherAddressAtDeactivationTest(){
		UtilsTest.createTestDataForContact( NUMBER_OF_RECORDS, NUMBER_OF_RECORDS );
		Address_Mapping__c selectedPrimaryMapping = [Select Id From Address_Mapping__c Where Id In : UtilsTest.addressMappingsContact And Primary__c = true];
		Address_Mapping__c theEarliestMap;
		for (Address_Mapping__c mapping : UtilsTest.addressMappingsContact){
			if (mapping.Id != selectedPrimaryMapping.Id){
				theEarliestMap = mapping;
				break;
			}
		}
		Test.setCreatedDate( theEarliestMap.Id, Datetime.now().addDays(-1) );
		Test.startTest();
			selectedPrimaryMapping.Active__c = false;
			update selectedPrimaryMapping;
		Test.stopTest();
		List<Address_Mapping__c> selectedPrimaryMappingsAfterDeactivations = [Select Id From Address_Mapping__c Where Id In : UtilsTest.addressMappingsContact And Primary__c = true];
		System.assertEquals( 1, selectedPrimaryMappingsAfterDeactivations.size() );
		System.assertEquals( theEarliestMap.Id, selectedPrimaryMappingsAfterDeactivations[0].Id );
	}

	@isTest
	private static void setPrimaryToAnotherAddressAtDeactivationTest2(){
		UtilsTest.createTestDataForContact( NUMBER_OF_RECORDS, NUMBER_OF_RECORDS );
		Address_Mapping__c selectedPrimaryMapping = [Select Id From Address_Mapping__c Where Id In : UtilsTest.addressMappingsContact And Primary__c = true];
		Address_Mapping__c theEarliestMap;
		for (Address_Mapping__c mapping : UtilsTest.addressMappingsContact){
			if (mapping.Id != selectedPrimaryMapping.Id){
				theEarliestMap = mapping;
				break;
			}
		}
		Test.setCreatedDate( theEarliestMap.Id, Datetime.now().addDays(-1) );
		Test.startTest();
			selectedPrimaryMapping.Active__c = false;
			selectedPrimaryMapping.Primary__c = false;
			update selectedPrimaryMapping;
		Test.stopTest();
		List<Address_Mapping__c> selectedPrimaryMappingsAfterDeactivations = [Select Id From Address_Mapping__c Where Id In : UtilsTest.addressMappingsContact And Primary__c = true];
		System.assertEquals( 1, selectedPrimaryMappingsAfterDeactivations.size() );
		System.assertEquals( theEarliestMap.Id, selectedPrimaryMappingsAfterDeactivations[0].Id );
	}

    @isTest
    private static void enforceContactAddressDeactivationEnabled() {
        UtilsTest.amActive = true;
        UtilsTest.amPrimary = true;
        Utils.updateCustomSettings( true );
        Aam_Settings__c aamSettings = Utils.aamSettings;
        aamSettings.Enforce_Contact_Address_Deactivation__c = true;
        UPSERT aamSettings Aam_Settings__c.Id;

        UtilsTest.createTestDataForContact( 1, 1 );

        List<Address_Mapping__c> addressMappingsToUpdate = new List<Address_Mapping__c>();
        for( Address_Mapping__c addressMapping : UtilsTest.addressMappingsAccount ) {
            addressMappingsToUpdate.add( new Address_Mapping__c( Id = addressMapping.Id, Active__c = false ) );
        }

        Test.startTest();
            UPDATE addressMappingsToUpdate;
        Test.stopTest();

        List<Address_Mapping__c> selectedMappings = [ SELECT Active__c FROM Address_Mapping__c WHERE Contact__c != null ];
        System.assert( !selectedMappings.isEmpty() );
        for( Address_Mapping__c addressMapping : selectedMappings ) {
            System.assertEquals( false, addressMapping.Active__c );
        }
    }

    @isTest
    private static void enforceContactAddressDeactivationDisabled() {
        UtilsTest.amActive = true;
        UtilsTest.amPrimary = true;
        Utils.updateCustomSettings( true );
        Aam_Settings__c aamSettings = Utils.aamSettings;
        aamSettings.Enforce_Contact_Address_Deactivation__c = false;
        UPSERT aamSettings Aam_Settings__c.Id;

        UtilsTest.createTestDataForContact( 1, 1 );

        List<Address_Mapping__c> addressMappingsToUpdate = new List<Address_Mapping__c>();
        for( Address_Mapping__c addressMapping : UtilsTest.addressMappingsAccount ) {
            addressMappingsToUpdate.add( new Address_Mapping__c( Id = addressMapping.Id, Active__c = false ) );
        }

        Test.startTest();
            UPDATE addressMappingsToUpdate;
        Test.stopTest();

        List<Address_Mapping__c> selectedMappings = [ SELECT Active__c FROM Address_Mapping__c WHERE Contact__c != null ];
        System.assert( !selectedMappings.isEmpty() );
        for( Address_Mapping__c addressMapping : selectedMappings ) {
            System.assertEquals( true, addressMapping.Active__c );
        }
    }

    @isTest
    private static void countActiveAddressMappingsOnCreation() {
        UtilsTest.amActive = true;
        Integer numberOfRecordsToCreateForAccount = 5;
        Integer numberOfRecordsToCreateForContact = 5;

        Test.startTest();
            UtilsTest.createTestDataForContact( numberOfRecordsToCreateForAccount, numberOfRecordsToCreateForContact );
        Test.stopTest();

        Account account = [ SELECT FIL_AAM__Address_Mappings_Active_Count__c FROM Account WHERE Id = :UtilsTest.account.Id ];
        Contact contact = [ SELECT FIL_AAM__Address_Mappings_Active_Count__c FROM Contact WHERE Id = :UtilsTest.contact.Id ];

        System.assertEquals( numberOfRecordsToCreateForAccount, account.FIL_AAM__Address_Mappings_Active_Count__c );
        System.assertEquals( numberOfRecordsToCreateForContact, contact.FIL_AAM__Address_Mappings_Active_Count__c );
    }

    @isTest
    private static void countActiveAddressMappingsOnUpdate() {
        UtilsTest.amActive = true;
        Integer numberOfRecordsToCreateForAccount = 5;
        Integer numberOfRecordsToCreateForContact = 5;
        Integer numberOfRecordsToDeactivateForAccount = 3;
        Integer numberOfRecordsToDeactivateForContact = 3;
        UtilsTest.createTestDataForContact( numberOfRecordsToCreateForAccount, numberOfRecordsToCreateForContact );

        Test.startTest();
            List<Address_Mapping__c> addressMappingsAccount = [ SELECT Id FROM Address_Mapping__c WHERE Account__c != null LIMIT :numberOfRecordsToDeactivateForAccount ];
            for( Address_Mapping__c addressMapping : addressMappingsAccount ) {
                addressMapping.Active__c = false;
            }
            UPDATE addressMappingsAccount;

            List<Address_Mapping__c> addressMappingsContact = [ SELECT Id FROM Address_Mapping__c WHERE Contact__c != null LIMIT :numberOfRecordsToDeactivateForContact ];
            for( Address_Mapping__c addressMapping : addressMappingsContact ) {
                addressMapping.Active__c = false;
            }
            UPDATE addressMappingsContact;
        Test.stopTest();

        Account account = [ SELECT FIL_AAM__Address_Mappings_Active_Count__c FROM Account WHERE Id = :UtilsTest.account.Id ];
        Contact contact = [ SELECT FIL_AAM__Address_Mappings_Active_Count__c FROM Contact WHERE Id = :UtilsTest.contact.Id ];

        System.assertEquals( numberOfRecordsToCreateForAccount - numberOfRecordsToDeactivateForAccount, account.FIL_AAM__Address_Mappings_Active_Count__c );
        System.assertEquals( numberOfRecordsToCreateForContact - numberOfRecordsToDeactivateForContact, contact.FIL_AAM__Address_Mappings_Active_Count__c );
    }

    @isTest
    private static void countActiveAddressMappingsOnDelete() {
        UtilsTest.amActive = true;
        Integer numberOfRecordsToCreateForAccount = 5;
        Integer numberOfRecordsToCreateForContact = 5;
        Integer numberOfRecordsToDeleteForAccount = 3;
        Integer numberOfRecordsToDeleteForContact = 3;
        UtilsTest.createTestDataForContact( numberOfRecordsToCreateForAccount, numberOfRecordsToCreateForContact );

        Test.startTest();
            DELETE [ SELECT Id FROM Address_Mapping__c WHERE Account__c != null LIMIT :numberOfRecordsToDeleteForAccount ];
            DELETE [ SELECT Id FROM Address_Mapping__c WHERE Contact__c != null LIMIT :numberOfRecordsToDeleteForContact ];
        Test.stopTest();

        Account account = [ SELECT FIL_AAM__Address_Mappings_Active_Count__c FROM Account WHERE Id = :UtilsTest.account.Id ];
        Contact contact = [ SELECT FIL_AAM__Address_Mappings_Active_Count__c FROM Contact WHERE Id = :UtilsTest.contact.Id ];

        System.assertEquals( numberOfRecordsToCreateForAccount - numberOfRecordsToDeleteForAccount, account.FIL_AAM__Address_Mappings_Active_Count__c );
        System.assertEquals( numberOfRecordsToCreateForContact - numberOfRecordsToDeleteForContact, contact.FIL_AAM__Address_Mappings_Active_Count__c );
    }

    @isTest
    private static void countActiveAddressMappingsOnUpdateAccount() {
        UtilsTest.amActive = true;
        Integer numberOfRecordsToCreateForAccount = 5;
        Integer numberOfRecordsToCreateForContact = 5;
        Integer numberOfRecordsToReparentForAccount = 3;
        UtilsTest.createTestDataForContact( numberOfRecordsToCreateForAccount, numberOfRecordsToCreateForContact );

        Test.startTest();
            List<Address_Mapping__c> addressMappingsAccount = [ SELECT Id FROM Address_Mapping__c WHERE Account__c != null LIMIT :numberOfRecordsToReparentForAccount ];
            for( Address_Mapping__c addressMapping : addressMappingsAccount ) {
                addressMapping.Account__c = null;
                addressMapping.Contact__c = UtilsTest.contact.Id;
            }
            UPDATE addressMappingsAccount;
        Test.stopTest();

        Account account = [ SELECT FIL_AAM__Address_Mappings_Active_Count__c FROM Account WHERE Id = :UtilsTest.account.Id ];
        Contact contact = [ SELECT FIL_AAM__Address_Mappings_Active_Count__c FROM Contact WHERE Id = :UtilsTest.contact.Id ];

        System.assertEquals( numberOfRecordsToCreateForAccount - numberOfRecordsToReparentForAccount, account.FIL_AAM__Address_Mappings_Active_Count__c );
        System.assertEquals( numberOfRecordsToCreateForAccount + numberOfRecordsToReparentForAccount, contact.FIL_AAM__Address_Mappings_Active_Count__c );
    }

    @isTest
    private static void countActiveAddressMappingsOnUpdateContact() {
        UtilsTest.amActive = true;
        Integer numberOfRecordsToCreateForAccount = 5;
        Integer numberOfRecordsToCreateForContact = 5;
        Integer numberOfRecordsToReparentForContact = 3;
        UtilsTest.createTestDataForContact( numberOfRecordsToCreateForAccount, numberOfRecordsToCreateForContact );

        Test.startTest();
            List<Address_Mapping__c> addressMappingsAccount = [ SELECT Id FROM Address_Mapping__c WHERE Contact__c != null LIMIT :numberOfRecordsToReparentForContact ];
            for( Address_Mapping__c addressMapping : addressMappingsAccount ) {
                addressMapping.Contact__c = null;
                addressMapping.Account__c = UtilsTest.account.Id;
            }
            UPDATE addressMappingsAccount;
        Test.stopTest();

        Account account = [ SELECT FIL_AAM__Address_Mappings_Active_Count__c FROM Account WHERE Id = :UtilsTest.account.Id ];
        Contact contact = [ SELECT FIL_AAM__Address_Mappings_Active_Count__c FROM Contact WHERE Id = :UtilsTest.contact.Id ];

        System.assertEquals( numberOfRecordsToCreateForAccount + numberOfRecordsToReparentForContact, account.FIL_AAM__Address_Mappings_Active_Count__c );
        System.assertEquals( numberOfRecordsToCreateForAccount - numberOfRecordsToReparentForContact, contact.FIL_AAM__Address_Mappings_Active_Count__c );
    }

    @isTest
    private static void countActiveAddressMappingsOnDeleteAddress() {
        UtilsTest.amActive = true;
        Integer numberOfRecordsToCreateForAccount = 5;
        Integer numberOfRecordsToCreateForContact = 5;
        Integer numberOfRecordsToCreateAdditionallyForContact = 3;
        UtilsTest.createTestDataForContact( numberOfRecordsToCreateForAccount, numberOfRecordsToCreateForContact );

        Account account1 = [ SELECT Address_Mappings_Active_Count__c FROM Account WHERE Id = :UtilsTest.account.Id ];
        Contact contact1 = [ SELECT Address_Mappings_Active_Count__c FROM Contact WHERE Id = :UtilsTest.contact.Id ];

        System.assertEquals( numberOfRecordsToCreateForAccount, account1.FIL_AAM__Address_Mappings_Active_Count__c );
        System.assertEquals( numberOfRecordsToCreateForContact, contact1.FIL_AAM__Address_Mappings_Active_Count__c );

        Id addressId = UtilsTest.address.Id;
        UtilsTest.createAddress();
        UtilsTest.createAddressMappings( numberOfRecordsToCreateAdditionallyForContact ); //test utls will create only for contact

        Account account2 = [ SELECT Address_Mappings_Active_Count__c FROM Account WHERE Id = :UtilsTest.account.Id ];
        Contact contact2 = [ SELECT Address_Mappings_Active_Count__c FROM Contact WHERE Id = :UtilsTest.contact.Id ];

        System.assertEquals( numberOfRecordsToCreateForAccount, account2.FIL_AAM__Address_Mappings_Active_Count__c );
        System.assertEquals( numberOfRecordsToCreateForContact + numberOfRecordsToCreateAdditionallyForContact, contact2.FIL_AAM__Address_Mappings_Active_Count__c );

        Test.startTest();
            Database.delete( addressId );
        Test.stopTest();

        Account account3 = [ SELECT Address_Mappings_Active_Count__c FROM Account WHERE Id = :UtilsTest.account.Id ];
        Contact contact3 = [ SELECT Address_Mappings_Active_Count__c FROM Contact WHERE Id = :UtilsTest.contact.Id ];

        System.assertEquals( 0, account3.Address_Mappings_Active_Count__c );
        System.assertEquals( numberOfRecordsToCreateAdditionallyForContact, contact3.Address_Mappings_Active_Count__c );
    }

}