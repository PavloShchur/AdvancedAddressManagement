@isTest
private class HierarchyNodeTest {

    @isTest static void init() {
        Id id = '001000000000000';

        Test.startTest();
            HierarchyNode node = new HierarchyNode( id );
        Test.stopTest();

        System.assert( node.id == id );
        System.assert( node.children != null );
        System.assert( node.children.isEmpty() );
    }

    @isTest static void getAllHierarchyIds() {
        Id id1 = '001000000000001';
        Id id2 = '001000000000002';
        Id id3 = '001000000000003';

        HierarchyNode node1 = new HierarchyNode( id1 );
        HierarchyNode node2 = new HierarchyNode( id2 );
        HierarchyNode node3 = new HierarchyNode( id3 );
        node1.children.add( node2 );
        node1.children.add( node3 );

        Test.startTest();
            Set<Id> allIds = node1.getAllHierarchyIds();
        Test.stopTest();

        System.assert( allIds != null );
        System.assert( allIds.contains( id1 ) );
        System.assert( allIds.contains( id2 ) );
        System.assert( allIds.contains( id3 ) );
    }

    @isTest static void getAllHierarchyIdsWithoutSpecifiedIds() {
        Id id1 = '001000000000001';
        Id id2 = '001000000000002';
        Id id3 = '001000000000003';

        HierarchyNode node1 = new HierarchyNode( id1 );
        HierarchyNode node2 = new HierarchyNode( id2 );
        HierarchyNode node3 = new HierarchyNode( id3 );
        node1.children.add( node2 );
        node1.children.add( node3 );

        Test.startTest();
            Set<Id> allIds = node1.getAllHierarchyIds( new Set<Id>{ id2 } );
        Test.stopTest();

        System.assert( allIds != null );
        System.assert( allIds.contains( id1 ) );
        System.assert( !allIds.contains( id2 ) );
        System.assert( allIds.contains( id3 ) );
    }

    @isTest static void getChildren() {
        Id id1 = '001000000000001';
        Id id2 = '001000000000002';
        Id id3 = '001000000000003';

        HierarchyNode node1 = new HierarchyNode( id1 );
        HierarchyNode node2 = new HierarchyNode( id2 );
        HierarchyNode node3 = new HierarchyNode( id3 );
        node1.children.add( node2 );
        node1.children.add( node3 );

        Test.startTest();
            List<HierarchyNode> childNodes = node1.getChildren( new Set<Id>{ id2 } );
        Test.stopTest();

        System.assert( childNodes != null );
        System.assertEquals( 1, childNodes.size() );
        System.assertEquals( 1, childNodes[0].getAllHierarchyIds().size() );
        System.assert( childNodes[0].getAllHierarchyIds().contains( id3 ) );
    }

    @isTest static void getHierarchyShards() {
        Id id1 = '001000000000001';
        Id id2 = '001000000000002';
        Id id3 = '001000000000003';

        HierarchyNode node1 = new HierarchyNode( id1 );
        HierarchyNode node2 = new HierarchyNode( id2 );
        HierarchyNode node3 = new HierarchyNode( id3 );
        node1.children.add( node2 );
        node1.children.add( node3 );

        Test.startTest();
            Map<Id, HierarchyNode> hierarchyShards = node1.getHierarchyShards( new Set<Id>{ id2 } );
        Test.stopTest();

        System.assert( hierarchyShards != null );
        System.assertEquals( 1, hierarchyShards.size() );
        System.assert( hierarchyShards.containsKey( id1 ) );
        Set<Id> hierarchyIds = hierarchyShards.get( id1 ).getAllHierarchyIds();
        System.assertEquals( 2, hierarchyIds.size() );
        System.assert( hierarchyIds.contains( id1 ) );
        System.assert( hierarchyIds.contains( id3 ) );
    }

}