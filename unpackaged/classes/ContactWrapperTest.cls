@isTest
private class ContactWrapperTest {

    @isTest static void areAllContactsSelected() {
        UtilsTest.createTestDataForContact( 1, 1 );

        List<ContactWrapper> contactWrappers = new List<ContactWrapper>();
        contactWrappers.add( new ContactWrapper( UtilsTest.contact ) );
        for( ContactWrapper contactWrapper : contactWrappers ) {
            contactWrapper.setSelected( true );
        }

        Boolean areAllContactsSelected;

        Test.startTest();
            areAllContactsSelected = ContactWrapper.areAllContactsSelected( contactWrappers );
        Test.stopTest();

        System.assert( areAllContactsSelected == true );
    }

    @isTest static void getFilteredContactsNew() {
        UtilsTest.createTestDataForContact( 1, 1 );

        List<ContactWrapper> filteredContactsNew;

        String query = 'SELECT ' + String.join(
                                       new List<String>(
                                           Utils.getFieldsFromFieldSet(
                                               Utils.joinFieldsInFieldSets(
                                                   SObjectType.Contact.FieldSets.New_Address_Selected_Contacts_Fields.getFields(),
                                                   null
                                               ),
                                               new List<Schema.SObjectField>{ Contact.Name },
                                               true
                                           )
                                       ), ', '
                                   ) + ' ';
        query += 'FROM Contact ';
        query += 'WHERE AccountId = \'' + UtilsTest.account.Id + '\' ';
        Contact contactNew = (Contact)Database.query( query )[0];
        ContactWrapper contactNewWrapper = new ContactWrapper( contactNew );
        contactNewWrapper.setSelected( true, UtilsTest.addressMappingsContact[0] );


        Test.startTest();
            filteredContactsNew = ContactWrapper.getFilteredContacts(
                new List<ContactWrapper>{ contactNewWrapper },
                UserInfo.getName(),
                SObjectType.Contact.FieldSets.New_Address_Selected_Contacts_Fields.getFields()
            );
        Test.stopTest();

        System.assert( filteredContactsNew != null );
    }

    @isTest static void getFilteredContactsMgmt() {
        UtilsTest.createTestDataForContact( 1, 1 );

        List<ContactWrapper> filteredContactsMgmt;

        String query = 'SELECT ' + String.join(
                                       new List<String>(
                                           Utils.getFieldsFromFieldSet(
                                               Utils.joinFieldsInFieldSets(
                                                   SObjectType.Contact.FieldSets.Manage_Address_Selected_Contacts_Fields.getFields(),
                                                   null
                                               ),
                                               new List<Schema.SObjectField>{ Contact.Name },
                                               true
                                           )
                                       ), ', '
                                   ) + ' ';
        query += 'FROM Contact ';
        query += 'WHERE AccountId = \'' + UtilsTest.account.Id + '\' ';
        Contact contactMgmt = (Contact)Database.query( query )[0];
        ContactWrapper contactMgmtWrapper = new ContactWrapper( contactMgmt );
        contactMgmtWrapper.setSelected( true, UtilsTest.addressMappingsContact[0] );


        Test.startTest();
            filteredContactsMgmt = ContactWrapper.getFilteredContacts(
                new List<ContactWrapper>{ new ContactWrapper( UtilsTest.contact ) },
                'test',
                SObjectType.Contact.FieldSets.Manage_Address_Selected_Contacts_Fields.getFields()
            );
        Test.stopTest();

        System.assert( filteredContactsMgmt != null );
    }

    @isTest static void getFilteredContactsDeact() {
        UtilsTest.createTestDataForContact( 1, 1 );

        List<ContactWrapper> filteredContactsDeact;

        String query = 'SELECT ' + String.join(
                                       new List<String>(
                                           Utils.getFieldsFromFieldSet(
                                               Utils.joinFieldsInFieldSets(
                                                   SObjectType.Contact.FieldSets.Deactivate_Address_Selected_Contacts_Fie.getFields(),
                                                   null
                                               ),
                                               new List<Schema.SObjectField>{ Contact.Name },
                                               true
                                           )
                                       ), ', '
                                   ) + ' ';
        query += 'FROM Contact ';
        query += 'WHERE AccountId = \'' + UtilsTest.account.Id + '\' ';
        Contact contactDeact = (Contact)Database.query( query )[0];
        ContactWrapper contactDeactWrapper = new ContactWrapper( contactDeact );
        contactDeactWrapper.setSelected( true, UtilsTest.addressMappingsContact[0] );

        Test.startTest();
            filteredContactsDeact = ContactWrapper.getFilteredContacts(
                new List<ContactWrapper>{ new ContactWrapper( UtilsTest.contact ) },
                'test',
                SObjectType.Contact.FieldSets.Deactivate_Address_Selected_Contacts_Fie.getFields()
            );
        Test.stopTest();

        System.assert( filteredContactsDeact != null );
    }

    @isTest static void getFilteredContactsForSelectedContactsByAddressNew() {
        UtilsTest.createTestDataForContact( 1, 1 );

        List<ContactWrapper> filteredContactsNew;

        Test.startTest();
            ContactWrapper contactNew = new ContactWrapper( UtilsTest.contact );
            contactNew.setSelected( true, UtilsTest.addressMappingsContact[0] );
            filteredContactsNew = ContactWrapper.getFilteredContactsForSelectedContacts(
                new List<ContactWrapper>{ contactNew },
                'test',
                UtilsTest.address,
                SObjectType.Contact.FieldSets.New_Address_Selected_Contacts_Fields.getFields(),
                SObjectType.Address_Mapping__c.FieldSets.New_Address_Selected_Contacts_Fields.getFields()
            );
        Test.stopTest();

        System.assert( filteredContactsNew != null );
    }

    @isTest static void getFilteredContactsForSelectedContactsByAddressMgmt() {
        UtilsTest.createTestDataForContact( 1, 1 );

        List<ContactWrapper> filteredContactsMgmt;

        Test.startTest();
            ContactWrapper contactMgmt = new ContactWrapper( UtilsTest.contact );
            contactMgmt.setSelected( true, UtilsTest.addressMappingsContact[0] );
            filteredContactsMgmt = ContactWrapper.getFilteredContactsForSelectedContacts(
                new List<ContactWrapper>{ contactMgmt },
                'test',
                UtilsTest.address,
                SObjectType.Contact.FieldSets.Manage_Address_Selected_Contacts_Fields.getFields(),
                SObjectType.Address_Mapping__c.FieldSets.Manage_Address_Selected_Contacts_Fields.getFields()
            );
        Test.stopTest();

        System.assert( filteredContactsMgmt != null );
    }

    @isTest static void getFilteredContactsForSelectedContactsByAddressDeact() {
        UtilsTest.createTestDataForContact( 1, 1 );

        List<ContactWrapper> filteredContactsDeact;

        Test.startTest();
            ContactWrapper contactDeact = new ContactWrapper( UtilsTest.contact );
            contactDeact.setSelected( true, UtilsTest.addressMappingsContact[0] );
            filteredContactsDeact = ContactWrapper.getFilteredContactsForSelectedContacts(
                new List<ContactWrapper>{ contactDeact },
                'test',
                UtilsTest.address,
                SObjectType.Contact.FieldSets.Deactivate_Address_Selected_Contacts_Fie.getFields(),
                SObjectType.Address_Mapping__c.FieldSets.Deactivate_Address_Selected_Contacts_Fie.getFields()
            );
        Test.stopTest();

        System.assert( filteredContactsDeact != null );
    }

    @isTest static void getFilteredContactsForSelectedContactsByOwnerNew() {
        UtilsTest.createTestDataForContact( 1, 1 );

        List<ContactWrapper> filteredContactsNew;

        String query = 'SELECT ' + String.join(
                                       new List<String>(
                                           Utils.getFieldsFromFieldSet(
                                               Utils.joinFieldsInFieldSets(
                                                   SObjectType.Contact.FieldSets.New_Address_Selected_Contacts_Fields.getFields(),
                                                   null
                                               ),
                                               new List<Schema.SObjectField>{ Contact.Name },
                                               true
                                           )
                                       ), ', '
                                   ) + ' ';
        query += 'FROM Contact ';
        query += 'WHERE AccountId = \'' + UtilsTest.account.Id + '\' ';
        Contact contactNew = (Contact)Database.query( query )[0];
        ContactWrapper contactNewWrapper = new ContactWrapper( contactNew );
        contactNewWrapper.setSelected( true, UtilsTest.addressMappingsContact[0] );

        Test.startTest();
            filteredContactsNew = ContactWrapper.getFilteredContactsForSelectedContacts(
                new List<ContactWrapper>{ contactNewWrapper },
                UserInfo.getName(),
                UtilsTest.address,
                SObjectType.Contact.FieldSets.New_Address_Selected_Contacts_Fields.getFields(),
                SObjectType.Address_Mapping__c.FieldSets.New_Address_Selected_Contacts_Fields.getFields()
            );
        Test.stopTest();

        System.assert( filteredContactsNew != null );
    }

    @isTest static void getFilteredContactsForSelectedContactsByOwnerMgmt() {
        UtilsTest.createTestDataForContact( 1, 1 );

        List<ContactWrapper> filteredContactsMgmt;

        String query = 'SELECT ' + String.join(
                                       new List<String>(
                                           Utils.getFieldsFromFieldSet(
                                               Utils.joinFieldsInFieldSets(
                                                   SObjectType.Contact.FieldSets.Manage_Address_Selected_Contacts_Fields.getFields(),
                                                   null
                                               ),
                                               new List<Schema.SObjectField>{ Contact.Name },
                                               true
                                           )
                                       ), ', '
                                   ) + ' ';
        query += 'FROM Contact ';
        query += 'WHERE AccountId = \'' + UtilsTest.account.Id + '\' ';
        Contact contactMgmt = (Contact)Database.query( query )[0];
        ContactWrapper contactMgmtWrapper = new ContactWrapper( contactMgmt );
        contactMgmtWrapper.setSelected( true, UtilsTest.addressMappingsContact[0] );

        Test.startTest();
            filteredContactsMgmt = ContactWrapper.getFilteredContactsForSelectedContacts(
                new List<ContactWrapper>{ contactMgmtWrapper },
                UserInfo.getName(),
                UtilsTest.address,
                SObjectType.Contact.FieldSets.Manage_Address_Selected_Contacts_Fields.getFields(),
                SObjectType.Address_Mapping__c.FieldSets.Manage_Address_Selected_Contacts_Fields.getFields()
            );
        Test.stopTest();

        System.assert( filteredContactsMgmt != null );
    }

    @isTest static void getFilteredContactsForSelectedContactsByOwnerDeact() {
        UtilsTest.createTestDataForContact( 1, 1 );

        List<ContactWrapper> filteredContactsDeact;

        String query = 'SELECT ' + String.join(
                                       new List<String>(
                                           Utils.getFieldsFromFieldSet(
                                               Utils.joinFieldsInFieldSets(
                                                   SObjectType.Contact.FieldSets.Deactivate_Address_Selected_Contacts_Fie.getFields(),
                                                   null
                                               ),
                                               new List<Schema.SObjectField>{ Contact.Name },
                                               true
                                           )
                                       ), ', '
                                   ) + ' ';
        query += 'FROM Contact ';
        query += 'WHERE AccountId = \'' + UtilsTest.account.Id + '\' ';
        Contact contactDeact = (Contact)Database.query( query )[0];
        ContactWrapper contactDeactWrapper = new ContactWrapper( contactDeact );
        contactDeactWrapper.setSelected( true, UtilsTest.addressMappingsContact[0] );

        Test.startTest();
            filteredContactsDeact = ContactWrapper.getFilteredContactsForSelectedContacts(
                new List<ContactWrapper>{ contactDeactWrapper },
                UserInfo.getName(),
                UtilsTest.address,
                SObjectType.Contact.FieldSets.Deactivate_Address_Selected_Contacts_Fie.getFields(),
                SObjectType.Address_Mapping__c.FieldSets.Deactivate_Address_Selected_Contacts_Fie.getFields()
            );
        Test.stopTest();

        System.assert( filteredContactsDeact != null );
    }

    @isTest static void init() {
        UtilsTest.createTestDataForContact( 1, 1 );

        ContactWrapper contactWrapper;

        Test.startTest();
            contactWrapper = new ContactWrapper( UtilsTest.contact );
        Test.stopTest();

        System.assert( contactWrapper != null );
        System.assert( contactWrapper.record != null );
    }

    @isTest static void wrapperFunctionality() {
        UtilsTest.createTestDataForContact( 1, 1 );

        ContactWrapper contactWrapper = new ContactWrapper( UtilsTest.contact );

        Test.startTest();
            contactWrapper.setSelected( true );
            System.assert( contactWrapper.getSelected() == true );

            contactWrapper.setSelected( false );
            System.assert( contactWrapper.getSelected() == false );

            contactWrapper.setSelected( true, UtilsTest.addressMappingsContact[0] );
            System.assert( contactWrapper.getSelected() == true );
            System.assert( contactWrapper.addressMapping != null );

            contactWrapper.removeAddress();
            System.assert( contactWrapper.addressMapping == null );

            contactWrapper.addAddress( UtilsTest.addressMappingsContact[0] );
            System.assert( contactWrapper.addressMapping != null );
        Test.stopTest();
    }

}