/**
 * Single place every mockable collaborator in this toolkit gets created
 * from. Production code calls Application.Crud.newInstance() instead of
 * `new Crud()` directly; a test that wants everything mocked calls
 * Application.Crud.setMock(new CrudMock()) once instead of threading DI
 * through every constructor by hand.
 */
public class Application {
  public static final CrudFactory Crud = new CrudFactory();
  public static final SelectorFactory Selector = new SelectorFactory();
  public static final CalloutFactory Callout = new CalloutFactory();
  public static final UnitOfWorkFactory UnitOfWork = new UnitOfWorkFactory();
  public static final EventPublisherFactory EventPublisher = new EventPublisherFactory();

  public virtual class CrudFactory {
    @testVisible
    private ICrud mockInstance;

    public virtual ICrud newInstance() {
      return this.mockInstance != null ? this.mockInstance : new Crud();
    }

    @testVisible
    private void setMock(ICrud mockInstance) {
      this.mockInstance = mockInstance;
    }
  }

  public virtual class SelectorFactory {
    @testVisible
    private Map<Schema.SObjectType, ISelector> mockInstanceBySObjectType = new Map<Schema.SObjectType, ISelector>();

    public virtual ISelector newInstance(Schema.SObjectType sObjectType) {
      if (this.mockInstanceBySObjectType.containsKey(sObjectType)) {
        return this.mockInstanceBySObjectType.get(sObjectType);
      }
      if (sObjectType == Account.SObjectType) {
        return new AccountsSelector();
      }
      throw new ApplicationException('No selector registered for ' + sObjectType);
    }

    @testVisible
    private void setMock(Schema.SObjectType sObjectType, ISelector mockInstance) {
      this.mockInstanceBySObjectType.put(sObjectType, mockInstance);
    }
  }

  public virtual class CalloutFactory {
    @testVisible
    private ICallout mockInstance;

    public virtual ICallout newInstance() {
      return this.mockInstance != null ? this.mockInstance : new Callout();
    }

    @testVisible
    private void setMock(ICallout mockInstance) {
      this.mockInstance = mockInstance;
    }
  }

  public virtual class UnitOfWorkFactory {
    @testVisible
    private IUnitOfWork mockInstance;

    public virtual IUnitOfWork newInstance() {
      return this.mockInstance != null ? this.mockInstance : new UnitOfWork(Application.Crud.newInstance());
    }

    @testVisible
    private void setMock(IUnitOfWork mockInstance) {
      this.mockInstance = mockInstance;
    }
  }

  public virtual class EventPublisherFactory {
    @testVisible
    private IEventPublisher mockInstance;

    public virtual IEventPublisher newInstance() {
      return this.mockInstance != null ? this.mockInstance : new EventPublisher();
    }

    @testVisible
    private void setMock(IEventPublisher mockInstance) {
      this.mockInstance = mockInstance;
    }
  }

  public class ApplicationException extends Exception {
  }
}
