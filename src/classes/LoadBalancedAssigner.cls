/**
 * Assigns each record to whichever assignee currently holds the fewest
 * records, tracking a running load count as it assigns. Seed it with
 * pre-existing loads (e.g. open case counts pulled from a query) via the
 * constructor, and read getCurrentLoad() afterward to persist state
 * across transactions if needed.
 */
public class LoadBalancedAssigner implements IAssigner {
    private final Map<Id, Integer> currentLoadByAssigneeId;

    public LoadBalancedAssigner() {
        this(new Map<Id, Integer>());
    }

    public LoadBalancedAssigner(Map<Id, Integer> currentLoadByAssigneeId) {
        this.currentLoadByAssigneeId = currentLoadByAssigneeId.clone();
    }

    public void assign(List<SObject> records, List<Id> assigneeIds, Schema.SObjectField ownerField) {
        if(assigneeIds == null || assigneeIds.isEmpty()) {
            throw new AssignerException('At least one assignee Id is required');
        }

        for(Id assigneeId : assigneeIds) {
            if(this.currentLoadByAssigneeId.containsKey(assigneeId) == false) {
                this.currentLoadByAssigneeId.put(assigneeId, 0);
            }
        }

        for(SObject record : records) {
            Id leastBusyAssigneeId = this.getLeastBusyAssigneeId(assigneeIds);
            record.put(ownerField, leastBusyAssigneeId);
            this.currentLoadByAssigneeId.put(leastBusyAssigneeId, this.currentLoadByAssigneeId.get(leastBusyAssigneeId) + 1);
        }
    }

    public Map<Id, Integer> getCurrentLoad() {
        return this.currentLoadByAssigneeId.clone();
    }

    private Id getLeastBusyAssigneeId(List<Id> assigneeIds) {
        Id leastBusyAssigneeId;
        Integer lowestLoad;
        for(Id assigneeId : assigneeIds) {
            Integer load = this.currentLoadByAssigneeId.get(assigneeId);
            if(lowestLoad == null || load < lowestLoad) {
                lowestLoad = load;
                leastBusyAssigneeId = assigneeId;
            }
        }
        return leastBusyAssigneeId;
    }
}
