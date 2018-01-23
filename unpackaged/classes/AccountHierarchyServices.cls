public without sharing class AccountHierarchyServices {

    public static Set<Id> getAccountIds( Id accountId ) {
        if( accountId == null ) return new Set<Id>();
        Map<Id, Id> accIdToUltId = getUltimateParentAccountIds( new Set<Id>{ accountId } );
        Id ultimateParentId = accIdToUltId.get( accountId );
        return getAccountHierarchies( new Set<Id>{ ultimateParentId } ).get( ultimateParentId ).getAllHierarchyIds();
    }

    public static Map<Id, Id> getUltimateParentAccountIds( Set<Id> accountIds ) {
        Map<Id, Id> startingAccIdToUltId = new Map<Id, Id>();
        if( accountIds == null ) return startingAccIdToUltId;
        accountIds.remove( null );
        if( accountIds.isEmpty() ) return startingAccIdToUltId;
        for( Id accountId : accountIds ) {
            startingAccIdToUltId.put( accountId, accountId );
        }
        Set<Id> currentParendIds = startingAccIdToUltId.keySet();
        while( !currentParendIds.isEmpty() ) {
            Set<Id> parentIdsToQuery = new Set<Id>( currentParendIds );
            String query = 'SELECT ParentId, Parent.ParentId, Parent.Parent.ParentId, Parent.Parent.Parent.ParentId,';
            query +=             ' Parent.Parent.Parent.Parent.ParentId, Parent.Parent.Parent.Parent.Parent.ParentId';
            query +=      ' FROM Account';
            query +=      ' WHERE Id IN :parentIdsToQuery';
            currentParendIds = new Set<Id>();

            List<SObject> currentAccounts = Database.query( query );
            for( SObject currentAccount : currentAccounts ) {
                Set<Id> startingAccountIds = new Set<Id>();
                for( Id accountId : startingAccIdToUltId.keySet() ) {
                    if( startingAccIdToUltId.get( accountId ) != currentAccount.Id ) continue;
                    startingAccountIds.add( accountId );
                }
                Integer parentLevel = 0;
                Id parentId = (Id)currentAccount.get( 'ParentId' );
                while( parentId != null ) {
                    if( parentLevel != 0 ) currentAccount = currentAccount.getSObject( 'Parent' );
                    if( currentAccount != null ) parentId = (Id)currentAccount.get( 'ParentId' );
                    if( parentId != null ) {
                        for( Id startingAccountId : startingAccountIds ) {
                            startingAccIdToUltId.put( startingAccountId, parentId );
                        }
                        if( parentLevel == 5 ) { // 5 is maximum query depth
                            currentParendIds.add( parentId );
                            break;
                        }
                    }
                    parentLevel++;
                }
            }
        }
        return startingAccIdToUltId;
    }

    public static Map<Id, HierarchyNode> getAccountHierarchies( Set<Id> top_acct_ids ) {
        Map<Id, HierarchyNode> nodes = new Map<Id, HierarchyNode>();
        for( Id top_acct_id : top_acct_ids ) {
            nodes.put( top_acct_id, new HierarchyNode( top_acct_id ) );
        }
        Set<Id> parentAccIds = nodes.keySet();
        while( parentAccIds.size() > 0 ) {
            Map<Integer, List<Account>> levelToAccounts = new Map<Integer, List<Account>>();
            for( Integer level = 1; level <= 6; level++ ) {
                levelToAccounts.put( level, new List<Account>() );
            }
            for( Account acc : [ SELECT ParentId, Parent.ParentId, Parent.Parent.ParentId, Parent.Parent.Parent.ParentId,
                                        Parent.Parent.Parent.Parent.ParentId, Parent.Parent.Parent.Parent.Parent.ParentId
                                 FROM  Account
                                 WHERE ParentId IN :parentAccIds OR
                                       Parent.ParentId IN :parentAccIds OR
                                       Parent.Parent.ParentId IN :parentAccIds OR
                                       Parent.Parent.Parent.ParentId IN :parentAccIds OR
                                       Parent.Parent.Parent.Parent.ParentId IN :parentAccIds OR
                                       Parent.Parent.Parent.Parent.Parent.ParentId IN :parentAccIds] ) {
                Account account = acc;
                for( Integer level = 1; level <= 6; level++ ) {
                    if( level > 1 ) {
                        account = (Account)account.getSobject( 'Parent' );
                    }
                    Id parentId = account != null ? (Id)account.get( 'ParentId' ) : null;
                    if( parentId == null ) break;
                    if( !parentAccIds.contains( parentId ) ) continue;
                    levelToAccounts.get( level ).add( acc );
                    break;
                }
            }
            Set<Id> nextParentAccIds = new Set<Id>();
            for( Integer level = 1; level <= 6; level++ ) { //Add children on all levels found, one level at a time
                addChildren( levelToAccounts.get( level ), nodes, level == 6 ? nextParentAccIds : null );
                levelToAccounts.put( level, new List<Account>() );
            }
            parentAccIds = nextParentAccIds; //Use lowest level of account ids for next SOQL query
        }
        return nodes;
    }

    private static void addChildren( List<Account> accs, Map<Id, HierarchyNode> nodes, Set<Id> parentAccIds ) {
        for( Account acc : accs ) {
            HierarchyNode refNode = nodes.get( acc.ParentId );
            HierarchyNode newNode = new HierarchyNode( acc.Id );
            nodes.put( acc.id, newNode );
            if( refNode != null ) {
                refNode.children.add( newNode );
            }
            if( parentAccIds != null ) {
                parentAccIds.add( acc.id );
            }
        }
    }

}