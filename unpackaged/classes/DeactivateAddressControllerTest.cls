@isTest
private class DeactivateAddressControllerTest {

    @isTest static void initWithAccount() {
        UtilsTest.createTestDataForAccount( 1 );

        Test.startTest();
            Test.setCurrentPageReference( Page.DeactivateAddress );
            System.currentPageReference().getParameters().put( 'id', UtilsTest.addressMappingsAccount[0].Id );
            DeactivateAddressController controller = new DeactivateAddressController();
        Test.stopTest();

        System.assertEquals( controller.hasError, false );
    }

    @isTest static void initWithContact() {
        UtilsTest.createTestDataForContact( 1, 1 );

        Test.startTest();
            Test.setCurrentPageReference( Page.DeactivateAddress );
            System.currentPageReference().getParameters().put( 'id', UtilsTest.addressMappingsContact[0].Id );
            DeactivateAddressController controller = new DeactivateAddressController();
        Test.stopTest();

        System.assertEquals( controller.hasError, false );
    }

    @isTest static void initNegative() {
        UtilsTest.createTestDataForContact( 1, 1 );

        Test.startTest();
            Test.setCurrentPageReference( Page.DeactivateAddress );
            System.currentPageReference().getParameters().put( 'id', UserInfo.getUserId() );
            DeactivateAddressController controller = new DeactivateAddressController();
        Test.stopTest();

        System.assertEquals( controller.hasError, true );
    }

    @isTest static void initNonExistingRecord() {
        UtilsTest.createTestDataForContact( 1, 1 );

        Test.startTest();
            Test.setCurrentPageReference( Page.DeactivateAddress );
            System.currentPageReference().getParameters().put( 'id', '001000000000000' );
            DeactivateAddressController controller = new DeactivateAddressController();
        Test.stopTest();

        System.assertEquals( controller.hasError, true );
    }

    @isTest static void controllerAccountActions() {
        UtilsTest.createTestDataForContact( 1, 1 );

        Aam_Settings__c settings = Aam_Settings__c.getOrgDefaults();
        settings.Active_Contact_Definition_Field__c = 'DoNotCall';
        UPSERT settings Aam_Settings__c.Id;
        UPDATE new Contact( Id = UtilsTest.contact.Id, DoNotCall = true );

        Test.setCurrentPageReference( Page.DeactivateAddress );
        System.currentPageReference().getParameters().put( 'id', UtilsTest.addressMappingsAccount[0].Id );
        DeactivateAddressController controller = new DeactivateAddressController();

        Test.startTest();
            List<FieldInfo> addressMappingHardcodedFields = controller.getAddressMappingHardcodedFields();
            List<ContactWrapper> relatedContacts = controller.getRelatedContacts();

            controller.linkContactId = UtilsTest.contact.Id;
            controller.linkContact();
            controller.linkAllContacts();
            controller.unlinkContactId = UtilsTest.contact.Id;
            controller.unlinkContact();
            controller.unlinkAllContacts();
            controller.linkAllContacts();
        Test.stopTest();

        System.assert( !controller.hasError );
        System.assert( !ApexPages.hasMessages() );
    }

    @isTest static void controllerAccountActionsDeactAccount() {
        UtilsTest.createTestDataForContact( 1, 1 );
        Test.setCurrentPageReference( Page.DeactivateAddress );
        System.currentPageReference().getParameters().put( 'id', UtilsTest.addressMappingsAccount[0].Id );
        DeactivateAddressController controller = new DeactivateAddressController();

        Test.startTest();
            controller.linkAllContacts();
            PageReference deactivateAddressAccount = controller.deactivateAddressAccount();
        Test.stopTest();

        System.assert( !controller.hasError );
        System.assert( !ApexPages.hasMessages() );
    }

    @isTest static void controllerAccountActionsDeactAndCreateAccount() {
        UtilsTest.createTestDataForContact( 1, 1 );
        Test.setCurrentPageReference( Page.DeactivateAddress );
        System.currentPageReference().getParameters().put( 'id', UtilsTest.addressMappingsAccount[0].Id );
        DeactivateAddressController controller = new DeactivateAddressController();

        Test.startTest();
            controller.linkAllContacts();
            PageReference deactivateAndCreateAddressAccount = controller.deactivateAndCreateAddressAccount();
        Test.stopTest();

        System.assert( !controller.hasError );
        System.assert( !ApexPages.hasMessages() );
    }

    @isTest static void controllerBaseClass() {
        UtilsTest.createTestDataForContact( 1, 1 );
        Test.setCurrentPageReference( Page.DeactivateAddress );
        System.currentPageReference().getParameters().put( 'id', UtilsTest.addressMappingsAccount[0].Id );
        DeactivateAddressController controller = new DeactivateAddressController();

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
            List<SelectOption> headerAddressTypes = controller.getHeaderAddressTypes();
            controller.headerAddressType = AddressMappingServices.ADDRESS_TYPE_OTHER_ADDRESS;
            controller.setHeaderAddressTypes();
            Boolean headerPrimary = controller.headerPrimary;
            Boolean headerPrimaries = controller.getHeaderPrimaries();
            controller.headerPrimaryValue = true;
            controller.setHeaderPrimaries();
            controller.reRender();
        Test.stopTest();

        System.assert( !controller.hasError );
        System.assert( !ApexPages.hasMessages() );
    }

}