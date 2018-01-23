@isTest
private class AccountServicesTest {

    @isTest static void deleteAccountFromHierarchy1() {
        Utils.updateCustomSettings( true );
        Account acc1 = new Account( Name = 'acc1' );
        INSERT acc1;

        Account acc2 = new Account( Name = 'acc2', ParentId = acc1.Id );
        INSERT acc2;

        Address__c addr1 = new Address__c( Account__c = acc1.Id, Address_Line_1__c = '1', City__c = '1', Country__c = 'AD', Postcode__c = '1', State_County__c = '1' );
        INSERT addr1;

        List<Address_Mapping__c> addressMappings = new List<Address_Mapping__c>();
        Address_Mapping__c am1 = new Address_Mapping__c( Account__c = acc1.Id, Address__c = addr1.Id, Address_Type__c = 'Billing Address', Active__c = true );
        addressMappings.add( am1 );
        Address_Mapping__c am2 = new Address_Mapping__c( Account__c = acc2.Id, Address__c = addr1.Id, Address_Type__c = 'Billing Address', Active__c = true );
        addressMappings.add( am2 );
        INSERT addressMappings;

        Test.startTest();
            DELETE acc1;
        Test.stopTest();

        List<Address__c> addressesFromDb = [ SELECT Account__c FROM Address__c ];
        System.assert( addressesFromDb.size() == 1 );
        for( Address__c address : addressesFromDb ) {
            System.assert( address.Account__c == acc2.Id );
        }

        List<Address_Mapping__c> addressMappingsFromDb = [ SELECT Address__c, Account__c FROM Address_Mapping__c ];
        System.assertEquals( 2, addressMappingsFromDb.size() );
        System.assert( new Map<Id, Address_Mapping__c>( addressMappings ).containsKey( addressMappingsFromDb[0].Id ) );
        System.assert( new Map<Id, Address_Mapping__c>( addressMappings ).containsKey( addressMappingsFromDb[1].Id ) );
        for( Address_Mapping__c addressMapping : addressMappingsFromDb ) {
            if( addressMapping.Id == am1.Id ) {
                System.assert( addressMapping.Address__c == addr1.Id );
                System.assert( addressMapping.Account__c == null );
            } else if( addressMapping.Id == am2.Id ) {
                System.assert( addressMapping.Address__c == addr1.Id );
                System.assert( addressMapping.Account__c == acc2.Id );
            }
        }
    }

    @isTest static void deleteAccountFromHierarchy2() {
        Utils.updateCustomSettings( true );
        Account acc1 = new Account( Name = 'acc1' );
        INSERT new List<Account>{ acc1 };

        Account acc2 = new Account( Name = 'acc2', ParentId = acc1.Id );
        INSERT new List<Account>{ acc2 };

        Account acc3 = new Account( Name = 'acc3', ParentId = acc2.Id );
        INSERT new List<Account>{ acc3 };

        Account acc4 = new Account( Name = 'acc4', ParentId = acc3.Id );
        Account acc5 = new Account( Name = 'acc5', ParentId = acc3.Id );
        INSERT new List<Account>{ acc4, acc5 };

        Account acc6 = new Account( Name = 'acc6', ParentId = acc4.Id );
        Account acc7 = new Account( Name = 'acc7', ParentId = acc5.Id );
        INSERT new List<Account>{ acc6, acc7 };

        Address__c addr1 = new Address__c( Account__c = acc1.Id, Address_Line_1__c = '1', City__c = '1', Country__c = 'AD', Postcode__c = '1', State_County__c = '1' );
        Address__c addr2 = new Address__c( Account__c = acc2.Id, Address_Line_1__c = '2', City__c = '2', Country__c = 'AD', Postcode__c = '2', State_County__c = '2' );
        Address__c addr3 = new Address__c( Account__c = acc3.Id, Address_Line_1__c = '3', City__c = '3', Country__c = 'AD', Postcode__c = '3', State_County__c = '3' );
        Address__c addr4 = new Address__c( Account__c = acc4.Id, Address_Line_1__c = '4', City__c = '4', Country__c = 'AD', Postcode__c = '4', State_County__c = '4' );
        Address__c addr6 = new Address__c( Account__c = acc6.Id, Address_Line_1__c = '6', City__c = '6', Country__c = 'AD', Postcode__c = '6', State_County__c = '6' );
        Address__c addr7 = new Address__c( Account__c = acc7.Id, Address_Line_1__c = '7', City__c = '7', Country__c = 'AD', Postcode__c = '7', State_County__c = '7' );
        List<Address__c> addresses = new List<Address__c>{ addr1, addr2, addr3, addr4, addr6, addr7 };
        INSERT addresses;

        Address_Mapping__c am3_1 = new Address_Mapping__c( Account__c = acc3.Id, Address__c = addr1.Id, Address_Type__c = 'Billing Address', Active__c = true );
        Address_Mapping__c am3_3 = new Address_Mapping__c( Account__c = acc3.Id, Address__c = addr3.Id, Address_Type__c = 'Shipping Address', Active__c = true );
        Address_Mapping__c am4_6 = new Address_Mapping__c( Account__c = acc4.Id, Address__c = addr6.Id, Address_Type__c = 'Billing Address', Active__c = true );
        Address_Mapping__c am5_2 = new Address_Mapping__c( Account__c = acc5.Id, Address__c = addr2.Id, Address_Type__c = 'Billing Address', Active__c = true );
        Address_Mapping__c am5_4 = new Address_Mapping__c( Account__c = acc5.Id, Address__c = addr4.Id, Address_Type__c = 'Shipping Address', Active__c = true );
        Address_Mapping__c am6_4 = new Address_Mapping__c( Account__c = acc6.Id, Address__c = addr4.Id, Address_Type__c = 'Billing Address', Active__c = true );
        Address_Mapping__c am7_2 = new Address_Mapping__c( Account__c = acc7.Id, Address__c = addr2.Id, Address_Type__c = 'Billing Address', Active__c = true );
        Address_Mapping__c am7_6 = new Address_Mapping__c( Account__c = acc7.Id, Address__c = addr6.Id, Address_Type__c = 'Shipping Address', Active__c = true );
        Address_Mapping__c am7_7 = new Address_Mapping__c( Account__c = acc7.Id, Address__c = addr7.Id, Address_Type__c = 'Mailing Address', Active__c = true );
        List<Address_Mapping__c> addressMappings = new List<Address_Mapping__c>{ am3_1, am3_3, am4_6, am5_2, am5_4, am6_4, am7_2, am7_6, am7_7 };
        INSERT addressMappings;

        List<Account> accountsToDelete = new List<Account>{ acc1, acc3 };

        Test.startTest();
            DELETE accountsToDelete;
        Test.stopTest();

        List<Account> accountsFromDb = [ SELECT ParentId FROM Account ];

        for( Account account : accountsFromDb ) {
            if( account.Id == acc2.Id ) {
                System.assert( account.ParentId == null );
            } else if( account.Id == acc4.Id ) {
                System.assert( account.ParentId == null );
            } else if( account.Id == acc5.Id ) {
                System.assert( account.ParentId == null );
            } else if( account.Id == acc6.Id ) {
                System.assert( account.ParentId == acc4.Id );
            } else if( account.Id == acc7.Id ) {
                System.assert( account.ParentId == acc5.Id );
            } else {
                System.assert( false );
            }
        }

        List<Address__c> addressesFromDb = [ SELECT Account__c, Address_Line_1__c FROM Address__c ];

        System.assert( addressesFromDb.size() == 6 );

        for( Address__c address : addressesFromDb ) {
            if( address.Id == addr1.Id ) {
                System.assert( address.Account__c == acc2.Id );
                System.assert( address.Address_Line_1__c == addr1.Address_Line_1__c );
            } else if( address.Id == addr2.Id ) {
                System.assert( address.Account__c == acc2.Id );
                System.assert( address.Address_Line_1__c == addr2.Address_Line_1__c );
            } else if( address.Id == addr3.Id ) {
                System.assert( address.Account__c == acc2.Id );
                System.assert( address.Address_Line_1__c == addr3.Address_Line_1__c );
            } else if( address.Id == addr4.Id ) {
                System.assert( address.Account__c == acc2.Id );
                System.assert( address.Address_Line_1__c == addr4.Address_Line_1__c );
            } else if( address.Id == addr6.Id ) {
                System.assert( address.Account__c == acc2.Id );
                System.assert( address.Address_Line_1__c == addr6.Address_Line_1__c );
            } else if( address.Id == addr7.Id ) {
                System.assert( address.Account__c == acc2.Id );
                System.assert( address.Address_Line_1__c == addr7.Address_Line_1__c );
            } else {
                System.assert( false );
            }
        }

        List<Address_Mapping__c> addressMappingsFromDb = [ SELECT Address__c, Account__c, Address__r.Account__c FROM Address_Mapping__c ];
        System.assert( addressMappingsFromDb.size() == 9 );

        for( Address_Mapping__c am : addressMappingsFromDb ) {
            if( am.Id == am3_1.Id ) {
                System.assert( am.Account__c == null );
                System.assert( am.Address__c == addr1.Id );
                System.assert( am.Address__r.Account__c == acc2.Id );
            } else if( am.Id == am3_3.Id ) {
                System.assert( am.Account__c == null );
                System.assert( am.Address__c == addr3.Id );
                System.assert( am.Address__r.Account__c == acc2.Id );
            } else if( am.Id == am4_6.Id ) {
                System.assert( am.Account__c == acc4.Id );
                System.assert( am.Address__c == addr6.Id );
                System.assert( am.Address__r.Account__c == acc2.Id );
            } else if( am.Id == am5_2.Id ) {
                System.assert( am.Account__c == acc5.Id );
                System.assert( am.Address__c == addr2.Id );
                System.assert( am.Address__r.Account__c == acc2.Id );
            } else if( am.Id == am5_4.Id ) {
                System.assert( am.Account__c == acc5.Id );
                System.assert( am.Address__c == addr4.Id );
                System.assert( am.Address__r.Account__c == acc2.Id );
            } else if( am.Id == am6_4.Id ) {
                System.assert( am.Account__c == acc6.Id );
                System.assert( am.Address__c == addr4.Id );
                System.assert( am.Address__r.Account__c == acc2.Id );
            } else if( am.Id == am7_2.Id ) {
                System.assert( am.Account__c == acc7.Id );
                System.assert( am.Address__c == addr2.Id );
                System.assert( am.Address__r.Account__c == acc2.Id );
            } else if( am.Id == am7_6.Id ) {
                System.assert( am.Account__c == acc7.Id );
                System.assert( am.Address__c == addr6.Id );
                System.assert( am.Address__r.Account__c == acc2.Id );
            } else if( am.Id == am7_7.Id ) {
                System.assert( am.Account__c == acc7.Id );
                System.assert( am.Address__c == addr7.Id );
                System.assert( am.Address__r.Account__c == acc2.Id );
            } else {
                System.assert( false );
            }
        }
    }

    @isTest static void deleteAllAccountsFromHierarchy() {
        Utils.updateCustomSettings( true );
        Account acc1 = new Account( Name = 'acc1' );
        INSERT new List<Account>{ acc1 };

        Account acc2 = new Account( Name = 'acc2', ParentId = acc1.Id );
        Account acc3 = new Account( Name = 'acc3', ParentId = acc1.Id );
        INSERT new List<Account>{ acc2, acc3 };

        Account acc4 = new Account( Name = 'acc4', ParentId = acc2.Id );
        INSERT new List<Account>{ acc4 };

        Address__c addr1 = new Address__c( Account__c = acc1.Id, Address_Line_1__c = '1', City__c = '1', Country__c = 'AD', Postcode__c = '1', State_County__c = '1' );
        Address__c addr2 = new Address__c( Account__c = acc2.Id, Address_Line_1__c = '2', City__c = '2', Country__c = 'AD', Postcode__c = '2', State_County__c = '2' );
        Address__c addr3 = new Address__c( Account__c = acc3.Id, Address_Line_1__c = '3', City__c = '3', Country__c = 'AD', Postcode__c = '3', State_County__c = '3' );
        Address__c addr4 = new Address__c( Account__c = acc4.Id, Address_Line_1__c = '4', City__c = '4', Country__c = 'AD', Postcode__c = '4', State_County__c = '4' );
        List<Address__c> addresses = new List<Address__c>{ addr1, addr2, addr3, addr4 };
        INSERT addresses;

        Address_Mapping__c am1_1 = new Address_Mapping__c( Account__c = acc1.Id, Address__c = addr1.Id, Address_Type__c = 'Billing Address', Active__c = true );
        Address_Mapping__c am1_2 = new Address_Mapping__c( Account__c = acc1.Id, Address__c = addr2.Id, Address_Type__c = 'Shipping Address', Active__c = true );
        Address_Mapping__c am3_4 = new Address_Mapping__c( Account__c = acc3.Id, Address__c = addr4.Id, Address_Type__c = 'Billing Address', Active__c = true );
        Address_Mapping__c am4_2 = new Address_Mapping__c( Account__c = acc4.Id, Address__c = addr2.Id, Address_Type__c = 'Billing Address', Active__c = true );
        Address_Mapping__c am4_3 = new Address_Mapping__c( Account__c = acc4.Id, Address__c = addr3.Id, Address_Type__c = 'Shipping Address', Active__c = true );
        List<Address_Mapping__c> addressMappings = new List<Address_Mapping__c>{ am1_1, am1_2, am3_4, am4_2, am4_3 };
        INSERT addressMappings;

        List<Account> accountsToDelete = new List<Account>{ acc1, acc2, acc3, acc4 };

        Test.startTest();
            DELETE accountsToDelete;
        Test.stopTest();

        List<Account> accountsFromDb = [ SELECT ParentId FROM Account ];
        System.assert( accountsFromDb.isEmpty() );

        List<Address__c> addressesFromDb = [ SELECT Account__c, Address_Line_1__c FROM Address__c ];
        System.assertEquals( 4, addressesFromDb.size() );
        for( Address__c addressFromDb : addressesFromDb ) {
            System.assert( addressFromDb.Account__c == null );
        }

        List<Address_Mapping__c> addressMappingsFromDb = [ SELECT Address__c, Account__c, Address__r.Account__c FROM Address_Mapping__c ];
        System.assertEquals( 5, addressMappingsFromDb.size() );
        for( Address_Mapping__c addressMappingFromDb : addressMappingsFromDb ) {
            System.assert( addressMappingFromDb.Account__c == null );
            System.assert( addressMappingFromDb.Address__r.Account__c == null );
            System.assert( addressMappingFromDb.Address__c != null );
        }
    }

}