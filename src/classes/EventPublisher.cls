public virtual class EventPublisher implements IEventPublisher {
  public virtual List<Database.SaveResult> publish(List<SObject> events) {
    return EventBus.publish(events);
  }
}
