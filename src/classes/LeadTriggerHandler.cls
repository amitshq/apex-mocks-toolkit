/**
 * Worked example tying the rest of this toolkit together: every newly
 * inserted Lead is round-robin assigned across LeadAssignmentConfig's
 * configured sales reps (beforeInsert), then a follow-up Task is queued
 * for the new owner and flushed through UnitOfWork (afterInsert). Swap
 * RoundRobinAssigner for RandomAssigner or LoadBalancedAssigner without
 * touching this class - that's the point of depending on IAssigner rather
 * than a concrete implementation.
 */
public class LeadTriggerHandler extends TriggerHandler {
  private final IUnitOfWork unitOfWork;
  private final IAssigner assigner;
  private final List<Id> salesRepIds;

  public LeadTriggerHandler() {
    this(Application.UnitOfWork.newInstance(), new RoundRobinAssigner(), LeadAssignmentConfig.salesRepIds);
  }

  @testVisible
  private LeadTriggerHandler(IUnitOfWork unitOfWork, IAssigner assigner, List<Id> salesRepIds) {
    this.unitOfWork = unitOfWork;
    this.assigner = assigner;
    this.salesRepIds = salesRepIds;
  }

  @testVisible
  protected override void beforeInsert(List<SObject> newRecords) {
    if (this.salesRepIds.isEmpty()) {
      return;
    }
    this.assigner.assign(newRecords, this.salesRepIds, Lead.OwnerId);
  }

  @testVisible
  protected override void afterInsert(List<SObject> newRecords) {
    if (this.salesRepIds.isEmpty()) {
      return;
    }
    for (SObject record : newRecords) {
      Lead lead = (Lead) record;
      this.unitOfWork.registerNew(
        new Task(WhoId = lead.Id, OwnerId = lead.OwnerId, Subject = 'Follow up with new lead', ActivityDate = System.today().addDays(1))
      );
    }
    this.unitOfWork.commitWork();
  }
}
