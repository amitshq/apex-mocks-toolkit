/**
 * Common contract for record-assignment strategies (round robin, random,
 * load balanced, ...). Implementations set ownerField on each record in
 * records, choosing from assigneeIds according to their own strategy.
 */
public interface IAssigner {
  void assign(List<SObject> records, List<Id> assigneeIds, Schema.SObjectField ownerField);
}
