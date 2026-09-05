/**
 * The read-side counterpart to Crud: subclasses declare which SObjectType
 * and fields they select, and this builds/runs the query. Mirrors the
 * fflib selector pattern this repo already compares itself against, kept
 * to the single method this toolkit's IAssigner/UnitOfWork classes
 * actually need.
 */
public abstract class Selector implements ISelector {
    public abstract Schema.SObjectType getSObjectType();
    public abstract List<Schema.SObjectField> getSObjectFieldList();

    public virtual List<SObject> selectById(Set<Id> recordIds) {
        return Database.query(this.buildBaseQuery() + ' WHERE Id IN :recordIds');
    }

    protected virtual String buildBaseQuery() {
        List<String> fieldNames = new List<String>();
        for(Schema.SObjectField field : this.getSObjectFieldList()) {
            fieldNames.add(field.getDescribe().getName());
        }
        return 'SELECT ' + String.join(fieldNames, ', ') + ' FROM ' + this.getSObjectType();
    }
}
