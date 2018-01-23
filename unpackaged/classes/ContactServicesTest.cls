@isTest
private class ContactServicesTest {

    @isTest static void reparentContactSameHierarchy() {
        Utils.updateCustomSettings( true );

        Account accParent = new Account( Name = 'accParent' );
        INSERT accParent;

        Account accChild = new Account( Name = 'accChild', ParentId = accParent.Id );
        INSERT accChild;

        Address__c address = new Address__c( Account__c = accChild.Id,
                                             Address_Line_1__c = 'test',
                                             City__c = 'test',
                                             Status__c = 'Active' );
        INSERT address;

        Contact contact = new Contact( LastName = 'test',
                                       AccountId = accChild.Id );
        INSERT contact;

        Address_Mapping__c addressMapping = new Address_Mapping__c( Address__c = address.Id,
                                                                    Contact__c = contact.Id,
                                                                    Address_Type__c = AddressMappingServices.ADDRESS_TYPE_MAILING_ADDRESS,
                                                                    Active__c = true,
                                                                    Primary__c = true );
        INSERT addressMapping;

        Test.startTest();
            UPDATE new Contact( Id = contact.Id, AccountId = accParent.Id );
        Test.stopTest();

        List<Address_Mapping__c> addressMappingDb = [ SELECT Address__c
                                                      FROM Address_Mapping__c ];

        System.assert( !addressMappingDb.isEmpty() );
        System.assert( addressMappingDb.size() == 1 );
        System.assert( addressMappingDb[0].Address__c == address.Id );
    }

    // - GW-154
    /*@isTest static void reparentContactDifferentHierarchyAddressDoesNotExist() {
        Utils.updateCustomSettings( true );

        Account accParent1 = new Account( Name = 'accParent1' );
        INSERT accParent1;

        Account accChild1 = new Account( Name = 'accChild1', ParentId = accParent1.Id );
        INSERT accChild1;

        Address__c address1 = new Address__c( Account__c = accChild1.Id,
                                              Address_Line_1__c = 'test',
                                              City__c = 'test',
                                              Status__c = 'Active' );
        INSERT address1;

        Contact contact = new Contact( LastName = 'test',
                                       AccountId = accChild1.Id );
        INSERT contact;

        Address_Mapping__c addressMapping = new Address_Mapping__c( Address__c = address1.Id,
                                                                    Contact__c = contact.Id,
                                                                    Address_Type__c = AddressMappingServices.ADDRESS_TYPE_MAILING_ADDRESS,
                                                                    Active__c = true,
                                                                    Primary__c = true );
        INSERT addressMapping;

        Account accParent2 = new Account( Name = 'accParent2' );
        INSERT accParent2;

        Account accChild2 = new Account( Name = 'accChild2', ParentId = accParent2.Id );
        INSERT accChild2;

        Address__c address2 = new Address__c( Account__c = accParent2.Id,
                                              Address_Line_1__c = address1.Address_Line_1__c + 'test',
                                              City__c = address1.City__c + 'test',
                                              Status__c = 'Active' );
        INSERT address2;

        Test.startTest();
            UPDATE new Contact( Id = contact.Id, AccountId = accParent2.Id );
        Test.stopTest();

        List<Address_Mapping__c> addressMappingDb = [ SELECT Address__c
                                                      FROM Address_Mapping__c ];
        System.assert( !addressMappingDb.isEmpty() );
        System.assert( addressMappingDb.size() == 1 );

        List<Address__c> addresses = [ SELECT Account__c, Address_Line_1__c, City__c, Status__c
                                       FROM Address__c ];
        System.assert( !addresses.isEmpty() );
        System.assert( addresses.size() == 3 );
        for( Address__c address : addresses ) {
            if( address.Id == address1.Id || address.Id == address2.Id ) {
                System.assert( address.Id != addressMappingDb[0].Address__c );
            } else {
                System.assert( address.Id == addressMappingDb[0].Address__c );
                System.assert( address.Account__c == accParent2.Id );
                System.assert( address.Address_Line_1__c == address1.Address_Line_1__c );
                System.assert( address.City__c == address1.City__c );
                System.assert( address.Status__c == address1.Status__c );
            }
        }
    }*/

    // + GW-154
    @isTest static void reparentContactDifferentHierarchyAddressDoesNotExist() {
        Utils.updateCustomSettings( true );

        Account accParent1 = new Account( Name = 'accParent1' );
        INSERT accParent1;

        Account accChild1 = new Account( Name = 'accChild1', ParentId = accParent1.Id );
        INSERT accChild1;

        Address__c address1 = new Address__c( Account__c = accChild1.Id,
                                              Address_Line_1__c = 'test',
                                              City__c = 'test',
                                              Status__c = 'Active' );
        INSERT address1;

        Contact contact = new Contact( LastName = 'test',
                                       AccountId = accChild1.Id );
        INSERT contact;

        Address_Mapping__c addressMapping = new Address_Mapping__c( Address__c = address1.Id,
                                                                    Contact__c = contact.Id,
                                                                    Address_Type__c = AddressMappingServices.ADDRESS_TYPE_MAILING_ADDRESS,
                                                                    Active__c = true,
                                                                    Primary__c = true );
        INSERT addressMapping;

        Account accParent2 = new Account( Name = 'accParent2' );
        INSERT accParent2;

        Account accChild2 = new Account( Name = 'accChild2', ParentId = accParent2.Id );
        INSERT accChild2;

        Address__c address2 = new Address__c( Account__c = accParent2.Id,
                                              Address_Line_1__c = address1.Address_Line_1__c + 'test',
                                              City__c = address1.City__c + 'test',
                                              Status__c = 'Active' );
        INSERT address2;

        Test.startTest();
            UPDATE new Contact( Id = contact.Id, AccountId = accChild2.Id );
        Test.stopTest();

        List<Address_Mapping__c> addressMappingDb = [ SELECT Address__c
                                                      FROM Address_Mapping__c ];
        System.assert( !addressMappingDb.isEmpty() );
        System.assert( addressMappingDb.size() == 1 );

        List<Address__c> addresses = [ SELECT Account__c, Address_Line_1__c, City__c, Status__c
                                       FROM Address__c ];
        System.assert( !addresses.isEmpty() );
        System.assert( addresses.size() == 3 );
        for( Address__c address : addresses ) {
            if( address.Id == address1.Id || address.Id == address2.Id ) {
                System.assert( address.Id != addressMappingDb[0].Address__c );
            } else {
                System.assert( address.Id == addressMappingDb[0].Address__c );
                System.assert( address.Account__c == accParent2.Id );
                System.assert( address.Address_Line_1__c == address1.Address_Line_1__c );
                System.assert( address.City__c == address1.City__c );
                System.assert( address.Status__c == address1.Status__c );
            }
        }
    }

    @isTest static void reparentContactDifferentHierarchyAddressExists() {
        Utils.updateCustomSettings( true );

        Account accParent1 = new Account( Name = 'accParent1' );
        INSERT accParent1;

        Account accChild1 = new Account( Name = 'accChild1', ParentId = accParent1.Id );
        INSERT accChild1;

        Address__c address1 = new Address__c( Account__c = accChild1.Id,
                                              Address_Line_1__c = 'test',
                                              City__c = 'test',
                                              Status__c = 'Active' );
        INSERT address1;

        Contact contact = new Contact( LastName = 'test',
                                       AccountId = accChild1.Id );
        INSERT contact;

        Address_Mapping__c addressMapping = new Address_Mapping__c( Address__c = address1.Id,
                                                                    Contact__c = contact.Id,
                                                                    Address_Type__c = AddressMappingServices.ADDRESS_TYPE_MAILING_ADDRESS,
                                                                    Active__c = true,
                                                                    Primary__c = true );
        INSERT addressMapping;

        Account accParent2 = new Account( Name = 'accParent2' );
        INSERT accParent2;

        Account accChild2 = new Account( Name = 'accChild2', ParentId = accParent2.Id );
        INSERT accChild2;

        Address__c address2 = address1.clone( false );
        address2.Account__c = accChild2.Id;
        INSERT address2;

        Test.startTest();
            UPDATE new Contact( Id = contact.Id, AccountId = accParent2.Id );
        Test.stopTest();

        List<Address_Mapping__c> addressMappingDb = [ SELECT Address__c
                                                      FROM Address_Mapping__c ];
        System.assert( !addressMappingDb.isEmpty() );
        System.assert( addressMappingDb.size() == 1 );

        List<Address__c> addresses = [ SELECT Account__c, Address_Line_1__c, City__c, Status__c
                                       FROM Address__c ];
        System.assert( !addresses.isEmpty() );
        System.assert( addresses.size() == 2 );
        for( Address__c address : addresses ) {
            if( address.Id == address2.Id ) {
                System.assert( address.Id == addressMappingDb[0].Address__c );
            } else {
                System.assert( address.Id != addressMappingDb[0].Address__c );
            }
        }
    }

    @isTest static void reparentContactRemapDisabled() {
        Utils.updateCustomSettings( true );
        Utils.aamSettings.Disable_Contact_Reparenting_Function__c = true;
        UPSERT Utils.aamSettings Aam_Settings__c.Id;

        Account accParent1 = new Account( Name = 'accParent1' );
        INSERT accParent1;

        Account accChild1 = new Account( Name = 'accChild1', ParentId = accParent1.Id );
        INSERT accChild1;

        Address__c address1 = new Address__c( Account__c = accChild1.Id,
                                              Address_Line_1__c = 'test',
                                              City__c = 'test',
                                              Status__c = 'Active' );
        INSERT address1;

        Contact contact = new Contact( LastName = 'test',
                                       AccountId = accChild1.Id );
        INSERT contact;

        Address_Mapping__c addressMapping = new Address_Mapping__c( Address__c = address1.Id,
                                                                    Contact__c = contact.Id,
                                                                    Address_Type__c = AddressMappingServices.ADDRESS_TYPE_MAILING_ADDRESS,
                                                                    Active__c = true,
                                                                    Primary__c = true );
        INSERT addressMapping;

        Account accParent2 = new Account( Name = 'accParent2' );
        INSERT accParent2;

        Test.startTest();
            UPDATE new Contact( Id = contact.Id, AccountId = accParent2.Id );
        Test.stopTest();

        List<Address_Mapping__c> addressMappingDb = [ SELECT Address__c
                                                      FROM Address_Mapping__c ];
        System.assert( !addressMappingDb.isEmpty() );
        System.assert( addressMappingDb.size() == 1 );

        List<Address__c> addresses = [ SELECT Account__c, Address_Line_1__c, City__c, Status__c
                                       FROM Address__c ];
        System.assert( !addresses.isEmpty() );
        System.assert( addresses.size() == 1 );
        for( Address__c address : addresses ) {
            if( address.Id == address1.Id ) {
                System.assert( address.Id == addressMappingDb[0].Address__c );
            } else {
                System.assert( address.Id != addressMappingDb[0].Address__c );
            }
        }
    }
    //added by chris chen 2017/07/18
    @isTest static void copyAccountAddressMappingsToNewContact() {
        Utils.updateCustomSettings( true );
        Utils.aamSettings.Disable_Contact_Reparenting_Function__c = true;
        Utils.aamSettings.Pull_Account_Addresses_Re_Parent_Contact__c = true;
        Utils.aamSettings.Pull_Account_Address_Creation_Contact__c = true;
    	UPSERT Utils.aamSettings Aam_Settings__c.Id;
        Account accParent1 = new Account( Name = 'accParent1' );
        INSERT accParent1;

        Account accChild1 = new Account( Name = 'accChild1', ParentId = accParent1.Id );
        INSERT accChild1;

        Address__c address1 = new Address__c( Account__c = accChild1.Id,
                                              Address_Line_1__c = 'test',
                                              City__c = 'test',
                                              Status__c = 'Active' );
		INSERT address1;                                               
        Address_Mapping__c addressMapping1 = new Address_Mapping__c( Address__c = address1.Id,
                                                                    Account__c = accChild1.Id,
                                                                    Address_Type__c = AddressMappingServices.ADDRESS_TYPE_BILLING_ADDRESS,
                                                                    Active__c = true,
                                                                    Primary__c = true );
                                              
        Address_Mapping__c addressMapping2 = new Address_Mapping__c( Address__c = address1.Id,
                                                                    Account__c = accChild1.Id,
                                                                    Address_Type__c = AddressMappingServices.ADDRESS_TYPE_MAILING_ADDRESS,
                                                                    Active__c = true,
                                                                    Primary__c = true );
		INSERT addressMapping1;
		INSERT addressMapping2;
		                                                                    
        Contact contact = new Contact( LastName = 'test',
                                       AccountId = accChild1.Id );
        INSERT contact;
		                                              
    }
    @isTest static void copyAccountAddressMappingsToReparentedContact() {
        Utils.updateCustomSettings( true );
        Utils.aamSettings.Disable_Contact_Reparenting_Function__c = true;
        Utils.aamSettings.Pull_Account_Addresses_Re_Parent_Contact__c = true;
        Utils.aamSettings.Pull_Account_Address_Creation_Contact__c = true;
    	UPSERT Utils.aamSettings Aam_Settings__c.Id;
        Account accParent1 = new Account( Name = 'accParent1' );
        //INSERT accParent1;
		Account accParent2 = new Account( Name = 'accParent2' );
        //INSERT accParent2;
        List<Account> accParents = new List<Account>();
        accParents.add(accParent1);
        accParents.add(accParent2);
        INSERT accParents;

        Account accChild1 = new Account( Name = 'accChild1', ParentId = accParent1.Id );
        INSERT accChild1;

        Address__c address1 = new Address__c( Account__c = accChild1.Id,
                                              Address_Line_1__c = 'test1',
                                              City__c = 'test1',
                                              Status__c = 'Active' );
		//INSERT address1;                                               

        Address__c address2 = new Address__c( Account__c = accChild1.Id,
                                              Address_Line_1__c = 'test2',
                                              City__c = 'test2',
                                              Status__c = 'Active' );
        //INSERT address2;
		List<Address__c> addresses = new List<Address__c>();
		addresses.add(address1);
		addresses.add(address2);
		INSERT addresses;
		
        Address_Mapping__c addressMapping1 = new Address_Mapping__c( Address__c = address1.Id,
                                                                    Account__c = accChild1.Id,
                                                                    Address_Type__c = AddressMappingServices.ADDRESS_TYPE_BILLING_ADDRESS,
                                                                    Active__c = true,
                                                                    Primary__c = true );
                                              
        Address_Mapping__c addressMapping2 = new Address_Mapping__c( Address__c = address1.Id,
                                                                    Account__c = accChild1.Id,
                                                                    Address_Type__c = AddressMappingServices.ADDRESS_TYPE_MAILING_ADDRESS,
                                                                    Active__c = true,
                                                                    Primary__c = true );
		
        Address_Mapping__c addressMapping3 = new Address_Mapping__c( Address__c = address2.Id,
                                                                    Account__c = accParent2.Id,
                                                                    Address_Type__c = AddressMappingServices.ADDRESS_TYPE_BILLING_ADDRESS,
                                                                    Active__c = true,
                                                                    Primary__c = true );
                                              
        Address_Mapping__c addressMapping4 = new Address_Mapping__c( Address__c = address2.Id,
                                                                    Account__c = accParent2.Id,
                                                                    Address_Type__c = AddressMappingServices.ADDRESS_TYPE_MAILING_ADDRESS,
                                                                    Active__c = true,
                                                                    Primary__c = true );
		List<Address_Mapping__c> addressMappings = new List<Address_Mapping__c>();
		addressMappings.add(addressMapping1);	                                                                    
		addressMappings.add(addressMapping2);	                                                                    
		addressMappings.add(addressMapping3);	                                                                    
		addressMappings.add(addressMapping4);	                                                                    
		INSERT addressMappings;
		       
        Contact contact = new Contact( LastName = 'test', AccountId = accParent2.Id);
        INSERT contact;
        
        contact.AccountId = accChild1.Id;
        UPSERT contact;
    }
}