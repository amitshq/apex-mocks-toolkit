/**
 * ICrud implementation that enforces field- and object-level security.
 * Create/update/upsert paths run Security.stripInaccessible before the
 * underlying DML, silently dropping fields the running user can't touch
 * (the platform-recommended alternative to a hard failure). Delete/hard
 * delete paths check object-level delete access up front and throw, since
 * there's no field to strip - either the user can delete the object or
 * they can't. The most recent SObjectAccessDecision is exposed via
 * getLastAccessDecision() so callers/tests can inspect what was stripped.
 */
public virtual class SecureCrud extends Crud {
    @testVisible
    private SObjectAccessDecision lastAccessDecision;

    public SObjectAccessDecision getLastAccessDecision() {
        return this.lastAccessDecision;
    }

    public override List<SObject> doInsert(List<SObject> records) {
        return super.doInsert(this.stripInaccessibleFields(System.AccessType.CREATABLE, records));
    }

    public override List<SObject> doUpdate(List<SObject> records) {
        return super.doUpdate(this.stripInaccessibleFields(System.AccessType.UPDATABLE, records));
    }

    public override List<SObject> doUpsert(List<SObject> records) {
        return super.doUpsert(this.stripInaccessibleFields(System.AccessType.UPSERTABLE, records));
    }

    public override List<SObject> doUpsert(List<SObject> records, Schema.SObjectField externalIdField) {
        return super.doUpsert(this.stripInaccessibleFields(System.AccessType.UPSERTABLE, records), externalIdField);
    }

    public override void doDelete(List<SObject> records) {
        this.enforceObjectIsDeletable(records);
        super.doDelete(records);
    }

    public override void doHardDelete(List<SObject> records) {
        this.enforceObjectIsDeletable(records);
        super.doHardDelete(records);
    }

    private List<SObject> stripInaccessibleFields(System.AccessType accessType, List<SObject> records) {
        this.lastAccessDecision = Security.stripInaccessible(accessType, records);
        return this.lastAccessDecision.getRecords();
    }

    private void enforceObjectIsDeletable(List<SObject> records) {
        Set<Schema.SObjectType> checkedTypes = new Set<Schema.SObjectType>();
        for(SObject record : records) {
            Schema.SObjectType sObjectType = record.getSObjectType();
            if(checkedTypes.add(sObjectType) && sObjectType.getDescribe().isDeletable() == false) {
                throw new SecureCrudException('Insufficient permissions to delete ' + sObjectType);
            }
        }
    }

    public class SecureCrudException extends Exception {}
}
