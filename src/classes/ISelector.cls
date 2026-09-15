public interface ISelector {
  List<SObject> selectById(Set<Id> recordIds);
}
