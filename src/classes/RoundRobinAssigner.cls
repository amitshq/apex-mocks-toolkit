/**
 * Cycles through assigneeIds in order, wrapping back to the start.
 * The 4-arg overload returns the index the *next* batch should resume
 * from - callers persist that themselves (Platform Cache, a Custom
 * Setting, a static variable within a single transaction, etc.) since
 * this class stays stateless between calls.
 */
public class RoundRobinAssigner implements IAssigner {
    public void assign(List<SObject> records, List<Id> assigneeIds, Schema.SObjectField ownerField) {
        this.assign(records, assigneeIds, ownerField, 0);
    }

    public Integer assign(List<SObject> records, List<Id> assigneeIds, Schema.SObjectField ownerField, Integer startIndex) {
        if(assigneeIds == null || assigneeIds.isEmpty()) {
            throw new AssignerException('At least one assignee Id is required');
        }

        Integer index = (startIndex == null || startIndex < 0) ? 0 : Math.mod(startIndex, assigneeIds.size());
        for(SObject record : records) {
            record.put(ownerField, assigneeIds[index]);
            index = Math.mod(index + 1, assigneeIds.size());
        }
        return index;
    }
}
