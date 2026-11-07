/// Riverpod 3 retries failing providers automatically with backoff, which keeps
/// the screen on a spinner instead of showing the error and Retry button. The app
/// turns that off globally: errors surface at once and the user decides to retry.
///
/// To retry one provider automatically, pass `retry:` on its `@Riverpod(...)`.
Duration? noProviderRetry(int retryCount, Object error) => null;
