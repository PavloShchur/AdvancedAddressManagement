@isTest
private class ManageAddressControllerTest {

    @isTest static void initWithAccount() {
        UtilsTest.createTestDataForAccount( 1 );

        Test.startTest();
            Test.setCurrentPageReference( Page.ManageAddress );
            System.currentPageReference().getParameters().put( 'id', UtilsTest.addressMappingsAccount[0].Id );
            ManageAddressController controller = new ManageAddressController();
        Test.stopTest();

        System.assertEquals( controller.hasError, false );
    }

    @isTest static void initWithContact() {
        UtilsTest.createTestDataForContact( 1, 1 );

        Test.startTest();
            Test.setCurrentPageReference( Page.ManageAddress );
            System.currentPageReference().getParameters().put( 'id', UtilsTest.addressMappingsContact[0].Id );
            ManageAddressController controller = new ManageAddressController();
        Test.stopTest();

        System.assertEquals( controller.hasError, false );
    }

    @isTest static void initNegative() {
        UtilsTest.createTestDataForContact( 1, 1 );

        Test.startTest();
            Test.setCurrentPageReference( Page.ManageAddress );
            System.currentPageReference().getParameters().put( 'id', UserInfo.getUserId() );
            ManageAddressController controller = new ManageAddressController();
        Test.stopTest();

        System.assertEquals( controller.hasError, true );
    }

    @isTest static void initNonExistingRecord() {
        UtilsTest.createTestDataForContact( 1, 1 );

        Test.startTest();
            Test.setCurrentPageReference( Page.ManageAddress );
            System.currentPageReference().getParameters().put( 'id', '001000000000000' );
            ManageAddressController controller = new ManageAddressController();
        Test.stopTest();

        System.assertEquals( controller.hasError, true );
    }

    @isTest static void controllerContactActions() {
        UtilsTest.createTestDataForContact( 1, 1 );
        Test.setCurrentPageReference( Page.ManageAddress );
        System.currentPageReference().getParameters().put( 'id', UtilsTest.addressMappingsContact[0].Id );
        ManageAddressController controller = new ManageAddressController();

        Test.startTest();
            controller.addressMappingRecord.Primary__c = true;

            PageReference updateAddressContact = controller.updateAddressContact();
        Test.stopTest();

        System.assert( !controller.hasError );
        System.assert( !ApexPages.hasMessages() );
    }

    @isTest static void controllerAccountActionsNewMapping() {
        UtilsTest.createTestDataForContact( 1, 1 );
        Test.setCurrentPageReference( Page.ManageAddress );
        System.currentPageReference().getParameters().put( 'id', UtilsTest.addressMappingsAccount[0].Id );
        ManageAddressController controller = new ManageAddressController();

        Test.startTest();
            controller.addressMappingRecord.Primary__c = true;
            controller.linkAllContacts();

            controller.addressId = UtilsTest.address.Id;
            for( ContactWrapper contactWrapperItem : controller.selectedContacts ) {
                contactWrapperItem.addressMapping.Primary__c = true;
                contactWrapperItem.addressMapping.Address_Type__c = AddressMappingServices.ADDRESS_TYPE_BILLING_ADDRESS;
            }

            PageReference updateAddressAccount = controller.updateAddressAccount();
        Test.stopTest();

        System.assert( !controller.hasError );
        System.assert( !ApexPages.hasMessages() );
    }

    @isTest static void controllerAccountActionsExistingMapping() {
        UtilsTest.createTestDataForContact( 1, 1 );
        Test.setCurrentPageReference( Page.ManageAddress );
        System.currentPageReference().getParameters().put( 'id', UtilsTest.addressMappingsAccount[0].Id );
        ManageAddressController controller = new ManageAddressController();

        Test.startTest();
            controller.addressMappingRecord.Primary__c = true;
            controller.linkAllContacts();

            controller.addressId = UtilsTest.address.Id;
            for( ContactWrapper contactWrapperItem : controller.selectedContacts ) {
                contactWrapperItem.addressMapping.Primary__c = true;
                contactWrapperItem.addressMapping.Address_Type__c = controller.addressMappingRecord.Address_Type__c;
            }

            PageReference updateAddressAccount = controller.updateAddressAccount();
        Test.stopTest();

        System.assert( !controller.hasError );
        System.assert( !ApexPages.hasMessages() );
    }

    @isTest static void controllerBaseClass() {
        UtilsTest.createTestDataForContact( 1, 1 );
        UtilsTest.contact = null;
        UtilsTest.amAddressType = AddressMappingServices.ADDRESS_TYPE_BILLING_ADDRESS;
        UtilsTest.createTestDataForContact( 0, 1 );

        Test.setCurrentPageReference( Page.ManageAddress );
        System.currentPageReference().getParameters().put( 'id', UtilsTest.addressMappingsAccount[0].Id );
        ManageAddressController controller = new ManageAddressController();

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