/**
 * Minimal trigger dispatch base class. A trigger's only job is to
 * instantiate its handler and call run(); the handler overrides whichever
 * lifecycle hooks it needs. There's no "before undelete" hook because the
 * platform doesn't fire one.
 */
public virtual class TriggerHandler {
  public void run() {
    if (Trigger.isBefore) {
      if (Trigger.isInsert) {
        this.beforeInsert(Trigger.new);
      } else if (Trigger.isUpdate) {
        this.beforeUpdate(Trigger.new, Trigger.oldMap);
      } else if (Trigger.isDelete) {
        this.beforeDelete(Trigger.old);
      }
    } else if (Trigger.isAfter) {
      if (Trigger.isInsert) {
        this.afterInsert(Trigger.new);
      } else if (Trigger.isUpdate) {
        this.afterUpdate(Trigger.new, Trigger.oldMap);
      } else if (Trigger.isDelete) {
        this.afterDelete(Trigger.old);
      } else if (Trigger.isUndelete) {
        this.afterUndelete(Trigger.new);
      }
    }
  }

  protected virtual void beforeInsert(List<SObject> newRecords) {
  }
  protected virtual void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecordsById) {
  }
  protected virtual void beforeDelete(List<SObject> oldRecords) {
  }
  protected virtual void afterInsert(List<SObject> newRecords) {
  }
  protected virtual void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecordsById) {
  }
  protected virtual void afterDelete(List<SObject> oldRecords) {
  }
  protected virtual void afterUndelete(List<SObject> newRecords) {
  }
}
