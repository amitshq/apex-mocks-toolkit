/**
 * The original benchmark's stated motivation cited "batch processes /
 * queueable tasks which process large numbers of records" - QueueableChainer
 * covers the queueable half; this covers Database.Batchable. Subclasses
 * implement getQueryLocator() and processBatch(); start()/execute()/finish()
 * are handled here, with a running total tracked via Database.Stateful.
 */
public abstract class BatchBase implements Database.Batchable<SObject>, Database.Stateful {
  private Integer totalProcessed = 0;

  public Database.QueryLocator start(Database.BatchableContext context) {
    return this.getQueryLocator();
  }

  public void execute(Database.BatchableContext context, List<SObject> records) {
    this.processBatch(records);
    this.totalProcessed += records.size();
  }

  public void finish(Database.BatchableContext context) {
    this.onFinish(this.totalProcessed);
  }

  public Integer getTotalProcessed() {
    return this.totalProcessed;
  }

  protected abstract Database.QueryLocator getQueryLocator();
  protected abstract void processBatch(List<SObject> records);
  protected virtual void onFinish(Integer totalProcessed) {
  }
}
