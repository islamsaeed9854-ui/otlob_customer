sealed class Result<S, E> {
  const Result();

  R fold<R>(R Function(S value) onOk, R Function(E error) onErr) =>
      switch (this) {
        Ok(:final value) => onOk(value),
        Err(:final error) => onErr(error),
      };

  Result<U, E> map<U>(U Function(S value) transform) =>
      switch (this) {
        Ok(:final value) => Ok(transform(value)),
        Err(:final error) => Err(error),
      };

  S getOrElse(S defaultValue) =>
      switch (this) {
        Ok(:final value) => value,
        Err() => defaultValue,
      };
}

final class Ok<S, E> extends Result<S, E> {
  final S value;
  const Ok(this.value);
}

final class Err<S, E> extends Result<S, E> {
  final E error;
  const Err(this.error);
}