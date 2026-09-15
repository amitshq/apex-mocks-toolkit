@isTest
private class UnitOfWork_Tests {
  @isTest
  static void it_should_insert_registered_new_records_on_commit() {
    IUnitOfWork uow = new UnitOfWork(CrudMock.getMock());
    Account account = new Account(Name = 'Test');

    uow.registerNew(account);
    uow.commitWork();

    System.assertEquals(1, CrudMock.Inserted.size());
  }

  @isTest
  static void it_should_update_registered_dirty_records_on_commit() {
    IUnitOfWork uow = new UnitOfWork(CrudMock.getMock());
    Account account = new Account(Id = TestingUtils.generateId(Account.SObjectType), Name = 'Test');

    uow.registerDirty(account);
    uow.commitWork();

    System.assertEquals(1, CrudMock.Updated.size());
  }

  @isTest
  static void it_should_delete_registered_deleted_records_on_commit() {
    IUnitOfWork uow = new UnitOfWork(CrudMock.getMock());
    Account account = new Account(Id = TestingUtils.generateId(Account.SObjectType), Name = 'Test');

    uow.registerDeleted(account);
    uow.commitWork();

    System.assertEquals(1, CrudMock.Deleted.size());
  }

  @isTest
  static void it_should_ignore_dirty_records_without_an_id() {
    IUnitOfWork uow = new UnitOfWork(CrudMock.getMock());
    Account account = new Account(Name = 'Test');

    uow.registerDirty(account);
    uow.commitWork();

    System.assertEquals(0, CrudMock.Updated.size());
  }

  @isTest
  static void it_should_deregister_a_dirty_record_once_it_is_marked_deleted() {
    IUnitOfWork uow = new UnitOfWork(CrudMock.getMock());
    Account account = new Account(Id = TestingUtils.generateId(Account.SObjectType), Name = 'Test');

    uow.registerDirty(account);
    uow.registerDeleted(account);
    uow.commitWork();

    System.assertEquals(0, CrudMock.Updated.size());
    System.assertEquals(1, CrudMock.Deleted.size());
  }

  @isTest
  static void it_should_clear_registrations_after_commit() {
    IUnitOfWork uow = new UnitOfWork(CrudMock.getMock());
    Account account = new Account(Name = 'Test');
    uow.registerNew(account);
    uow.commitWork();

    uow.commitWork();

    System.assertEquals(1, CrudMock.Inserted.size());
  }

  @isTest
  static void it_should_perform_real_dml_when_committed_with_the_default_constructor() {
    IUnitOfWork uow = new UnitOfWork();
    Account account = new Account(Name = 'Test');

    uow.registerNew(account);
    uow.commitWork();

    System.assertNotEquals(null, account.Id);
  }
}
