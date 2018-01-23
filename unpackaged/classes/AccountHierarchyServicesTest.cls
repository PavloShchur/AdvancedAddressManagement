@isTest
private class AccountHierarchyServicesTest {

    @isTest static void getAccountIds() {
        Account acc0 = new Account( Name = 'acc0' );
        INSERT acc0;

        Account acc1 = new Account( Name = 'acc1', ParentId = acc0.Id );
        INSERT acc1;

        Account acc2 = new Account( Name = 'acc2', ParentId = acc1.Id );
        INSERT acc2;

        Account acc3 = new Account( Name = 'acc3', ParentId = acc2.Id );
        INSERT acc3;

        Account acc4 = new Account( Name = 'acc4', ParentId = acc3.Id );
        INSERT acc4;

        Account acc5 = new Account( Name = 'acc5', ParentId = acc4.Id );
        INSERT acc5;

        Account acc6 = new Account( Name = 'acc6', ParentId = acc5.Id );
        INSERT acc6;

        Account acc7 = new Account( Name = 'acc7', ParentId = acc6.Id );
        INSERT acc7;

        Account acc2_1 = new Account( Name = 'acc2_1', ParentId = acc1.Id );
        INSERT acc2_1;

        Account acc2_2 = new Account( Name = 'acc2_2', ParentId = acc1.Id );
        INSERT acc2_2;

        Account acc3_2_1 = new Account( Name = 'acc3_2_1', ParentId = acc2_1.Id );
        INSERT acc3_2_1;

        Account acc5_1 = new Account( Name = 'acc5_1', ParentId = acc4.Id );
        INSERT acc5_1;

        Account accU = new Account( Name = 'accUltimateParent' );
        INSERT accU;

        acc0.ParentId = accU.Id;
        UPDATE acc0;

        Set<Id> result;

        Test.startTest();
            result = AccountHierarchyServices.getAccountIds( acc7.Id );
        Test.stopTest();

        System.assert( result != null );
        System.assert( result.size() == 13 );
        System.assert( result.contains( accU.Id ) );
        System.assert( result.contains( acc0.Id ) );
        System.assert( result.contains( acc1.Id ) );
        System.assert( result.contains( acc2.Id ) );
        System.assert( result.contains( acc3.Id ) );
        System.assert( result.contains( acc4.Id ) );
        System.assert( result.contains( acc5.Id ) );
        System.assert( result.contains( acc6.Id ) );
        System.assert( result.contains( acc7.Id ) );
        System.assert( result.contains( acc2_1.Id ) );
        System.assert( result.contains( acc2_2.Id ) );
        System.assert( result.contains( acc3_2_1.Id ) );
        System.assert( result.contains( acc5_1.Id ) );
    }

    @isTest static void getUltimateParentAccountIds() {
        Account acc0_1 = new Account( Name = 'acc0_1' );
        INSERT acc0_1;

        Account acc1_1 = new Account( Name = 'acc1_1' );
        INSERT acc1_1;

        Account acc1_2 = new Account( Name = 'acc1_2', ParentId = acc1_1.Id );
        INSERT acc1_2;

        Account acc1_3 = new Account( Name = 'acc1_3', ParentId = acc1_1.Id );
        INSERT acc1_3;

        Account acc2_1 = new Account( Name = 'acc2_1' );
        INSERT acc2_1;

        Account acc2_2 = new Account( Name = 'acc2_2', ParentId = acc2_1.Id );
        INSERT acc2_2;

        Map<Id, Id> result;

        Test.startTest();
            result = AccountHierarchyServices.getUltimateParentAccountIds( new Set<Id>{ acc0_1.Id, acc1_2.Id, acc2_1.Id, acc2_2.Id } );
        Test.stopTest();

        System.assert( result != null );
        System.assert( result.get( acc0_1.Id ) == acc0_1.Id );
        System.assert( result.get( acc1_2.Id ) == acc1_1.Id );
        System.assert( result.get( acc2_1.Id ) == acc2_1.Id );
        System.assert( result.get( acc2_2.Id ) == acc2_1.Id );
    }

    @isTest static void getAccountHierarchies() {
        Account acc0_1 = new Account( Name = 'acc0_1' );
        INSERT acc0_1;

        Account acc1_1 = new Account( Name = 'acc1_1' );
        INSERT acc1_1;

        Account acc1_2 = new Account( Name = 'acc1_2', ParentId = acc1_1.Id );
        INSERT acc1_2;

        Account acc1_3 = new Account( Name = 'acc1_3', ParentId = acc1_1.Id );
        INSERT acc1_3;

        Account acc2_1 = new Account( Name = 'acc2_1' );
        INSERT acc2_1;

        Account acc2_2 = new Account( Name = 'acc2_2', ParentId = acc2_1.Id );
        INSERT acc2_2;

        Map<Id, HierarchyNode> result;

        Test.startTest();
            result = AccountHierarchyServices.getAccountHierarchies( new Set<Id>{ acc0_1.Id, acc1_1.Id, acc2_1.Id } );
        Test.stopTest();

        System.assert( result != null );
        System.assert( result.containsKey( acc0_1.Id ) );
        System.assert( result.get( acc0_1.Id ) != null );
        System.assert( result.get( acc0_1.Id ).children != null );
        System.assert( result.get( acc0_1.Id ).getAllHierarchyIds().size() == 1 );
        System.assert( result.get( acc0_1.Id ).getAllHierarchyIds().contains( acc0_1.Id ) );

        System.assert( result.containsKey( acc1_1.Id ) );
        System.assert( result.get( acc1_1.Id ) != null );
        System.assert( result.get( acc1_1.Id ).children != null );
        System.assert( result.get( acc1_1.Id ).getAllHierarchyIds().size() == 3 );
        System.assert( result.get( acc1_1.Id ).getAllHierarchyIds().contains( acc1_1.Id ) );
        System.assert( result.get( acc1_1.Id ).getAllHierarchyIds().contains( acc1_2.Id ) );
        System.assert( result.get( acc1_1.Id ).getAllHierarchyIds().contains( acc1_3.Id ) );

        System.assert( result.containsKey( acc2_1.Id ) );
        System.assert( result.get( acc2_1.Id ) != null );
        System.assert( result.get( acc2_1.Id ).children != null );
        System.assert( result.get( acc2_1.Id ).getAllHierarchyIds().size() == 2 );
        System.assert( result.get( acc2_1.Id ).getAllHierarchyIds().contains( acc2_1.Id ) );
        System.assert( result.get( acc2_1.Id ).getAllHierarchyIds().contains( acc2_2.Id ) );
    }

}