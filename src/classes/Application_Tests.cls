@isTest
private class Application_Tests {
  @isTest
  static void it_should_return_a_real_crud_instance_by_default() {
    ICrud crud = Application.Crud.newInstance();

    System.assert(crud instanceof Crud);
  }

  @isTest
  static void it_should_return_the_configured_mock_crud_instance() {
    CrudMock mockCrud = new CrudMock();
    Application.Crud.setMock(mockCrud);

    ICrud crud = Application.Crud.newInstance();

    System.assertEquals(mockCrud, crud);
  }

  @isTest
  static void it_should_return_the_accounts_selector_by_default() {
    ISelector selector = Application.Selector.newInstance(Account.SObjectType);

    System.assert(selector instanceof AccountsSelector);
  }

  @isTest
  static void it_should_return_a_configured_mock_selector() {
    SelectorMock mockSelector = new SelectorMock();
    Application.Selector.setMock(Account.SObjectType, mockSelector);

    ISelector selector = Application.Selector.newInstance(Account.SObjectType);

    System.assertEquals(mockSelector, selector);
  }

  @isTest
  static void it_should_throw_for_an_unregistered_selector_type() {
    try {
      Application.Selector.newInstance(Contact.SObjectType);
      System.assert(false, 'Expected an Application.ApplicationException to be thrown');
    } catch (Application.ApplicationException ex) {
      System.assert(true);
    }
  }

  @isTest
  static void it_should_return_a_real_callout_instance_by_default() {
    ICallout callout = Application.Callout.newInstance();

    System.assert(callout instanceof Callout);
  }

  @isTest
  static void it_should_return_the_configured_mock_callout_instance() {
    CalloutMock mockCallout = new CalloutMock();
    Application.Callout.setMock(mockCallout);

    ICallout callout = Application.Callout.newInstance();

    System.assertEquals(mockCallout, callout);
  }

  @isTest
  static void it_should_return_a_real_unit_of_work_by_default() {
    IUnitOfWork uow = Application.UnitOfWork.newInstance();

    System.assert(uow instanceof UnitOfWork);
  }

  @isTest
  static void it_should_return_the_configured_mock_unit_of_work() {
    UnitOfWork mockUow = new UnitOfWork(new CrudMock());
    Application.UnitOfWork.setMock(mockUow);

    IUnitOfWork uow = Application.UnitOfWork.newInstance();

    System.assertEquals(mockUow, uow);
  }

  @isTest
  static void it_should_return_a_real_event_publisher_by_default() {
    IEventPublisher publisher = Application.EventPublisher.newInstance();

    System.assert(publisher instanceof EventPublisher);
  }

  @isTest
  static void it_should_return_the_configured_mock_event_publisher() {
    EventPublisherMock mockPublisher = new EventPublisherMock();
    Application.EventPublisher.setMock(mockPublisher);

    IEventPublisher publisher = Application.EventPublisher.newInstance();

    System.assertEquals(mockPublisher, publisher);
  }
}
