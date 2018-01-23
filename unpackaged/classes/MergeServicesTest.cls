@isTest
private with sharing class MergeServicesTest {

    private static final Integer NUMBER_TO_CREATE = 2;
    private static final String CHANGED_ADDRESS_TYPE = 'Reporting Address';

    private static Address__c address1, address2;
    private static List<Address_Mapping__c> mappings1, mappings2;
	
    @isTest
    private static void testMergeMappingsByPrimary(){

    	UtilsTest.createTestDataForAccount(NUMBER_TO_CREATE);
    	address1 = UtilsTest.address;
    	mappings1 = UtilsTest.addressMappingsAccount;

    	UtilsTest.createTestDataForAccount(NUMBER_TO_CREATE);
    	address2 = UtilsTest.address;
    	mappings2 = UtilsTest.addressMappingsAccount;

    	Address_Mapping__c thePrimaryMapping = mappings2[0];
    	thePrimaryMapping.Primary__c = true;
    	update thePrimaryMapping;
    	Test.startTest();
    		MergeServices.MappingsMergeResult res = MergeServices.mergeMappings(address1, new List<Address__c>{address2} );
    	Test.stopTest();
    	System.assertEquals( 1, res.mappingsToUpdate.size() );
    	System.assertEquals( NUMBER_TO_CREATE * 2 -1, res.mappingsToDelete.size() );
    	System.assertEquals( thePrimaryMapping.Id, res.mappingsToUpdate[0].Id );
    	System.assertEquals( address1.Id, res.mappingsToUpdate[0].Address__c );
    }

    @isTest
    private static void testMergeMappingsByActive(){

    	UtilsTest.createTestDataForAccount(NUMBER_TO_CREATE);
    	address1 = UtilsTest.address;
    	mappings1 = UtilsTest.addressMappingsAccount;

    	UtilsTest.amActive = !UtilsTest.amActive;
    	UtilsTest.createTestDataForAccount(NUMBER_TO_CREATE);
    	address2 = UtilsTest.address;
    	mappings2 = UtilsTest.addressMappingsAccount;

    	Test.startTest();
    		MergeServices.MappingsMergeResult res = MergeServices.mergeMappings(address1, new List<Address__c>{address2} );
    	Test.stopTest();
    	System.assertEquals( 2, res.mappingsToUpdate.size() );
    }

    @isTest
    private static void testMergeMappingsByAddressType(){

    	UtilsTest.createTestDataForAccount(NUMBER_TO_CREATE);
    	address1 = UtilsTest.address;
    	mappings1 = UtilsTest.addressMappingsAccount;

    	UtilsTest.amAddressType = CHANGED_ADDRESS_TYPE;
    	UtilsTest.createTestDataForAccount(NUMBER_TO_CREATE);
    	address2 = UtilsTest.address;
    	mappings2 = UtilsTest.addressMappingsAccount;

    	Test.startTest();
    		MergeServices.MappingsMergeResult res = MergeServices.mergeMappings(address1, new List<Address__c>{address2} );
    	Test.stopTest();
    	System.assertEquals( 2, res.mappingsToUpdate.size() );
    }
	
    @isTest
    private static void testMergeMappingsByCreatedDate(){

    	UtilsTest.createTestDataForAccount(NUMBER_TO_CREATE);
    	address1 = UtilsTest.address;
    	mappings1 = UtilsTest.addressMappingsAccount;

    	UtilsTest.createTestDataForAccount(NUMBER_TO_CREATE);
    	address2 = UtilsTest.address;
    	mappings2 = UtilsTest.addressMappingsAccount;

    	Test.startTest();
    		MergeServices.MappingsMergeResult res = MergeServices.mergeMappings(address1, new List<Address__c>{address2} );
    	Test.stopTest();
    	System.assertEquals( 1, res.mappingsToUpdate.size() );
    	System.assertEquals( NUMBER_TO_CREATE * 2 -1, res.mappingsToDelete.size() );
    	Address_Mapping__c mappingToUpdate = [Select Primary__c From Address_Mapping__c Where Id = : res.mappingsToUpdate[0].Id];
    	System.assert( mappingToUpdate.Primary__c );
    	System.assertEquals( address1.Id, res.mappingsToUpdate[0].Address__c );
    }
	
    @isTest
    private static void testMergeMappingsByCreatedDateForInactiveMapping(){

    	UtilsTest.amActive = false;
    	UtilsTest.createTestDataForAccount(NUMBER_TO_CREATE);
    	address1 = UtilsTest.address;
    	mappings1 = UtilsTest.addressMappingsAccount;

    	UtilsTest.createTestDataForAccount(NUMBER_TO_CREATE);
    	address2 = UtilsTest.address;
    	mappings2 = UtilsTest.addressMappingsAccount;

    	Address_Mapping__c theEarliestMapping = mappings2[1];
    	Datetime yesterday = Datetime.now().addDays(-1);
    	Test.setCreatedDate( theEarliestMapping.Id, yesterday);
    	Test.startTest();
    		MergeServices.MappingsMergeResult res = MergeServices.mergeMappings(address1, new List<Address__c>{address2} );
    	Test.stopTest();
    	System.assertEquals( 2, res.mappingsToUpdate.size() );
    	System.assertEquals( NUMBER_TO_CREATE * 2 - 2, res.mappingsToDelete.size() );
    }

    @isTest
    private static void testMergeMappingsOnContactAndAccount(){

    	UtilsTest.createTestDataForAccount(NUMBER_TO_CREATE);
    	address1 = UtilsTest.address;
    	mappings1 = UtilsTest.addressMappingsAccount;

    	UtilsTest.createTestDataForContact(NUMBER_TO_CREATE, NUMBER_TO_CREATE);
    	address2 = UtilsTest.address;
    	mappings2 = UtilsTest.addressMappingsAccount;

    	Address_Mapping__c thePrimaryMapping = mappings2[0];
    	thePrimaryMapping.Primary__c = true;
    	update thePrimaryMapping;
    	Test.startTest();
    		MergeServices.MappingsMergeResult res = MergeServices.mergeMappings(address1, new List<Address__c>{address2} );
    	Test.stopTest();
    	System.assertEquals( 2, res.mappingsToUpdate.size() );
    }

 }