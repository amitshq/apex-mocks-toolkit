/**
 * Worked example for BatchBase: re-runs round-robin assignment across
 * every Lead, one execute() chunk at a time, committing through
 * UnitOfWork - Crud + UnitOfWork + IAssigner + BatchBase together.
 */
public class LeadReassignmentBatch extends BatchBase {
  private final IUnitOfWork unitOfWork;
  private final IAssigner assigner;
  private final List<Id> salesRepIds;

  public LeadReassignmentBatch(List<Id> salesRepIds) {
    this(Application.UnitOfWork.newInstance(), new RoundRobinAssigner(), salesRepIds);
  }

  @testVisible
  private LeadReassignmentBatch(IUnitOfWork unitOfWork, IAssigner assigner, List<Id> salesRepIds) {
    this.unitOfWork = unitOfWork;
    this.assigner = assigner;
    this.salesRepIds = salesRepIds;
  }

  protected override Database.QueryLocator getQueryLocator() {
    return Database.getQueryLocator([SELECT Id, OwnerId FROM Lead]);
  }

  @testVisible
  protected override void processBatch(List<SObject> records) {
    if (this.salesRepIds.isEmpty() || records.isEmpty()) {
      return;
    }
    this.assigner.assign(records, this.salesRepIds, Lead.OwnerId);
    this.unitOfWork.registerDirty(records);
    this.unitOfWork.commitWork();
  }
}
