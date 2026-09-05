/**
 * Assigns each record to a uniformly random assignee. Useful when an even
 * long-run distribution matters more than any per-batch ordering guarantee.
 */
public class RandomAssigner implements IAssigner {
    public void assign(List<SObject> records, List<Id> assigneeIds, Schema.SObjectField ownerField) {
        if(assigneeIds == null || assigneeIds.isEmpty()) {
            throw new AssignerException('At least one assignee Id is required');
        }

        for(SObject record : records) {
            Integer randomIndex = Integer.valueOf(Math.floor(Math.random() * assigneeIds.size()));
            record.put(ownerField, assigneeIds[randomIndex]);
        }
    }
}
