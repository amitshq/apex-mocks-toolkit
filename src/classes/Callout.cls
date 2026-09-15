public virtual class Callout implements ICallout {
  public virtual HttpResponse send(HttpRequest request) {
    return new Http().send(request);
  }
}
