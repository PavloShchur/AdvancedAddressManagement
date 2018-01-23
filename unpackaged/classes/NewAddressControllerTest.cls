@isTest
private class NewAddressControllerTest {

    @isTest static void initWithAccount() {
        UtilsTest.createTestDataForAccount( 1 );

        Test.startTest();
            Test.setCurrentPageReference( Page.NewAddress );
            System.currentPageReference().getParameters().put( 'id', UtilsTest.account.Id );
            NewAddressController controller = new NewAddressController();
        Test.stopTest();

        System.assertEquals( controller.hasError, false );
    }

    @isTest static void initWithContact() {
        UtilsTest.createTestDataForContact( 1, 1 );

        Test.startTest();
            Test.setCurrentPageReference( Page.NewAddress );
            System.currentPageReference().getParameters().put( 'id', UtilsTest.contact.Id );
            NewAddressController controller = new NewAddressController();
        Test.stopTest();

        System.assertEquals( controller.hasError, false );
    }

    @isTest static void initNegative() {
        UtilsTest.createTestDataForContact( 1, 1 );

        Test.startTest();
            Test.setCurrentPageReference( Page.NewAddress );
            System.currentPageReference().getParameters().put( 'id', UserInfo.getUserId() );
            NewAddressController controller = new NewAddressController();
            controller.getAccountId();
        Test.stopTest();

        System.assertEquals( controller.hasError, true );
    }

    @isTest static void initNonExistingRecord() {
        UtilsTest.createTestDataForContact( 1, 1 );

        Test.startTest();
            Test.setCurrentPageReference( Page.NewAddress );
            System.currentPageReference().getParameters().put( 'id', '001000000000000' );
            NewAddressController controller = new NewAddressController();
        Test.stopTest();

        System.assertEquals( controller.hasError, true );
    }

    @isTest static void initPrepopulate() {
        UtilsTest.createTestDataForAccount( 1 );

        Contact newContact = new Contact( LastName = 'test' );
        INSERT newContact;

        Test.startTest();
            Test.setCurrentPageReference( Page.NewAddress );
            System.currentPageReference().getParameters().put( 'id', UtilsTest.account.Id );
            System.currentPageReference().getParameters().put( Utils.PARAM_CONTACT_IDS, newContact.Id );
            System.currentPageReference().getParameters().put( Utils.PARAM_ADDRESS_MAPPING_TYPE, AddressMappingServices.ADDRESS_TYPE_VISITING_ADDRESS );
            NewAddressController controller = new NewAddressController();
        Test.stopTest();

        System.assertEquals( controller.hasError, false );
    }

    @isTest static void controllerAccountActions() {
        UtilsTest.createTestDataForContact( 1, 1 );

        Aam_Settings__c settings = Aam_Settings__c.getOrgDefaults();
        settings.Active_Contact_Definition_Field__c = 'DoNotCall';
        UPSERT settings Aam_Settings__c.Id;
        UPDATE new Contact( Id = UtilsTest.contact.Id, DoNotCall = true );

        Test.setCurrentPageReference( Page.NewAddress );
        System.currentPageReference().getParameters().put( 'id', UtilsTest.account.Id );
        NewAddressController controller = new NewAddressController();


        Test.startTest();
            List<AddressMappingWrapper> relatedAddresses = controller.getRelatedAddresses();
            String filterTextRelatedAddresses = controller.filterTextRelatedAddresses;
            controller.filterRelatedAddresses();
            List<AddressMappingWrapper> filteredRelatedAddresses = controller.getFilteredRelatedAddresses();
            String primaryFilterRelatedAddresses = controller.primaryFilterRelatedAddresses;
            List<SelectOption> primaryFilterRelatedAddressesOptions = controller.getPrimaryFilterRelatedAddressesOptions();
            Id accountId = controller.getAccountId();
            List<Address__c> addresses = controller.getAddresses();
            String selectAddressId = controller.selectAddressId;
            controller.selectAddress();
            Integer minFieldsEntered = controller.getMinFieldsEntered();
            Integer numFieldsEntered = controller.getNumFieldsEntered();
            controller.clearAddress();
            controller.doSearch();

            controller.linkContactId = UtilsTest.contact.Id;
            controller.linkContact();
            controller.linkAllContacts();
            controller.unlinkContactId = UtilsTest.contact.Id;
            controller.unlinkContact();
            controller.unlinkAllContacts();

            controller.addressMappingRecord.Address_Type__c = AddressMappingServices.ADDRESS_TYPE_BILLING_ADDRESS;
            controller.linkAllContacts();

            controller.addressId = UtilsTest.address.Id;
            for( ContactWrapper contactWrapperItem : controller.selectedContacts ) {
                contactWrapperItem.addressMapping.Primary__c = true;
                contactWrapperItem.addressMapping.Address_Type__c = AddressMappingServices.ADDRESS_TYPE_VISITING_ADDRESS;
            }

            PageReference createAddressAccountWithAddressId = controller.createAddressAccount();
        Test.stopTest();

        System.assert( !controller.hasError );
        System.assert( !ApexPages.hasMessages() );
    }

    @isTest static void createOrUpdateAddressFindAddress() {
        UtilsTest.createTestDataForContact( 1, 1 );
        Test.setCurrentPageReference( Page.NewAddress );
        System.currentPageReference().getParameters().put( 'id', UtilsTest.account.Id );
        NewAddressController controller = new NewAddressController();

        Test.startTest();
            UPDATE new Address__c( Id = UtilsTest.address.Id, Status__c = AddressServices.STATUS_INACTIVE );
            controller.addressId = null;
            controller.addressRecord = UtilsTest.address.clone();

            controller.addressMappingRecord.Address_Type__c = AddressMappingServices.ADDRESS_TYPE_VISITING_ADDRESS;
            PageReference createAddressAccountWithAddressIdAndStatus = controller.createAddressAccount();
        Test.stopTest();

        System.assert( !controller.hasError );
        System.assert( !ApexPages.hasMessages() );
    }

    @isTest static void controllerAccountActionsNegative() {
        UtilsTest.createTestDataForContact( 1, 1 );
        Test.setCurrentPageReference( Page.NewAddress );
        System.currentPageReference().getParameters().put( 'id', UtilsTest.account.Id );
        NewAddressController controller = new NewAddressController();

        Test.startTest();
            controller.linkAllContacts();
            PageReference createAddressAccount = controller.createAddressAccount();

            controller.unlinkAllContacts();
            controller.addressMappingRecord.Address_Type__c = AddressMappingServices.ADDRESS_TYPE_VISITING_ADDRESS;
            controller.linkAllContacts();

            controller.addressId = UtilsTest.address.Id;
            for( ContactWrapper contactWrapperItem : controller.selectedContacts ) {
                contactWrapperItem.addressMapping.Primary__c = true;
            }
            PageReference createAddressAccountWithAddressId = controller.createAddressAccount();
        Test.stopTest();

        System.assert( !controller.hasError );
        System.assert( ApexPages.hasMessages() );
    }

    @isTest static void controllerContactActions() {
        UtilsTest.createTestDataForContact( 1, 1 );
        Test.setCurrentPageReference( Page.NewAddress );
        System.currentPageReference().getParameters().put( 'id', UtilsTest.contact.Id );
        NewAddressController controller = new NewAddressController();

        Test.startTest();
            List<AddressMappingWrapper> relatedAddresses = controller.getRelatedAddresses();
            String filterTextRelatedAddresses = controller.filterTextRelatedAddresses;
            controller.filterRelatedAddresses();
            List<AddressMappingWrapper> filteredRelatedAddresses = controller.getFilteredRelatedAddresses();
            String primaryFilterRelatedAddresses = controller.primaryFilterRelatedAddresses;
            List<SelectOption> primaryFilterRelatedAddressesOptions = controller.getPrimaryFilterRelatedAddressesOptions();
            Id accountId = controller.getAccountId();
            List<Address__c> addresses = controller.getAddresses();
            String selectAddressId = controller.selectAddressId;
            controller.selectAddress();
            Integer minFieldsEntered = controller.getMinFieldsEntered();
            Integer numFieldsEntered = controller.getNumFieldsEntered();
            controller.clearAddress();
            controller.doSearch();

            controller.linkContactId = UtilsTest.contact.Id;
            controller.linkContact();
            controller.linkAllContacts();
            controller.unlinkContactId = UtilsTest.contact.Id;
            controller.unlinkContact();
            controller.unlinkAllContacts();
            controller.linkAllContacts();

            controller.addressMappingRecord.Address_Type__c = AddressMappingServices.ADDRESS_TYPE_VISITING_ADDRESS;
            PageReference createAddressAccount = controller.createAddressContact();

            controller.addressId = UtilsTest.address.Id;
            PageReference createAddressAccountWithAddressId = controller.createAddressContact();
        Test.stopTest();

        System.assert( !controller.hasError );
        System.assert( !ApexPages.hasMessages() );
    }

    @isTest static void controllerContactActionsNegative() {
        UtilsTest.createTestDataForContact( 1, 1 );
        Test.setCurrentPageReference( Page.NewAddress );
        System.currentPageReference().getParameters().put( 'id', UtilsTest.contact.Id );
        NewAddressController controller = new NewAddressController();

        Test.startTest();
            PageReference createAddressAccount = controller.createAddressContact();
        Test.stopTest();

        System.assert( !controller.hasError );
        System.assert( ApexPages.hasMessages() );
    }

    @isTest static void controllerContactActionsNegativeNoAccountOnContact() {
        UtilsTest.createTestDataForContact( 1, 1 );
        UPDATE new Contact( Id = UtilsTest.contact.Id, AccountId = null );
        Test.setCurrentPageReference( Page.NewAddress );
        System.currentPageReference().getParameters().put( 'id', UtilsTest.contact.Id );
        NewAddressController controller = new NewAddressController();

        Test.startTest();
            controller.addressMappingRecord.Address_Type__c = AddressMappingServices.ADDRESS_TYPE_VISITING_ADDRESS;
            PageReference createAddressAccount = controller.createAddressContact();
        Test.stopTest();

        System.assert( !controller.hasError );
        System.assert( ApexPages.hasMessages() );
    }

    @isTest static void controllerBaseClass() {
        UtilsTest.createTestDataForContact( 1, 1 );
        UtilsTest.contact = null;
        UtilsTest.amAddressType = AddressMappingServices.ADDRESS_TYPE_BILLING_ADDRESS;
        UtilsTest.createTestDataForContact( 0, 1 );

        Test.setCurrentPageReference( Page.NewAddress );
        System.currentPageReference().getParameters().put( 'id', UtilsTest.account.Id );
        NewAddressController controller = new NewAddressController();

        Test.startTest();
            String addressLines = controller.getAddressLines();
            List<FieldInfo> addressMappingFields = controller.getAddressMappingFields();
            List<FieldInfo> addressMappingHardcodedFields = controller.getAddressMappingHardcodedFields();
            List<SelectOption> addressTypeValues = controller.getAddressTypeValues();
            Boolean areAllFilteredRelatedContactsSelected = controller.getAreAllFilteredRelatedContactsSelected();
            List<ContactWrapper> filteredRelatedContacts = controller.getFilteredRelatedContacts();
            String editableSelectedContactsFields = controller.getEditableSelectedContactsFields();
            controller.filterRelatedContacts();
            controller.filterSelectedContacts();
            controller.cancel();
            controller.linkAllContacts();
            List<ContactWrapper> filteredSelectedContacts = controller.getFilteredSelectedContacts();
            controller.headerAddressType = AddressMappingServices.ADDRESS_TYPE_OTHER_ADDRESS;
            controller.setHeaderAddressTypes();
            List<SelectOption> headerAddressTypes = controller.getHeaderAddressTypes();
            Boolean headerPrimary = controller.headerPrimary;
            Boolean headerPrimaries1 = controller.getHeaderPrimaries();
            controller.headerPrimaryValue = true;
            controller.setHeaderPrimaries();
            Boolean headerPrimaries2 = controller.getHeaderPrimaries();
            controller.reRender();
        Test.stopTest();

        System.assert( !controller.hasError );
        System.assert( !ApexPages.hasMessages() );
    }

}