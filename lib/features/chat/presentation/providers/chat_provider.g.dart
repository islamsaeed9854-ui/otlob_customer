// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Chat)
final chatProvider = ChatFamily._();

final class ChatProvider extends $NotifierProvider<Chat, List<Message>> {
  ChatProvider._({
    required ChatFamily super.from,
    required ChatArgs super.argument,
  }) : super(
         retry: null,
         name: r'chatProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatHash();

  @override
  String toString() {
    return r'chatProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  Chat create() => Chat();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Message> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Message>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChatProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatHash() => r'c62c905a7492513970968efb59c75c8b2fd3ffdf';

final class ChatFamily extends $Family
    with
        $ClassFamilyOverride<
          Chat,
          List<Message>,
          List<Message>,
          List<Message>,
          ChatArgs
        > {
  ChatFamily._()
    : super(
        retry: null,
        name: r'chatProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  ChatProvider call(ChatArgs args) =>
      ChatProvider._(argument: args, from: this);

  @override
  String toString() => r'chatProvider';
}

abstract class _$Chat extends $Notifier<List<Message>> {
  late final _$args = ref.$arg as ChatArgs;
  ChatArgs get args => _$args;

  List<Message> build(ChatArgs args);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<Message>, List<Message>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<Message>, List<Message>>,
              List<Message>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
