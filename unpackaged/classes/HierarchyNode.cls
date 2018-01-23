public without sharing class HierarchyNode {

    public Id id;
    public List<HierarchyNode> children;

    //returns all records within hierarchy including current one
    public Set<Id> getAllHierarchyIds() {
        Set<Id> result = new Set<Id>{ id };
        for( HierarchyNode node : children ) {
            result.addAll( node.getAllHierarchyIds() );
        }
        return result;
    }

    //returns all records within hierarchy including current one and excluding records with ids provided
    public Set<Id> getAllHierarchyIds( Set<Id> removedIds ) {
        Set<Id> result = getAllHierarchyIds();
        if( removedIds == null ) return result;
        result.removeAll( removedIds );
        return result;
    }

    //modifies hierarchy by removing all its parts that are cut after deleting records with ids provided
    //returns all notes that remain in the hierarchy from the perspective of the current node instance
    public List<HierarchyNode> getChildren( Set<Id> removedIds ) {
        List<HierarchyNode> newChildren = new List<HierarchyNode>();
        for( HierarchyNode child : children ) {
            if( removedIds.contains( child.id ) ) continue;
            child.children = child.getChildren( removedIds );
            newChildren.add( child );
        }
        return newChildren;
    }

    //returns new hierarchies that will emerge after removal of records with ids provided from the perspective of the current node instance
    public Map<Id, HierarchyNode> getHierarchyShards( Set<Id> removedIds ) {
        return getHierarchyShards( removedIds, null, null );
    }

    public Map<Id, HierarchyNode> getHierarchyShards( Set<Id> removedIds, Map<Id, HierarchyNode> hierarchies, Id parentId ) {
        if( hierarchies == null ) hierarchies = new Map<Id, HierarchyNode>();
        if( ( parentId == null || removedIds.contains( parentId ) ) && !removedIds.contains( id ) ) {
            if( hierarchies.get( id ) == null ) {
                HierarchyNode node = new HierarchyNode( id );
                node.children = getChildren( removedIds );
                hierarchies.put( id, node );
            }
        }
        for( HierarchyNode node : children ) {
            node.getHierarchyShards( removedIds, hierarchies, id );
        }
        return hierarchies;
    }

    public HierarchyNode( Id recordId ) {
        this.id = recordId;
        this.children = new List<HierarchyNode>();
    }

}