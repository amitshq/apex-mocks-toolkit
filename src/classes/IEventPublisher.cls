public interface IEventPublisher {
  List<Database.SaveResult> publish(List<SObject> events);
}
