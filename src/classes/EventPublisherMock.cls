/**
 * Records published events in memory instead of touching the real event
 * bus. Returns an empty result list rather than a fabricated
 * Database.SaveResult - Apex doesn't allow constructing those directly -
 * so assert against PublishedEvents, not the return value.
 */
public virtual class EventPublisherMock implements IEventPublisher {
  public static List<SObject> PublishedEvents = new List<SObject>();

  public virtual List<Database.SaveResult> publish(List<SObject> events) {
    PublishedEvents.addAll(events);
    return new List<Database.SaveResult>();
  }
}
