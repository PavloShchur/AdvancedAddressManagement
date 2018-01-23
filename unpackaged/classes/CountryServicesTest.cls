@isTest
private class CountryServicesTest {

    @isTest static void recreateCountryMappings() {

        Test.startTest();
            CountryServices.recreateCountryMappings();
        Test.stopTest();

        List<Country_Mapping__c> mappings = [ SELECT Id
                                              FROM Country_Mapping__c
                                              LIMIT 1 ];
        System.assert( !mappings.isEmpty() );
    }

    @isTest static void populateCountryMappingOnExistingAddress() {
        UtilsTest.createTestDataForAccount( 1 );
        String countryName = 'test';
        Country_Mapping__c cm;

        Test.startTest();
            cm = new Country_Mapping__c( Iso_Code__c = UtilsTest.aCountry, Country_Name__c = countryName );
            INSERT cm;
        Test.stopTest();

        List<Address__c> addresses = [ SELECT Country_Mapping__c
                                       FROM Address__c
                                       WHERE Id = :UtilsTest.address.Id ];
        System.assert( !addresses.isEmpty() );
        System.assert( addresses.size() == 1 );
        System.assert( addresses[0].Country_Mapping__c == cm.Id );
    }

    @isTest static void populateCountryMappingOnNewAddress() {
        String countryName = 'test';
        Country_Mapping__c cm = new Country_Mapping__c( Iso_Code__c = UtilsTest.aCountry, Country_Name__c = countryName );
        INSERT cm;

        Test.startTest();
            UtilsTest.createTestDataForAccount( 1 );
        Test.stopTest();

        List<Address__c> addresses = [ SELECT Country_Mapping__c
                                       FROM Address__c
                                       WHERE Id = :UtilsTest.address.Id ];
        System.assert( !addresses.isEmpty() );
        System.assert( addresses.size() == 1 );
        System.assert( addresses[0].Country_Mapping__c == cm.Id );
    }

    @isTest static void countryIsoCodeToName() {
        CountryServices.recreateCountryMappings();

        Map<String, String> countryIsoCodeToName;

        Test.startTest();
            countryIsoCodeToName = CountryServices.countryIsoCodeToName;
        Test.stopTest();

        System.assert( countryIsoCodeToName != null );
        System.assert( !countryIsoCodeToName.isEmpty() );
    }

}