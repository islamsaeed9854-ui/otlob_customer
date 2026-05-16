// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_ticket_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SupportTicket)
final supportTicketProvider = SupportTicketProvider._();

final class SupportTicketProvider
    extends $AsyncNotifierProvider<SupportTicket, void> {
  SupportTicketProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supportTicketProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supportTicketHash();

  @$internal
  @override
  SupportTicket create() => SupportTicket();
}

String _$supportTicketHash() => r'036b8559f033adabc3ff2970010be297c8920702';

abstract class _$SupportTicket extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
