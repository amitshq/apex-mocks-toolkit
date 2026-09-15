public class TestingUtils {
  private static Integer startingNumber = 1;

  public static String generateId(Schema.SObjectType sObjectType) {
    String result = String.valueOf(startingNumber++);
    Integer paddingLength = 12 - result.length();
    if (paddingLength < 0) {
      throw new TestingUtilsException('Exceeded the maximum number of fake Ids that can be generated: ' + startingNumber);
    }
    return sObjectType.getDescribe().getKeyPrefix() + '0'.repeat(paddingLength) + result;
  }

  public static SObject generateId(SObject objectInstance) {
    if (objectInstance.Id == null) {
      objectInstance.Id = generateId(objectInstance.getSObjectType());
    }
    return objectInstance;
  }

  public static void generateIds(List<SObject> records) {
    for (SObject record : records) {
      if (record.Id == null) {
        generateId(record);
      }
    }
  }

  public class TestingUtilsException extends Exception {
  }
}
