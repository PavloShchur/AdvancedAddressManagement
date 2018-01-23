@isTest
private class AddressListControllerTest {

    @isTest static void initWithAccount() {
        UtilsTest.createTestDataForAccount( 1 );
        UtilsTest.createTestDataForContact( 0, 1 );
        Test.setCurrentPageReference( Page.AddressList );
        System.currentPageReference().getParameters().put( 'id', UtilsTest.account.Id );
        AddressListController controller = new AddressListController();

        Test.startTest();
            Aam_Settings__c settings = controller.settings;
            settings = controller.getSettings();
            System.assert( settings != null );

            String objectName = controller.getObjectName();
            Boolean newAddressLinkAvailable = controller.getNewAddressLinkAvailable();
            controller.filterText = 'test';
            controller.filterRecords();
            List<AddressMappingWrapper> filteredRecords = controller.getFilteredRecords();
            controller.deactivateAddressRecordId = UtilsTest.addressMappingsAccount[0].Id;
            controller.deactivateAddress();
        Test.stopTest();

        System.assertEquals( false, ApexPages.hasMessages() );
    }

    @isTest static void initWithAccountNegative() {
        UtilsTest.createTestDataForAccount( 1 );
        Test.setCurrentPageReference( Page.AddressList );
        System.currentPageReference().getParameters().put( 'id', UtilsTest.account.Id );
        AddressListController controller = new AddressListController();

        Test.startTest();
            controller.deactivateAddressRecordId = UtilsTest.address.Id; //wrong id
            controller.deactivateAddress();
        Test.stopTest();

        System.assertEquals( true, ApexPages.hasMessages() );
    }

    @isTest static void initWithContact() {
        UtilsTest.createTestDataForContact( 1, 1 );
        Test.setCurrentPageReference( Page.AddressList );
        System.currentPageReference().getParameters().put( 'id', UtilsTest.contact.Id );
        AddressListController controller = new AddressListController();

        Test.startTest();
            Aam_Settings__c settings = controller.settings;
            settings = controller.getSettings();
            System.assert( settings != null );

            String objectName = controller.getObjectName();
            Boolean newAddressLinkAvailable = controller.getNewAddressLinkAvailable();
            controller.filterText = 'test';
            controller.filterRecords();
            List<AddressMappingWrapper> filteredRecords = controller.getFilteredRecords();
            controller.deactivateAddressRecordId = UtilsTest.addressMappingsContact[0].Id;
            controller.deactivateAddress();

            UPDATE new Contact( Id = UtilsTest.contact.Id, AccountId = null );
            Boolean newAddressLinkAvailableNegative = controller.getNewAddressLinkAvailable();
        Test.stopTest();

        System.assertEquals( false, ApexPages.hasMessages() );
    }

}