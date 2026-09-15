/**
 * Extracts which fields actually changed between two versions of the
 * same record - useful in TriggerHandler.beforeUpdate/afterUpdate, which
 * already receive oldRecordsById but nothing in this toolkit previously
 * did anything with it.
 */
public class SObjectComparer {
  public static Set<String> getChangedFields(SObject oldRecord, SObject newRecord, List<Schema.SObjectField> fieldsToCompare) {
    Set<String> changedFields = new Set<String>();
    for (Schema.SObjectField field : fieldsToCompare) {
      if (oldRecord.get(field) != newRecord.get(field)) {
        changedFields.add(field.getDescribe().getName());
      }
    }
    return changedFields;
  }

  public static Boolean hasChanged(SObject oldRecord, SObject newRecord, Schema.SObjectField field) {
    return oldRecord.get(field) != newRecord.get(field);
  }
}
