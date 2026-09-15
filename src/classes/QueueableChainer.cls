/**
 * A Queueable base class that only chains itself onward if
 * GovernorLimitGuard confirms there's still headroom for another
 * queueable job in this context - avoiding a
 * System.LimitException: Too many queueable jobs added when a chain
 * runs longer than expected. Subclasses implement run() (the actual
 * work for this link) and getNext() (the next link, or null to stop).
 */
public abstract class QueueableChainer implements Queueable {
  private final GovernorLimitGuard limitGuard;

  protected QueueableChainer() {
    this(new GovernorLimitGuard());
  }

  @testVisible
  private QueueableChainer(GovernorLimitGuard limitGuard) {
    this.limitGuard = limitGuard;
  }

  public void execute(QueueableContext context) {
    this.run();
    QueueableChainer next = this.getNext();
    if (next != null) {
      try {
        this.limitGuard.throwIfQueueableJobsNear(90);
        System.enqueueJob(next);
      } catch (GovernorLimitGuard.LimitGuardException ex) {
        this.onChainStopped(next);
      }
    }
  }

  protected abstract void run();
  protected abstract QueueableChainer getNext();
  protected virtual void onChainStopped(QueueableChainer nextThatDidNotRun) {
  }
}
