/**
 * Batches registered record changes into a single insert / update / delete
 * per commitWork() call, delegating the actual DML to an injected ICrud
 * (Crud for real DML, CrudMock in tests). Records without an Id are ignored
 * by registerDirty/registerDeleted since there's nothing to match against.
 */
public virtual class UnitOfWork implements IUnitOfWork {
  private final ICrud crud;
  private final List<SObject> newRecords = new List<SObject>();
  private final Map<Id, SObject> dirtyRecordsById = new Map<Id, SObject>();
  private final Map<Id, SObject> deletedRecordsById = new Map<Id, SObject>();

  public UnitOfWork() {
    this(new Crud());
  }

  public UnitOfWork(ICrud crud) {
    this.crud = crud;
  }

  public virtual void registerNew(SObject record) {
    this.registerNew(new List<SObject>{ record });
  }

  public virtual void registerNew(List<SObject> records) {
    this.newRecords.addAll(records);
  }

  public virtual void registerDirty(SObject record) {
    this.registerDirty(new List<SObject>{ record });
  }

  public virtual void registerDirty(List<SObject> records) {
    for (SObject record : records) {
      if (record.Id != null) {
        this.dirtyRecordsById.put(record.Id, record);
      }
    }
  }

  public virtual void registerDeleted(SObject record) {
    this.registerDeleted(new List<SObject>{ record });
  }

  public virtual void registerDeleted(List<SObject> records) {
    for (SObject record : records) {
      if (record.Id != null) {
        this.deletedRecordsById.put(record.Id, record);
        this.dirtyRecordsById.remove(record.Id);
      }
    }
  }

  public virtual void commitWork() {
    if (this.newRecords.isEmpty() == false) {
      this.crud.doInsert(this.newRecords);
    }
    if (this.dirtyRecordsById.isEmpty() == false) {
      this.crud.doUpdate(this.dirtyRecordsById.values());
    }
    if (this.deletedRecordsById.isEmpty() == false) {
      this.crud.doDelete(this.deletedRecordsById.values());
    }
    this.newRecords.clear();
    this.dirtyRecordsById.clear();
    this.deletedRecordsById.clear();
  }
}
