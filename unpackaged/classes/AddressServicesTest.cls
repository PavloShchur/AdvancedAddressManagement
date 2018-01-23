@isTest
private class AddressServicesTest {

    @isTest static void updateVerifiedFields() {
        UtilsTest.createAddress();

        Test.startTest();
            UPDATE new Address__c( Id = UtilsTest.address.Id,
                                   Verified__c = true );
        Test.stopTest();

        List<Address__c> addresses = [ SELECT Verified_Date__c, Verified_By__c
                                       FROM Address__c ];
        System.assert( !addresses.isEmpty() );
        for( Address__c address : addresses ) {
            if( address.Id == UtilsTest.address.Id ) {
                System.assert( address.Verified_Date__c != null );
                System.assert( address.Verified_Date__c == Date.today() );
                System.assert( address.Verified_By__c != null );
                System.assert( address.Verified_By__c == UserInfo.getUserId() );
            }
        }
    }

    @isTest static void getNumFieldsEntered() {
        UtilsTest.createAddress();

        Integer numOfFieldsEntered;

        Test.startTest();
            numOfFieldsEntered = AddressServices.getNumFieldsEntered( UtilsTest.address );
        Test.stopTest();

        List<Address__c> addresses = [ SELECT Verified_Date__c, Verified_By__c
                                       FROM Address__c ];
        System.assert( numOfFieldsEntered != null );
    }

    @isTest static void getRelatedAddressesInHierarchy() {
        Account topAccount = new Account( Name = 'testtop' );
        INSERT topAccount;
        UtilsTest.account = topAccount;
        Id topAddressId = UtilsTest.createAddress().Id;

        Account midAccount = new Account( Name = 'testmid', ParentId = topAccount.Id );
        INSERT midAccount;
        UtilsTest.account = midAccount;
        Id midAddressId = UtilsTest.createAddress().Id;

        Account botAccount = new Account( Name = 'testbot', ParentId = midAccount.Id );
        INSERT botAccount;
        UtilsTest.account = botAccount;
        Id botAddressId = UtilsTest.createAddress().Id;

        Account otherChildAccount = new Account( Name = 'testotherchild', ParentId = topAccount.Id );
        INSERT otherChildAccount;
        UtilsTest.account = otherChildAccount;
        Id otherChildAddressId = UtilsTest.createAddress().Id;

        Set<Id> addressIds = new Set<Id>{ topAddressId, midAddressId, botAddressId, otherChildAddressId };

        List<Address__c> relatedAddressesInHierarchy;

        Test.startTest();
            relatedAddressesInHierarchy = AddressServices.getRelatedAddressesInHierarchy( midAccount.Id, new Address__c(), 0, false );
        Test.stopTest();

        System.assert( !relatedAddressesInHierarchy.isEmpty() );
        System.assert( relatedAddressesInHierarchy.size() == addressIds.size() );
        for( Address__c address : relatedAddressesInHierarchy ) {
            System.assert( addressIds.contains( address.Id ) );
        }
    }

    @isTest static void getAddressRecord() {
        UtilsTest.createAddress();

        Address__c addressRecordNew;
        Address__c addressRecordMgmt;
        Address__c addressRecordDeactivate;

        Test.startTest();
            addressRecordNew = AddressServices.getAddressRecord( UtilsTest.address.Id, SObjectType.Address__c.FieldSets.New_Address_Address_Fields.getFields() );
            addressRecordMgmt = AddressServices.getAddressRecord( UtilsTest.address.Id, SObjectType.Address__c.FieldSets.Manage_Address_Address_Fields.getFields() );
            addressRecordDeactivate = AddressServices.getAddressRecord( UtilsTest.address.Id, SObjectType.Address__c.FieldSets.Deactivate_Address_Address_Fields.getFields() );
        Test.stopTest();

        System.assert( addressRecordNew != null );
        System.assert( addressRecordNew.Id != null );
        System.assert( addressRecordMgmt != null );
        System.assert( addressRecordMgmt.Id != null );
        System.assert( addressRecordDeactivate != null );
        System.assert( addressRecordDeactivate.Id != null );
    }

    @isTest static void getAddressRecordWithCustomSettings() {
        Address__c addressRecord;
        Aam_Settings__c settings = Aam_Settings__c.getInstance();
        settings.Default_Country_ISO_Code__c = UtilsTest.aCountry;
        UPSERT settings Aam_Settings__c.Id;

        Test.startTest();
            addressRecord = AddressServices.getAddressRecord( null, SObjectType.Address__c.FieldSets.New_Address_Address_Fields.getFields(), settings );
        Test.stopTest();

        System.assert( addressRecord != null );
        System.assert( addressRecord.Id == null );
        System.assert( addressRecord.Country__c == settings.Default_Country_ISO_Code__c );
    }

    @isTest static void getAddressLines() {
        UtilsTest.createAddress();

        Address__c address = AddressServices.getAddressRecord( UtilsTest.address.Id, null );

        String addressLines;

        Test.startTest();
            addressLines = AddressServices.getAddressLines( address );
        Test.stopTest();

        System.assert( !String.isEmpty( addressLines ) );
    }

    @isTest static void standardAddressPopulationOnAccount() {
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

        //create new shipping address (used in mappings) = populate standard shipping address
        UtilsTest.amAddressType = AddressMappingServices.ADDRESS_TYPE_SHIPPING_ADDRESS;
        UtilsTest.aAddressLine1 += UtilsTest.aAddressLine1;
        UtilsTest.aCountry = 'PL';
        UtilsTest.createTestDataForAccount( 1 );
        Id shippingAddressId = UtilsTest.address.Id;

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
        System.assert( acc.ShippingStreet != null );
        System.assert( acc.ShippingStreet.contains( address2 ) );
        System.assert( acc.ShippingCity != null );
        System.assert( acc.ShippingCity == UtilsTest.aCity );
        System.assert( acc.ShippingCountry != null );
        System.assert( acc.ShippingCountry == acc.Shipping_Country_AAM__r.Country_Name__c );
        System.assert( acc.Shipping_Country_AAM__c != null );
        System.assert( acc.Shipping_Country_AAM__r.Iso_Code__c == country2 );

        //create new other address (not used in mappings) = does nothing
        UtilsTest.amAddressType = AddressMappingServices.ADDRESS_TYPE_OTHER_ADDRESS;
        UtilsTest.aAddressLine1 += UtilsTest.aAddressLine1;
        UtilsTest.aCountry = 'MX';
        UtilsTest.createTestDataForAccount( 1 );
        Id otherAddressId = UtilsTest.address.Id;

        acc = [ SELECT BillingStreet, BillingCity, BillingCountry, Billing_Country_AAM__c, Billing_Country_AAM__r.Iso_Code__c, Billing_Country_AAM__r.Country_Name__c,
                       ShippingStreet, ShippingCity, ShippingCountry, Shipping_Country_AAM__c, Shipping_Country_AAM__r.Iso_Code__c, Shipping_Country_AAM__r.Country_Name__c
                FROM Account
                WHERE Id =: UtilsTest.account.Id ];

        System.assert( acc.BillingStreet != null );
        System.assert( acc.BillingStreet.contains( address1 ) );
        System.assert( acc.BillingCity != null );
        System.assert( acc.BillingCity == UtilsTest.aCity );
        System.assert( acc.Billing_Country_AAM__c != null );
        System.assert( acc.Billing_Country_AAM__r.Iso_Code__c == country1 );
        System.assert( acc.BillingCountry != null );
        System.assert( acc.BillingCountry == acc.Billing_Country_AAM__r.Country_Name__c );
        System.assert( acc.ShippingStreet != null );
        System.assert( acc.ShippingStreet.contains( address2 ) );
        System.assert( acc.ShippingCity != null );
        System.assert( acc.ShippingCity == UtilsTest.aCity );
        System.assert( acc.ShippingCountry != null );
        System.assert( acc.ShippingCountry == acc.Shipping_Country_AAM__r.Country_Name__c );
        System.assert( acc.Shipping_Country_AAM__c != null );
        System.assert( acc.Shipping_Country_AAM__r.Iso_Code__c == country2 );

        //create new billing address (used in mappings) = owerwrites standard billing address
        UtilsTest.amAddressType = AddressMappingServices.ADDRESS_TYPE_BILLING_ADDRESS; //new primary billing address
        UtilsTest.aAddressLine1 += UtilsTest.aAddressLine1;
        UtilsTest.aCountry = 'PT';
        UtilsTest.createTestDataForAccount( 1 );
        Id billingAddressId = UtilsTest.address.Id;

        acc = [ SELECT BillingStreet, BillingCity, BillingCountry, Billing_Country_AAM__c, Billing_Country_AAM__r.Iso_Code__c, Billing_Country_AAM__r.Country_Name__c,
                       ShippingStreet, ShippingCity, ShippingCountry, Shipping_Country_AAM__c, Shipping_Country_AAM__r.Iso_Code__c, Shipping_Country_AAM__r.Country_Name__c
                FROM Account
                WHERE Id =: UtilsTest.account.Id ];

        String address3 = UtilsTest.aAddressLine1;
        String country3 = UtilsTest.aCountry;
        System.assert( acc.BillingStreet != null );
        System.assert( acc.BillingStreet.contains( address3 ) );
        System.assert( acc.BillingCity != null );
        System.assert( acc.BillingCity == UtilsTest.aCity );
        System.assert( acc.Billing_Country_AAM__c != null );
        System.assert( acc.Billing_Country_AAM__r.Iso_Code__c == country3 );
        System.assert( acc.BillingCountry != null );
        System.assert( acc.BillingCountry == acc.Billing_Country_AAM__r.Country_Name__c );
        System.assert( acc.ShippingStreet != null );
        System.assert( acc.ShippingStreet.contains( address2 ) );
        System.assert( acc.ShippingCity != null );
        System.assert( acc.ShippingCity == UtilsTest.aCity );
        System.assert( acc.ShippingCountry != null );
        System.assert( acc.ShippingCountry == acc.Shipping_Country_AAM__r.Country_Name__c );
        System.assert( acc.Shipping_Country_AAM__c != null );
        System.assert( acc.Shipping_Country_AAM__r.Iso_Code__c == country2 );

        //update billing address (used in mappings) = updates standard billing address
        Address__c billingAddress = [ SELECT City__c, Country__c FROM Address__c WHERE Id = :billingAddressId ];
        billingAddress.City__c += billingAddress.City__c;
        billingAddress.Country__c = 'NO';
        UPDATE billingAddress;

        acc = [ SELECT BillingStreet, BillingCity, BillingCountry, Billing_Country_AAM__c, Billing_Country_AAM__r.Iso_Code__c, Billing_Country_AAM__r.Country_Name__c,
                       ShippingStreet, ShippingCity, ShippingCountry, Shipping_Country_AAM__c, Shipping_Country_AAM__r.Iso_Code__c, Shipping_Country_AAM__r.Country_Name__c
                FROM Account
                WHERE Id =: UtilsTest.account.Id ];

        System.assert( acc.BillingStreet != null );
        System.assert( acc.BillingStreet.contains( address3 ) );
        System.assert( acc.BillingCity != null );
        System.assert( acc.BillingCity == billingAddress.City__c );
        System.assert( acc.Billing_Country_AAM__c != null );
        System.assert( acc.Billing_Country_AAM__r.Iso_Code__c == billingAddress.Country__c );
        System.assert( acc.BillingCountry != null );
        System.assert( acc.BillingCountry == acc.Billing_Country_AAM__r.Country_Name__c );
        System.assert( acc.ShippingStreet != null );
        System.assert( acc.ShippingStreet.contains( address2 ) );
        System.assert( acc.ShippingCity != null );
        System.assert( acc.ShippingCity == UtilsTest.aCity );
        System.assert( acc.ShippingCountry != null );
        System.assert( acc.ShippingCountry == acc.Shipping_Country_AAM__r.Country_Name__c );
        System.assert( acc.Shipping_Country_AAM__c != null );
        System.assert( acc.Shipping_Country_AAM__r.Iso_Code__c == country2 );

        Test.startTest();
            //update shipping address (used in mappings) = updates standard shipping address
            Address__c shippingAddress = [ SELECT City__c, Country__c FROM Address__c WHERE Id = :shippingAddressId ];
            shippingAddress.City__c += shippingAddress.City__c;
            shippingAddress.Country__c = 'NO';
            UPDATE shippingAddress;

            acc = [ SELECT BillingStreet, BillingCity, BillingCountry, Billing_Country_AAM__c, Billing_Country_AAM__r.Iso_Code__c, Billing_Country_AAM__r.Country_Name__c,
                           ShippingStreet, ShippingCity, ShippingCountry, Shipping_Country_AAM__c, Shipping_Country_AAM__r.Iso_Code__c, Shipping_Country_AAM__r.Country_Name__c
                    FROM Account
                    WHERE Id =: UtilsTest.account.Id ];

            System.assert( acc.BillingStreet != null );
            System.assert( acc.BillingStreet.contains( address3 ) );
            System.assert( acc.BillingCity != null );
            System.assert( acc.BillingCity == billingAddress.City__c );
            System.assert( acc.Billing_Country_AAM__c != null );
            System.assert( acc.Billing_Country_AAM__r.Iso_Code__c == billingAddress.Country__c );
            System.assert( acc.BillingCountry != null );
            System.assert( acc.BillingCountry == acc.Billing_Country_AAM__r.Country_Name__c );
            System.assert( acc.ShippingStreet != null );
            System.assert( acc.ShippingStreet.contains( address2 ) );
            System.assert( acc.ShippingCity != null );
            System.assert( acc.ShippingCity == shippingAddress.City__c );
            System.assert( acc.ShippingCountry != null );
            System.assert( acc.ShippingCountry == acc.Shipping_Country_AAM__r.Country_Name__c );
            System.assert( acc.Shipping_Country_AAM__c != null );
            System.assert( acc.Shipping_Country_AAM__r.Iso_Code__c == shippingAddress.Country__c );

            //update other address (not used in mappings) = does nothing
            Address__c otherAddress = [ SELECT City__c, Country__c FROM Address__c WHERE Id = :otherAddressId ];
            otherAddress.City__c += otherAddress.City__c;
            otherAddress.Country__c = 'TW';
            UPDATE otherAddress;

            acc = [ SELECT BillingStreet, BillingCity, BillingCountry, Billing_Country_AAM__c, Billing_Country_AAM__r.Iso_Code__c, Billing_Country_AAM__r.Country_Name__c,
                           ShippingStreet, ShippingCity, ShippingCountry, Shipping_Country_AAM__c, Shipping_Country_AAM__r.Iso_Code__c, Shipping_Country_AAM__r.Country_Name__c
                    FROM Account
                    WHERE Id =: UtilsTest.account.Id ];

            System.assert( acc.BillingStreet != null );
            System.assert( acc.BillingStreet.contains( address3 ) );
            System.assert( acc.BillingCity != null );
            System.assert( acc.BillingCity == billingAddress.City__c );
            System.assert( acc.Billing_Country_AAM__c != null );
            System.assert( acc.Billing_Country_AAM__r.Iso_Code__c == billingAddress.Country__c );
            System.assert( acc.BillingCountry != null );
            System.assert( acc.BillingCountry == acc.Billing_Country_AAM__r.Country_Name__c );
            System.assert( acc.ShippingStreet != null );
            System.assert( acc.ShippingStreet.contains( address2 ) );
            System.assert( acc.ShippingCity != null );
            System.assert( acc.ShippingCity == shippingAddress.City__c );
            System.assert( acc.ShippingCountry != null );
            System.assert( acc.ShippingCountry == acc.Shipping_Country_AAM__r.Country_Name__c );
            System.assert( acc.Shipping_Country_AAM__c != null );
            System.assert( acc.Shipping_Country_AAM__r.Iso_Code__c == shippingAddress.Country__c );

            //delete billing address (used in mappings) = deletes standard billing address
            DELETE billingAddress;

            acc = [ SELECT BillingStreet, BillingCity, BillingCountry, Billing_Country_AAM__c, Billing_Country_AAM__r.Iso_Code__c, Billing_Country_AAM__r.Country_Name__c,
                           ShippingStreet, ShippingCity, ShippingCountry, Shipping_Country_AAM__c, Shipping_Country_AAM__r.Iso_Code__c, Shipping_Country_AAM__r.Country_Name__c
                    FROM Account
                    WHERE Id =: UtilsTest.account.Id ];

            System.assert( acc.BillingStreet == null );
            System.assert( acc.BillingCity == null );
            System.assert( acc.Billing_Country_AAM__c == null );
            System.assert( acc.BillingCountry == null );
            System.assert( acc.ShippingStreet != null );
            System.assert( acc.ShippingStreet.contains( address2 ) );
            System.assert( acc.ShippingCity != null );
            System.assert( acc.ShippingCity == shippingAddress.City__c );
            System.assert( acc.ShippingCountry != null );
            System.assert( acc.ShippingCountry == acc.Shipping_Country_AAM__r.Country_Name__c );
            System.assert( acc.Shipping_Country_AAM__c != null );
            System.assert( acc.Shipping_Country_AAM__r.Iso_Code__c == shippingAddress.Country__c );

            //delete other address (not used in mappings) = does nothing
            DELETE otherAddress;

            acc = [ SELECT BillingStreet, BillingCity, BillingCountry, Billing_Country_AAM__c, Billing_Country_AAM__r.Iso_Code__c, Billing_Country_AAM__r.Country_Name__c,
                           ShippingStreet, ShippingCity, ShippingCountry, Shipping_Country_AAM__c, Shipping_Country_AAM__r.Iso_Code__c, Shipping_Country_AAM__r.Country_Name__c
                    FROM Account
                    WHERE Id =: UtilsTest.account.Id ];

            System.assert( acc.BillingStreet == null );
            System.assert( acc.BillingCity == null );
            System.assert( acc.Billing_Country_AAM__c == null );
            System.assert( acc.BillingCountry == null );
            System.assert( acc.ShippingStreet != null );
            System.assert( acc.ShippingStreet.contains( address2 ) );
            System.assert( acc.ShippingCity != null );
            System.assert( acc.ShippingCity == shippingAddress.City__c );
            System.assert( acc.ShippingCountry != null );
            System.assert( acc.ShippingCountry == acc.Shipping_Country_AAM__r.Country_Name__c );
            System.assert( acc.Shipping_Country_AAM__c != null );
            System.assert( acc.Shipping_Country_AAM__r.Iso_Code__c == shippingAddress.Country__c );

            //update shipping address (used in mappings) = renames standard shipping address
            shippingAddress = [ SELECT City__c, Country__c FROM Address__c WHERE Id = :shippingAddressId ];
            shippingAddress.City__c += shippingAddress.City__c;
            shippingAddress.Country__c = 'LU';
            UPDATE shippingAddress;

            acc = [ SELECT BillingStreet, BillingCity, BillingCountry, Billing_Country_AAM__c, Billing_Country_AAM__r.Iso_Code__c, Billing_Country_AAM__r.Country_Name__c,
                           ShippingStreet, ShippingCity, ShippingCountry, Shipping_Country_AAM__c, Shipping_Country_AAM__r.Iso_Code__c, Shipping_Country_AAM__r.Country_Name__c
                    FROM Account
                    WHERE Id =: UtilsTest.account.Id ];

            System.assert( acc.BillingStreet == null );
            System.assert( acc.BillingCity == null );
            System.assert( acc.Billing_Country_AAM__c == null );
            System.assert( acc.BillingCountry == null );
            System.assert( acc.ShippingStreet != null );
            System.assert( acc.ShippingStreet.contains( address2 ) );
            System.assert( acc.ShippingCity != null );
            System.assert( acc.ShippingCity == shippingAddress.City__c );
            System.assert( acc.ShippingCountry != null );
            System.assert( acc.ShippingCountry == acc.Shipping_Country_AAM__r.Country_Name__c );
            System.assert( acc.Shipping_Country_AAM__c != null );
            System.assert( acc.Shipping_Country_AAM__r.Iso_Code__c == shippingAddress.Country__c );

            //delete shipping address (used in mappings) = deletes standard shipping address
            DELETE shippingAddress;

            acc = [ SELECT BillingStreet, BillingCity, BillingCountry, Billing_Country_AAM__c, Billing_Country_AAM__r.Iso_Code__c, Billing_Country_AAM__r.Country_Name__c,
                           ShippingStreet, ShippingCity, ShippingCountry, Shipping_Country_AAM__c, Shipping_Country_AAM__r.Iso_Code__c, Shipping_Country_AAM__r.Country_Name__c
                    FROM Account
                    WHERE Id =: UtilsTest.account.Id ];

            System.assert( acc.BillingStreet == null );
            System.assert( acc.BillingCity == null );
            System.assert( acc.Billing_Country_AAM__c == null );
            System.assert( acc.BillingCountry == null );
            System.assert( acc.BillingStreet == null );
            System.assert( acc.ShippingStreet == null );
            System.assert( acc.ShippingCity == null );
            System.assert( acc.ShippingCountry == null );
            System.assert( acc.Shipping_Country_AAM__c == null );
        Test.stopTest();
    }

    @isTest static void standardAddressPopulationOnContact() {
        CountryServices.recreateCountryMappings();
        Utils.updateCustomSettings( true );

        //create new mailing address (used in mappings) = populate standard mailing address
        UtilsTest.amAddressType = AddressMappingServices.ADDRESS_TYPE_MAILING_ADDRESS;
        UtilsTest.amPrimary = true;
        UtilsTest.amActive = true;
        UtilsTest.createTestDataForContact( 1, 1 );

        Contact con = [ SELECT MailingStreet, MailingCity, MailingCountry, Mailing_Country_AAM__c, Mailing_Country_AAM__r.Iso_Code__c, Mailing_Country_AAM__r.Country_Name__c,
                               OtherStreet, OtherCity, OtherCountry, Other_Country_AAM__c, Other_Country_AAM__r.Iso_Code__c, Other_Country_AAM__r.Country_Name__c
                        FROM Contact
                        WHERE Id =: UtilsTest.contact.Id ];
        String address1 = UtilsTest.aAddressLine1;
        String country1 = UtilsTest.aCountry;
        System.assert( con.MailingStreet != null );
        System.assert( con.MailingStreet.contains( address1 ) );
        System.assert( con.MailingCity != null );
        System.assert( con.MailingCity == UtilsTest.aCity );
        System.assert( con.Mailing_Country_AAM__c != null );
        System.assert( con.Mailing_Country_AAM__r.Iso_Code__c == country1 );
        System.assert( con.MailingCountry != null );
        System.assert( con.MailingCountry == con.Mailing_Country_AAM__r.Country_Name__c );
        System.assert( con.OtherStreet == null );
        System.assert( con.OtherCity == null );
        System.assert( con.OtherCountry == null );
        System.assert( con.Other_Country_AAM__c == null );

        //create new other address (used in mappings) = populate standard other address
        UtilsTest.amAddressType = AddressMappingServices.ADDRESS_TYPE_OTHER_ADDRESS;
        UtilsTest.aAddressLine1 += UtilsTest.aAddressLine1;
        UtilsTest.aCountry = 'PL';
        UtilsTest.createAddress();
        UtilsTest.createTestDataForContact( 0, 1 );
        Id otherAddressId = UtilsTest.address.Id;

        con = [ SELECT MailingStreet, MailingCity, MailingCountry, Mailing_Country_AAM__c, Mailing_Country_AAM__r.Iso_Code__c, Mailing_Country_AAM__r.Country_Name__c,
                       OtherStreet, OtherCity, OtherCountry, Other_Country_AAM__c, Other_Country_AAM__r.Iso_Code__c, Other_Country_AAM__r.Country_Name__c
                FROM Contact
                WHERE Id =: UtilsTest.contact.Id ];

        String address2 = UtilsTest.aAddressLine1;
        String country2 = UtilsTest.aCountry;
        System.assert( con.MailingStreet != null );
        System.assert( con.MailingStreet.contains( address1 ) );
        System.assert( con.MailingCity != null );
        System.assert( con.MailingCity == UtilsTest.aCity );
        System.assert( con.Mailing_Country_AAM__c != null );
        System.assert( con.Mailing_Country_AAM__r.Iso_Code__c == country1 );
        System.assert( con.MailingCountry != null );
        System.assert( con.MailingCountry == con.Mailing_Country_AAM__r.Country_Name__c );
        System.assert( con.OtherStreet != null );
        System.assert( con.OtherStreet.contains( address2 ) );
        System.assert( con.OtherCity != null );
        System.assert( con.OtherCity == UtilsTest.aCity );
        System.assert( con.OtherCountry != null );
        System.assert( con.OtherCountry == con.Other_Country_AAM__r.Country_Name__c );
        System.assert( con.Other_Country_AAM__c != null );
        System.assert( con.Other_Country_AAM__r.Iso_Code__c == country2 );

        //create new visiting address (not used in mappings) = does nothing
        UtilsTest.amAddressType = AddressMappingServices.ADDRESS_TYPE_VISITING_ADDRESS;
        UtilsTest.aAddressLine1 += UtilsTest.aAddressLine1;
        UtilsTest.aCountry = 'MX';
        UtilsTest.createAddress();
        UtilsTest.createTestDataForContact( 0, 1 );
        Id visitingAddressId = UtilsTest.address.Id;

        con = [ SELECT MailingStreet, MailingCity, MailingCountry, Mailing_Country_AAM__c, Mailing_Country_AAM__r.Iso_Code__c, Mailing_Country_AAM__r.Country_Name__c,
                       OtherStreet, OtherCity, OtherCountry, Other_Country_AAM__c, Other_Country_AAM__r.Iso_Code__c, Other_Country_AAM__r.Country_Name__c
                FROM Contact
                WHERE Id =: UtilsTest.contact.Id ];

        System.assert( con.MailingStreet != null );
        System.assert( con.MailingStreet.contains( address1 ) );
        System.assert( con.MailingCity != null );
        System.assert( con.MailingCity == UtilsTest.aCity );
        System.assert( con.Mailing_Country_AAM__c != null );
        System.assert( con.Mailing_Country_AAM__r.Iso_Code__c == country1 );
        System.assert( con.MailingCountry != null );
        System.assert( con.MailingCountry == con.Mailing_Country_AAM__r.Country_Name__c );
        System.assert( con.OtherStreet != null );
        System.assert( con.OtherStreet.contains( address2 ) );
        System.assert( con.OtherCity != null );
        System.assert( con.OtherCity == UtilsTest.aCity );
        System.assert( con.OtherCountry != null );
        System.assert( con.OtherCountry == con.Other_Country_AAM__r.Country_Name__c );
        System.assert( con.Other_Country_AAM__c != null );
        System.assert( con.Other_Country_AAM__r.Iso_Code__c == country2 );

        //create new mailing address (used in mappings) = owerwrites standard mailing address
        UtilsTest.amAddressType = AddressMappingServices.ADDRESS_TYPE_MAILING_ADDRESS; //new primary mailing address
        UtilsTest.aAddressLine1 += UtilsTest.aAddressLine1;
        UtilsTest.aCountry = 'PT';
        UtilsTest.createAddress();
        UtilsTest.createTestDataForContact( 0, 1 );
        Id mailingAddressId = UtilsTest.address.Id;

        con = [ SELECT MailingStreet, MailingCity, MailingCountry, Mailing_Country_AAM__c, Mailing_Country_AAM__r.Iso_Code__c, Mailing_Country_AAM__r.Country_Name__c,
                       OtherStreet, OtherCity, OtherCountry, Other_Country_AAM__c, Other_Country_AAM__r.Iso_Code__c, Other_Country_AAM__r.Country_Name__c
                FROM Contact
                WHERE Id =: UtilsTest.contact.Id ];

        String address3 = UtilsTest.aAddressLine1;
        String country3 = UtilsTest.aCountry;
        System.assert( con.MailingStreet != null );
        System.assert( con.MailingStreet.contains( address3 ) );
        System.assert( con.MailingCity != null );
        System.assert( con.MailingCity == UtilsTest.aCity );
        System.assert( con.Mailing_Country_AAM__c != null );
        System.assert( con.Mailing_Country_AAM__r.Iso_Code__c == country3 );
        System.assert( con.MailingCountry != null );
        System.assert( con.MailingCountry == con.Mailing_Country_AAM__r.Country_Name__c );
        System.assert( con.OtherStreet != null );
        System.assert( con.OtherStreet.contains( address2 ) );
        System.assert( con.OtherCity != null );
        System.assert( con.OtherCity == UtilsTest.aCity );
        System.assert( con.OtherCountry != null );
        System.assert( con.OtherCountry == con.Other_Country_AAM__r.Country_Name__c );
        System.assert( con.Other_Country_AAM__c != null );
        System.assert( con.Other_Country_AAM__r.Iso_Code__c == country2 );

        //update mailing address (used in mappings) = updates standard mailing address
        Address__c mailingAddress = [ SELECT City__c, Country__c FROM Address__c WHERE Id = :mailingAddressId ];
        mailingAddress.City__c += mailingAddress.City__c;
        mailingAddress.Country__c = 'NO';
        UPDATE mailingAddress;

        con = [ SELECT MailingStreet, MailingCity, MailingCountry, Mailing_Country_AAM__c, Mailing_Country_AAM__r.Iso_Code__c, Mailing_Country_AAM__r.Country_Name__c,
                       OtherStreet, OtherCity, OtherCountry, Other_Country_AAM__c, Other_Country_AAM__r.Iso_Code__c, Other_Country_AAM__r.Country_Name__c
                FROM Contact
                WHERE Id =: UtilsTest.contact.Id ];

        System.assert( con.MailingStreet != null );
        System.assert( con.MailingStreet.contains( address3 ) );
        System.assert( con.MailingCity != null );
        System.assert( con.MailingCity == mailingAddress.City__c );
        System.assert( con.Mailing_Country_AAM__c != null );
        System.assert( con.Mailing_Country_AAM__r.Iso_Code__c == mailingAddress.Country__c );
        System.assert( con.MailingCountry != null );
        System.assert( con.MailingCountry == con.Mailing_Country_AAM__r.Country_Name__c );
        System.assert( con.OtherStreet != null );
        System.assert( con.OtherStreet.contains( address2 ) );
        System.assert( con.OtherCity != null );
        System.assert( con.OtherCity == UtilsTest.aCity );
        System.assert( con.OtherCountry != null );
        System.assert( con.OtherCountry == con.Other_Country_AAM__r.Country_Name__c );
        System.assert( con.Other_Country_AAM__c != null );
        System.assert( con.Other_Country_AAM__r.Iso_Code__c == country2 );

        Test.startTest();
            //update other address (used in mappings) = updates standard other address
            Address__c otherAddress = [ SELECT City__c, Country__c FROM Address__c WHERE Id = :otherAddressId ];
            otherAddress.City__c += otherAddress.City__c;
            otherAddress.Country__c = 'NO';
            UPDATE otherAddress;

            con = [ SELECT MailingStreet, MailingCity, MailingCountry, Mailing_Country_AAM__c, Mailing_Country_AAM__r.Iso_Code__c, Mailing_Country_AAM__r.Country_Name__c,
                           OtherStreet, OtherCity, OtherCountry, Other_Country_AAM__c, Other_Country_AAM__r.Iso_Code__c, Other_Country_AAM__r.Country_Name__c
                    FROM Contact
                    WHERE Id =: UtilsTest.contact.Id ];

            System.assert( con.MailingStreet != null );
            System.assert( con.MailingStreet.contains( address3 ) );
            System.assert( con.MailingCity != null );
            System.assert( con.MailingCity == mailingAddress.City__c );
            System.assert( con.Mailing_Country_AAM__c != null );
            System.assert( con.Mailing_Country_AAM__r.Iso_Code__c == mailingAddress.Country__c );
            System.assert( con.MailingCountry != null );
            System.assert( con.MailingCountry == con.Mailing_Country_AAM__r.Country_Name__c );
            System.assert( con.OtherStreet != null );
            System.assert( con.OtherStreet.contains( address2 ) );
            System.assert( con.OtherCity != null );
            System.assert( con.OtherCity == otherAddress.City__c );
            System.assert( con.OtherCountry != null );
            System.assert( con.OtherCountry == con.Other_Country_AAM__r.Country_Name__c );
            System.assert( con.Other_Country_AAM__c != null );
            System.assert( con.Other_Country_AAM__r.Iso_Code__c == otherAddress.Country__c );

            //update visiting address (not used in mappings) = does nothing
            Address__c visitingAddress = [ SELECT City__c, Country__c FROM Address__c WHERE Id = :visitingAddressId ];
            visitingAddress.City__c += visitingAddress.City__c;
            visitingAddress.Country__c = 'TW';
            UPDATE visitingAddress;

            con = [ SELECT MailingStreet, MailingCity, MailingCountry, Mailing_Country_AAM__c, Mailing_Country_AAM__r.Iso_Code__c, Mailing_Country_AAM__r.Country_Name__c,
                           OtherStreet, OtherCity, OtherCountry, Other_Country_AAM__c, Other_Country_AAM__r.Iso_Code__c, Other_Country_AAM__r.Country_Name__c
                    FROM Contact
                    WHERE Id =: UtilsTest.contact.Id ];

            System.assert( con.MailingStreet != null );
            System.assert( con.MailingStreet.contains( address3 ) );
            System.assert( con.MailingCity != null );
            System.assert( con.MailingCity == mailingAddress.City__c );
            System.assert( con.Mailing_Country_AAM__c != null );
            System.assert( con.Mailing_Country_AAM__r.Iso_Code__c == mailingAddress.Country__c );
            System.assert( con.MailingCountry != null );
            System.assert( con.MailingCountry == con.Mailing_Country_AAM__r.Country_Name__c );
            System.assert( con.OtherStreet != null );
            System.assert( con.OtherStreet.contains( address2 ) );
            System.assert( con.OtherCity != null );
            System.assert( con.OtherCity == otherAddress.City__c );
            System.assert( con.OtherCountry != null );
            System.assert( con.OtherCountry == con.Other_Country_AAM__r.Country_Name__c );
            System.assert( con.Other_Country_AAM__c != null );
            System.assert( con.Other_Country_AAM__r.Iso_Code__c == otherAddress.Country__c );

            //delete mailing address (used in mappings) = deletes standard mailing address
            DELETE mailingAddress;

            con = [ SELECT MailingStreet, MailingCity, MailingCountry, Mailing_Country_AAM__c, Mailing_Country_AAM__r.Iso_Code__c, Mailing_Country_AAM__r.Country_Name__c,
                           OtherStreet, OtherCity, OtherCountry, Other_Country_AAM__c, Other_Country_AAM__r.Iso_Code__c, Other_Country_AAM__r.Country_Name__c
                    FROM Contact
                    WHERE Id =: UtilsTest.contact.Id ];

            System.assert( con.MailingStreet == null );
            System.assert( con.MailingCity == null );
            System.assert( con.Mailing_Country_AAM__c == null );
            System.assert( con.MailingCountry == null );
            System.assert( con.OtherStreet != null );
            System.assert( con.OtherStreet.contains( address2 ) );
            System.assert( con.OtherCity != null );
            System.assert( con.OtherCity == otherAddress.City__c );
            System.assert( con.OtherCountry != null );
            System.assert( con.OtherCountry == con.Other_Country_AAM__r.Country_Name__c );
            System.assert( con.Other_Country_AAM__c != null );
            System.assert( con.Other_Country_AAM__r.Iso_Code__c == otherAddress.Country__c );

            //delete visiting address (not used in mappings) = does nothing
            DELETE visitingAddress;

            con = [ SELECT MailingStreet, MailingCity, MailingCountry, Mailing_Country_AAM__c, Mailing_Country_AAM__r.Iso_Code__c, Mailing_Country_AAM__r.Country_Name__c,
                           OtherStreet, OtherCity, OtherCountry, Other_Country_AAM__c, Other_Country_AAM__r.Iso_Code__c, Other_Country_AAM__r.Country_Name__c
                    FROM Contact
                    WHERE Id =: UtilsTest.contact.Id ];

            System.assert( con.MailingStreet == null );
            System.assert( con.MailingCity == null );
            System.assert( con.Mailing_Country_AAM__c == null );
            System.assert( con.MailingCountry == null );
            System.assert( con.OtherStreet != null );
            System.assert( con.OtherStreet.contains( address2 ) );
            System.assert( con.OtherCity != null );
            System.assert( con.OtherCity == otherAddress.City__c );
            System.assert( con.OtherCountry != null );
            System.assert( con.OtherCountry == con.Other_Country_AAM__r.Country_Name__c );
            System.assert( con.Other_Country_AAM__c != null );
            System.assert( con.Other_Country_AAM__r.Iso_Code__c == otherAddress.Country__c );

            //update other address (used in mappings) = renames standard other address
            otherAddress = [ SELECT City__c, Country__c FROM Address__c WHERE Id = :otherAddressId ];
            otherAddress.City__c += otherAddress.City__c;
            otherAddress.Country__c = 'LU';
            UPDATE otherAddress;

            con = [ SELECT MailingStreet, MailingCity, MailingCountry, Mailing_Country_AAM__c, Mailing_Country_AAM__r.Iso_Code__c, Mailing_Country_AAM__r.Country_Name__c,
                           OtherStreet, OtherCity, OtherCountry, Other_Country_AAM__c, Other_Country_AAM__r.Iso_Code__c, Other_Country_AAM__r.Country_Name__c
                    FROM Contact
                    WHERE Id =: UtilsTest.contact.Id ];

            System.assert( con.MailingStreet == null );
            System.assert( con.MailingCity == null );
            System.assert( con.Mailing_Country_AAM__c == null );
            System.assert( con.MailingCountry == null );
            System.assert( con.OtherStreet != null );
            System.assert( con.OtherStreet.contains( address2 ) );
            System.assert( con.OtherCity != null );
            System.assert( con.OtherCity == otherAddress.City__c );
            System.assert( con.OtherCountry != null );
            System.assert( con.OtherCountry == con.Other_Country_AAM__r.Country_Name__c );
            System.assert( con.Other_Country_AAM__c != null );
            System.assert( con.Other_Country_AAM__r.Iso_Code__c == otherAddress.Country__c );

            //delete other address (used in mappings) = deletes standard other address
            DELETE otherAddress;

            con = [ SELECT MailingStreet, MailingCity, MailingCountry, Mailing_Country_AAM__c, Mailing_Country_AAM__r.Iso_Code__c, Mailing_Country_AAM__r.Country_Name__c,
                           OtherStreet, OtherCity, OtherCountry, Other_Country_AAM__c, Other_Country_AAM__r.Iso_Code__c, Other_Country_AAM__r.Country_Name__c
                    FROM Contact
                    WHERE Id =: UtilsTest.contact.Id ];

            System.assert( con.MailingStreet == null );
            System.assert( con.MailingCity == null );
            System.assert( con.Mailing_Country_AAM__c == null );
            System.assert( con.MailingCountry == null );
            System.assert( con.MailingStreet == null );
            System.assert( con.OtherStreet == null );
            System.assert( con.OtherCity == null );
            System.assert( con.OtherCountry == null );
            System.assert( con.Other_Country_AAM__c == null );
        Test.stopTest();
    }

    @isTest static void standardAddressPopulationOnAccountDisabled() {
        CountryServices.recreateCountryMappings();
        Utils.updateCustomSettings( true );
        Aam_Settings__c aamSettings = Utils.aamSettings;
        aamSettings.Disable_Standard_Address_Population__c = true;
        UPSERT aamSettings Aam_Settings__c.Id;

        //create new billing address (used in mappings) = do not populate standard billing address (it's disabled)
        UtilsTest.amAddressType = AddressMappingServices.ADDRESS_TYPE_BILLING_ADDRESS;
        UtilsTest.amPrimary = true;
        UtilsTest.amActive = true;
        UtilsTest.createTestDataForAccount( 1 );

        Account acc = [ SELECT BillingStreet, BillingCity, BillingCountry, Billing_Country_AAM__c, Billing_Country_AAM__r.Iso_Code__c, Billing_Country_AAM__r.Country_Name__c,
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

        DELETE UtilsTest.address;

        //create new billing address (used in mappings) = populate standard billing address
        aamSettings.Disable_Standard_Address_Population__c = false;
        UPSERT aamSettings Aam_Settings__c.Id;
        UtilsTest.createTestDataForAccount( 1 );
        Id billingAddressId = UtilsTest.address.Id;

        acc = [ SELECT BillingStreet, BillingCity, BillingCountry, Billing_Country_AAM__c, Billing_Country_AAM__r.Iso_Code__c, Billing_Country_AAM__r.Country_Name__c,
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

        //update billing address (used in mappings) = noes not update standard billing address (it's disabled)
        aamSettings.Disable_Standard_Address_Population__c = true;
        UPSERT aamSettings Aam_Settings__c.Id;
        Address__c billingAddress = [ SELECT City__c, Country__c FROM Address__c WHERE Id = :billingAddressId ];
        billingAddress.City__c += billingAddress.City__c;
        billingAddress.Country__c = 'NO';
        UPDATE billingAddress;

        acc = [ SELECT BillingStreet, BillingCity, BillingCountry, Billing_Country_AAM__c, Billing_Country_AAM__r.Iso_Code__c, Billing_Country_AAM__r.Country_Name__c,
                       ShippingStreet, ShippingCity, ShippingCountry, Shipping_Country_AAM__c, Shipping_Country_AAM__r.Iso_Code__c, Shipping_Country_AAM__r.Country_Name__c
                FROM Account
                WHERE Id =: UtilsTest.account.Id ];

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

        Test.startTest();
            //create new shipping address (used in mappings) = dpo not populate standard shipping address (it's disabled)
            UtilsTest.amAddressType = AddressMappingServices.ADDRESS_TYPE_SHIPPING_ADDRESS;
            UtilsTest.aAddressLine1 += UtilsTest.aAddressLine1;
            UtilsTest.aCountry = 'PL';
            UtilsTest.createTestDataForAccount( 1 );
            Id shippingAddressId = UtilsTest.address.Id;

            acc = [ SELECT BillingStreet, BillingCity, BillingCountry, Billing_Country_AAM__c, Billing_Country_AAM__r.Iso_Code__c, Billing_Country_AAM__r.Country_Name__c,
                           ShippingStreet, ShippingCity, ShippingCountry, Shipping_Country_AAM__c, Shipping_Country_AAM__r.Iso_Code__c, Shipping_Country_AAM__r.Country_Name__c
                    FROM Account
                    WHERE Id =: UtilsTest.account.Id ];

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

            //delete billing address (used in mappings) = do not delete standard billing address (it's disabled)
            DELETE billingAddress;

            acc = [ SELECT BillingStreet, BillingCity, BillingCountry, Billing_Country_AAM__c, Billing_Country_AAM__r.Iso_Code__c, Billing_Country_AAM__r.Country_Name__c,
                           ShippingStreet, ShippingCity, ShippingCountry, Shipping_Country_AAM__c, Shipping_Country_AAM__r.Iso_Code__c, Shipping_Country_AAM__r.Country_Name__c
                    FROM Account
                    WHERE Id =: UtilsTest.account.Id ];

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

            //update shipping address (used in mappings) = updates standard shipping address,
            //does not change standard billing address, despite of the fact that it's deleted (it was done when the functionality was disabled)
            aamSettings.Disable_Standard_Address_Population__c = false;
            UPSERT aamSettings Aam_Settings__c.Id;
            Address__c shippingAddress = [ SELECT City__c, Country__c FROM Address__c WHERE Id = :shippingAddressId ];
            shippingAddress.City__c += shippingAddress.City__c;
            shippingAddress.Country__c = 'NO';
            UPDATE shippingAddress;

            acc = [ SELECT BillingStreet, BillingCity, BillingCountry, Billing_Country_AAM__c, Billing_Country_AAM__r.Iso_Code__c, Billing_Country_AAM__r.Country_Name__c,
                           ShippingStreet, ShippingCity, ShippingCountry, Shipping_Country_AAM__c, Shipping_Country_AAM__r.Iso_Code__c, Shipping_Country_AAM__r.Country_Name__c
                    FROM Account
                    WHERE Id =: UtilsTest.account.Id ];

            System.assert( acc.BillingStreet != null );
            System.assert( acc.BillingStreet.contains( address1 ) );
            System.assert( acc.BillingCity != null );
            System.assert( acc.BillingCity == UtilsTest.aCity );
            System.assert( acc.Billing_Country_AAM__c != null );
            System.assert( acc.Billing_Country_AAM__r.Iso_Code__c == country1 );
            System.assert( acc.BillingCountry != null );
            System.assert( acc.BillingCountry == acc.Billing_Country_AAM__r.Country_Name__c );
            System.assert( acc.ShippingStreet != null );
            System.assert( acc.ShippingStreet.contains( UtilsTest.aAddressLine1 ) );
            System.assert( acc.ShippingCity != null );
            System.assert( acc.ShippingCity == shippingAddress.City__c );
            System.assert( acc.ShippingCountry != null );
            System.assert( acc.ShippingCountry == acc.Shipping_Country_AAM__r.Country_Name__c );
            System.assert( acc.Shipping_Country_AAM__c != null );
            System.assert( acc.Shipping_Country_AAM__r.Iso_Code__c == shippingAddress.Country__c );
        Test.stopTest();
    }

    @isTest static void standardAddressPopulationOnContactDisabled() {
        CountryServices.recreateCountryMappings();
        Utils.updateCustomSettings( true );
        Aam_Settings__c aamSettings = Utils.aamSettings;
        aamSettings.Disable_Standard_Address_Population__c = true;
        UPSERT aamSettings Aam_Settings__c.Id;

        //create new mailing address (used in mappings) = do not populate standard mailing address (it's disabled)
        UtilsTest.amAddressType = AddressMappingServices.ADDRESS_TYPE_MAILING_ADDRESS;
        UtilsTest.amPrimary = true;
        UtilsTest.amActive = true;
        UtilsTest.createTestDataForContact( 1, 1 );

        Contact con = [ SELECT MailingStreet, MailingCity, MailingCountry, Mailing_Country_AAM__c, Mailing_Country_AAM__r.Iso_Code__c, Mailing_Country_AAM__r.Country_Name__c,
                               OtherStreet, OtherCity, OtherCountry, Other_Country_AAM__c, Other_Country_AAM__r.Iso_Code__c, Other_Country_AAM__r.Country_Name__c
                        FROM Contact
                        WHERE Id =: UtilsTest.contact.Id ];

        System.assert( con.MailingStreet == null );
        System.assert( con.MailingCity == null );
        System.assert( con.Mailing_Country_AAM__c == null );
        System.assert( con.MailingCountry == null );
        System.assert( con.OtherStreet == null );
        System.assert( con.OtherCity == null );
        System.assert( con.OtherCountry == null );
        System.assert( con.Other_Country_AAM__c == null );

        DELETE UtilsTest.address;

        //create new mailing address (used in mappings) = populate standard mailing address
        aamSettings.Disable_Standard_Address_Population__c = false;
        UPSERT aamSettings Aam_Settings__c.Id;
        UtilsTest.createAddress();
        UtilsTest.createTestDataForContact( 0, 1 );
        Id mailingAddressId = UtilsTest.address.Id;

        con = [ SELECT MailingStreet, MailingCity, MailingCountry, Mailing_Country_AAM__c, Mailing_Country_AAM__r.Iso_Code__c, Mailing_Country_AAM__r.Country_Name__c,
                       OtherStreet, OtherCity, OtherCountry, Other_Country_AAM__c, Other_Country_AAM__r.Iso_Code__c, Other_Country_AAM__r.Country_Name__c
                FROM Contact
                WHERE Id =: UtilsTest.contact.Id ];

        String address1 = UtilsTest.aAddressLine1;
        String country1 = UtilsTest.aCountry;
        System.assert( con.MailingStreet != null );
        System.assert( con.MailingStreet.contains( address1 ) );
        System.assert( con.MailingCity != null );
        System.assert( con.MailingCity == UtilsTest.aCity );
        System.assert( con.Mailing_Country_AAM__c != null );
        System.assert( con.Mailing_Country_AAM__r.Iso_Code__c == country1 );
        System.assert( con.MailingCountry != null );
        System.assert( con.MailingCountry == con.Mailing_Country_AAM__r.Country_Name__c );
        System.assert( con.OtherStreet == null );
        System.assert( con.OtherCity == null );
        System.assert( con.OtherCountry == null );
        System.assert( con.Other_Country_AAM__c == null );

        //update mailing address (used in mappings) = noes not update standard mailing address (it's disabled)
        aamSettings.Disable_Standard_Address_Population__c = true;
        UPSERT aamSettings Aam_Settings__c.Id;
        Address__c mailingAddress = [ SELECT City__c, Country__c FROM Address__c WHERE Id = :mailingAddressId ];
        mailingAddress.City__c += mailingAddress.City__c;
        mailingAddress.Country__c = 'NO';
        UPDATE mailingAddress;

        con = [ SELECT MailingStreet, MailingCity, MailingCountry, Mailing_Country_AAM__c, Mailing_Country_AAM__r.Iso_Code__c, Mailing_Country_AAM__r.Country_Name__c,
                       OtherStreet, OtherCity, OtherCountry, Other_Country_AAM__c, Other_Country_AAM__r.Iso_Code__c, Other_Country_AAM__r.Country_Name__c
                FROM Contact
                WHERE Id =: UtilsTest.contact.Id ];

        System.assert( con.MailingStreet != null );
        System.assert( con.MailingStreet.contains( address1 ) );
        System.assert( con.MailingCity != null );
        System.assert( con.MailingCity == UtilsTest.aCity );
        System.assert( con.Mailing_Country_AAM__c != null );
        System.assert( con.Mailing_Country_AAM__r.Iso_Code__c == country1 );
        System.assert( con.MailingCountry != null );
        System.assert( con.MailingCountry == con.Mailing_Country_AAM__r.Country_Name__c );
        System.assert( con.OtherStreet == null );
        System.assert( con.OtherCity == null );
        System.assert( con.OtherCountry == null );
        System.assert( con.Other_Country_AAM__c == null );

        Test.startTest();
            //create new shipping address (used in mappings) = dpo not populate standard shipping address (it's disabled)
            UtilsTest.amAddressType = AddressMappingServices.ADDRESS_TYPE_OTHER_ADDRESS;
            UtilsTest.aAddressLine1 += UtilsTest.aAddressLine1;
            UtilsTest.aCountry = 'PL';
            UtilsTest.createAddress();
            UtilsTest.createTestDataForContact( 0, 1 );
            Id shippingAddressId = UtilsTest.address.Id;

            con = [ SELECT MailingStreet, MailingCity, MailingCountry, Mailing_Country_AAM__c, Mailing_Country_AAM__r.Iso_Code__c, Mailing_Country_AAM__r.Country_Name__c,
                           OtherStreet, OtherCity, OtherCountry, Other_Country_AAM__c, Other_Country_AAM__r.Iso_Code__c, Other_Country_AAM__r.Country_Name__c
                    FROM Contact
                    WHERE Id =: UtilsTest.contact.Id ];

            System.assert( con.MailingStreet != null );
            System.assert( con.MailingStreet.contains( address1 ) );
            System.assert( con.MailingCity != null );
            System.assert( con.MailingCity == UtilsTest.aCity );
            System.assert( con.Mailing_Country_AAM__c != null );
            System.assert( con.Mailing_Country_AAM__r.Iso_Code__c == country1 );
            System.assert( con.MailingCountry != null );
            System.assert( con.MailingCountry == con.Mailing_Country_AAM__r.Country_Name__c );
            System.assert( con.OtherStreet == null );
            System.assert( con.OtherCity == null );
            System.assert( con.OtherCountry == null );
            System.assert( con.Other_Country_AAM__c == null );

            //delete mailing address (used in mappings) = do not delete standard mailing address (it's disabled)
            DELETE mailingAddress;

            con = [ SELECT MailingStreet, MailingCity, MailingCountry, Mailing_Country_AAM__c, Mailing_Country_AAM__r.Iso_Code__c, Mailing_Country_AAM__r.Country_Name__c,
                           OtherStreet, OtherCity, OtherCountry, Other_Country_AAM__c, Other_Country_AAM__r.Iso_Code__c, Other_Country_AAM__r.Country_Name__c
                    FROM Contact
                    WHERE Id =: UtilsTest.contact.Id ];

            System.assert( con.MailingStreet != null );
            System.assert( con.MailingStreet.contains( address1 ) );
            System.assert( con.MailingCity != null );
            System.assert( con.MailingCity == UtilsTest.aCity );
            System.assert( con.Mailing_Country_AAM__c != null );
            System.assert( con.Mailing_Country_AAM__r.Iso_Code__c == country1 );
            System.assert( con.MailingCountry != null );
            System.assert( con.MailingCountry == con.Mailing_Country_AAM__r.Country_Name__c );
            System.assert( con.OtherStreet == null );
            System.assert( con.OtherCity == null );
            System.assert( con.OtherCountry == null );
            System.assert( con.Other_Country_AAM__c == null );

            //update shipping address (used in mappings) = updates standard shipping address,
            //does not change standard mailing address, despite of the fact that it's deleted (it was done when the functionality was disabled)
            aamSettings.Disable_Standard_Address_Population__c = false;
            UPSERT aamSettings Aam_Settings__c.Id;
            Address__c shippingAddress = [ SELECT City__c, Country__c FROM Address__c WHERE Id = :shippingAddressId ];
            shippingAddress.City__c += shippingAddress.City__c;
            shippingAddress.Country__c = 'NO';
            UPDATE shippingAddress;

            con = [ SELECT MailingStreet, MailingCity, MailingCountry, Mailing_Country_AAM__c, Mailing_Country_AAM__r.Iso_Code__c, Mailing_Country_AAM__r.Country_Name__c,
                           OtherStreet, OtherCity, OtherCountry, Other_Country_AAM__c, Other_Country_AAM__r.Iso_Code__c, Other_Country_AAM__r.Country_Name__c
                    FROM Contact
                    WHERE Id =: UtilsTest.contact.Id ];

            System.assert( con.MailingStreet != null );
            System.assert( con.MailingStreet.contains( address1 ) );
            System.assert( con.MailingCity != null );
            System.assert( con.MailingCity == UtilsTest.aCity );
            System.assert( con.Mailing_Country_AAM__c != null );
            System.assert( con.Mailing_Country_AAM__r.Iso_Code__c == country1 );
            System.assert( con.MailingCountry != null );
            System.assert( con.MailingCountry == con.Mailing_Country_AAM__r.Country_Name__c );
            System.assert( con.OtherStreet != null );
            System.assert( con.OtherStreet.contains( UtilsTest.aAddressLine1 ) );
            System.assert( con.OtherCity != null );
            System.assert( con.OtherCity == shippingAddress.City__c );
            System.assert( con.OtherCountry != null );
            System.assert( con.OtherCountry == con.Other_Country_AAM__r.Country_Name__c );
            System.assert( con.Other_Country_AAM__c != null );
            System.assert( con.Other_Country_AAM__r.Iso_Code__c == shippingAddress.Country__c );
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
        Id billingAddressId = UtilsTest.address.Id;

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
        Id visitingAddressId = UtilsTest.address.Id;

        acc = [ SELECT BillingStreet, BillingCity, BillingCountry, Billing_Country_AAM__c, Billing_Country_AAM__r.Iso_Code__c, Billing_Country_AAM__r.Country_Name__c,
                       ShippingStreet, ShippingCity, ShippingCountry, Shipping_Country_AAM__c, Shipping_Country_AAM__r.Iso_Code__c, Shipping_Country_AAM__r.Country_Name__c
                FROM Account
                WHERE Id =: UtilsTest.account.Id ];

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

        Test.startTest();
            //update visiting address (mapped = changes standard fields)
            Aam_Settings__c aamSettings = Utils.aamSettings;
            aamSettings.Acc_Billing_Addr_Source__c = AddressMappingServices.ADDRESS_TYPE_VISITING_ADDRESS;
            UPSERT aamSettings Aam_Settings__c.Id;
            AddressMappingServices.objectNameToFieldToAddressType = null; //reset static variable to repopulate correct settings

            Address__c visitingAddress = [ SELECT City__c, Country__c FROM Address__c WHERE Id = :visitingAddressId ];
            visitingAddress.City__c += visitingAddress.City__c;
            visitingAddress.Country__c = 'LU';
            UPDATE visitingAddress;

            acc = [ SELECT BillingStreet, BillingCity, BillingCountry, Billing_Country_AAM__c, Billing_Country_AAM__r.Iso_Code__c, Billing_Country_AAM__r.Country_Name__c,
                           ShippingStreet, ShippingCity, ShippingCountry, Shipping_Country_AAM__c, Shipping_Country_AAM__r.Iso_Code__c, Shipping_Country_AAM__r.Country_Name__c
                    FROM Account
                    WHERE Id =: UtilsTest.account.Id ];

            System.assert( acc.BillingStreet != null );
            System.assert( acc.BillingStreet.contains( address1 ) );
            System.assert( acc.BillingCity != null );
            System.assert( acc.BillingCity == visitingAddress.City__c );
            System.assert( acc.Billing_Country_AAM__c != null );
            System.assert( acc.Billing_Country_AAM__r.Iso_Code__c == visitingAddress.Country__c );
            System.assert( acc.BillingCountry != null );
            System.assert( acc.BillingCountry == acc.Billing_Country_AAM__r.Country_Name__c );
            System.assert( acc.ShippingStreet == null );
            System.assert( acc.ShippingCity == null );
            System.assert( acc.ShippingCountry == null );
            System.assert( acc.Shipping_Country_AAM__c == null );

            //delete billing address (unmapped = does nothing)
            DELETE new Address__c( Id = billingAddressId );

            acc = [ SELECT BillingStreet, BillingCity, BillingCountry, Billing_Country_AAM__c, Billing_Country_AAM__r.Iso_Code__c, Billing_Country_AAM__r.Country_Name__c,
                           ShippingStreet, ShippingCity, ShippingCountry, Shipping_Country_AAM__c, Shipping_Country_AAM__r.Iso_Code__c, Shipping_Country_AAM__r.Country_Name__c
                    FROM Account
                    WHERE Id =: UtilsTest.account.Id ];

            System.assert( acc.BillingStreet != null );
            System.assert( acc.BillingStreet.contains( address1 ) );
            System.assert( acc.BillingCity != null );
            System.assert( acc.BillingCity == visitingAddress.City__c );
            System.assert( acc.Billing_Country_AAM__c != null );
            System.assert( acc.Billing_Country_AAM__r.Iso_Code__c == visitingAddress.Country__c );
            System.assert( acc.BillingCountry != null );
            System.assert( acc.BillingCountry == acc.Billing_Country_AAM__r.Country_Name__c );
            System.assert( acc.ShippingStreet == null );
            System.assert( acc.ShippingCity == null );
            System.assert( acc.ShippingCountry == null );
            System.assert( acc.Shipping_Country_AAM__c == null );

            //delete visiting address (mapped = changes standard fields)
            DELETE visitingAddress;
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

    @isTest static void setStandardFieldsForAddresses() {
        CountryServices.recreateCountryMappings();
        Utils.updateCustomSettings( true );

        Aam_Settings__c aamSettings = Utils.aamSettings;
        aamSettings.Cont_Mailing_Addr_Source__c = AddressMappingServices.ADDRESS_TYPE_BILLING_ADDRESS;
        UPSERT aamSettings Aam_Settings__c.Id;

        UtilsTest.amAddressType = AddressMappingServices.ADDRESS_TYPE_BILLING_ADDRESS;
        UtilsTest.amPrimary = true;
        UtilsTest.amActive = true;
        UtilsTest.createTestDataForContact( 1, 1 );

        Set<Id> addressIds = new Set<Id>{ UtilsTest.address.Id };

        Account acc = UtilsTest.account;
        acc.BillingStreet = null;
        acc.BillingCity = null;
        acc.Billing_Country_AAM__c = null;
        acc.BillingCountry = null;
        UPDATE acc;

        Contact con = UtilsTest.contact;
        con.MailingStreet = null;
        con.MailingCity = null;
        con.Mailing_Country_AAM__c = null;
        con.MailingCountry = null;
        UPDATE con;

        Test.startTest();
            AddressServices.setStandardAddresses( addressIds );
        Test.stopTest();

        acc = [ SELECT BillingStreet, BillingCity, BillingCountry, Billing_Country_AAM__c, Billing_Country_AAM__r.Iso_Code__c, Billing_Country_AAM__r.Country_Name__c
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

        con = [ SELECT MailingStreet, MailingCity, MailingCountry, Mailing_Country_AAM__c, Mailing_Country_AAM__r.Iso_Code__c, Mailing_Country_AAM__r.Country_Name__c
                FROM Contact
                WHERE Id =: UtilsTest.contact.Id ];

        System.assert( con.MailingStreet != null );
        System.assert( con.MailingStreet.contains( UtilsTest.aAddressLine1 ) );
        System.assert( con.MailingCity != null );
        System.assert( con.MailingCity == UtilsTest.aCity );
        System.assert( con.Mailing_Country_AAM__c != null );
        System.assert( con.Mailing_Country_AAM__r.Iso_Code__c == UtilsTest.aCountry );
        System.assert( con.MailingCountry != null );
        System.assert( con.MailingCountry == con.Mailing_Country_AAM__r.Country_Name__c );
    }

    @isTest static void setStandardFieldsForAccounts() {
        CountryServices.recreateCountryMappings();
        Utils.updateCustomSettings( true );

        UtilsTest.amAddressType = AddressMappingServices.ADDRESS_TYPE_BILLING_ADDRESS;
        UtilsTest.amPrimary = true;
        UtilsTest.amActive = true;
        UtilsTest.createTestDataForAccount( 1 );

        Account acc = UtilsTest.account;
        acc.BillingStreet = null;
        acc.BillingCity = null;
        acc.Billing_Country_AAM__c = null;
        acc.BillingCountry = null;
        UPDATE acc;

        Test.startTest();
            AddressServices.setStandardAddresses( new Set<Id>{ UtilsTest.account.Id } );
        Test.stopTest();

        acc = [ SELECT BillingStreet, BillingCity, BillingCountry, Billing_Country_AAM__c, Billing_Country_AAM__r.Iso_Code__c, Billing_Country_AAM__r.Country_Name__c
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
    }

    @isTest static void setStandardFieldsForContacts() {
        CountryServices.recreateCountryMappings();
        Utils.updateCustomSettings( true );

        UtilsTest.amAddressType = AddressMappingServices.ADDRESS_TYPE_MAILING_ADDRESS;
        UtilsTest.amPrimary = true;
        UtilsTest.amActive = true;
        UtilsTest.createTestDataForContact( 1, 1 );

        Contact con = UtilsTest.contact;
        con.MailingStreet = null;
        con.MailingCity = null;
        con.Mailing_Country_AAM__c = null;
        con.MailingCountry = null;
        UPDATE con;

        Test.startTest();
            AddressServices.setStandardAddresses( new Set<Id>{ UtilsTest.contact.Id } );
        Test.stopTest();

        con = [ SELECT MailingStreet, MailingCity, MailingCountry, Mailing_Country_AAM__c, Mailing_Country_AAM__r.Iso_Code__c, Mailing_Country_AAM__r.Country_Name__c
                FROM Contact
                WHERE Id =: UtilsTest.contact.Id ];

        System.assert( con.MailingStreet != null );
        System.assert( con.MailingStreet.contains( UtilsTest.aAddressLine1 ) );
        System.assert( con.MailingCity != null );
        System.assert( con.MailingCity == UtilsTest.aCity );
        System.assert( con.Mailing_Country_AAM__c != null );
        System.assert( con.Mailing_Country_AAM__r.Iso_Code__c == UtilsTest.aCountry );
        System.assert( con.MailingCountry != null );
        System.assert( con.MailingCountry == con.Mailing_Country_AAM__r.Country_Name__c );
    }

    // + GW-154
    @isTest static void reparentAddressToTopLevelAccount() {
        Account parentAccount = UtilsTest.createAccount( true );
        Account childAccount = UtilsTest.createAccount( false );
        childAccount.ParentId = parentAccount.Id;
        INSERT childAccount;

        Test.startTest();
            UtilsTest.createTestDataForAccount( 1 );
        Test.stopTest();

        Address__c address = UtilsTest.address;
        System.assert( address != null );
        System.assertEquals( childAccount.Id, address.Account__c );

        address = [ SELECT Account__c FROM Address__c WHERE Id = :address.Id ];
        System.assertEquals( parentAccount.Id, address.Account__c );
    }

}