/**
 * A minimal System.StubProvider implementation used to benchmark Salesforce's
 * built-in stubbing API (Test.createStub) as a third mocking approach,
 * alongside fflib-apex-mocks and CrudMock, in ApexMocksTests.
 */
@isTest
public class CrudStubProvider implements System.StubProvider {
  public Integer callCount { get; private set; }

  public CrudStubProvider() {
    this.callCount = 0;
  }

  public Object handleMethodCall(
    Object stubbedObject,
    String stubbedMethodName,
    Type returnType,
    List<Type> listOfParamTypes,
    List<String> listOfParamNames,
    List<Object> listOfArgs
  ) {
    this.callCount++;
    return listOfArgs.isEmpty() ? null : listOfArgs[0];
  }
}
