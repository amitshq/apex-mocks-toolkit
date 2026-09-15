/**
 * Like RoundRobinAssigner, but each assignee can carry a different
 * weight - a weight of 2 gets roughly twice the volume of a weight of 1.
 * Assignees not present in the weight map default to a weight of 1.
 * Builds an expanded cycle from assigneeIds and their weights on every
 * call (e.g. {A: 2, B: 1} cycles A, A, B, A, A, B, ...).
 */
public class WeightedRoundRobinAssigner implements IAssigner {
  private final Map<Id, Integer> weightByAssigneeId;
  private Integer index = 0;

  public WeightedRoundRobinAssigner(Map<Id, Integer> weightByAssigneeId) {
    this.weightByAssigneeId = weightByAssigneeId;
  }

  public void assign(List<SObject> records, List<Id> assigneeIds, Schema.SObjectField ownerField) {
    List<Id> expandedCycle = this.buildExpandedCycle(assigneeIds);
    if (expandedCycle.isEmpty()) {
      throw new AssignerException('At least one assignee with a positive weight is required');
    }

    for (SObject record : records) {
      record.put(ownerField, expandedCycle[Math.mod(this.index, expandedCycle.size())]);
      this.index++;
    }
  }

  private List<Id> buildExpandedCycle(List<Id> assigneeIds) {
    List<Id> cycle = new List<Id>();
    for (Id assigneeId : assigneeIds) {
      Integer weight = this.weightByAssigneeId.containsKey(assigneeId) ? this.weightByAssigneeId.get(assigneeId) : 1;
      for (Integer i = 0; i < weight; i++) {
        cycle.add(assigneeId);
      }
    }
    return cycle;
  }
}
