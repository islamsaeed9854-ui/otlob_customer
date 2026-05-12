import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/message.dart';
import '../providers/chat_provider.dart';
import '../widgets/order_offer_bottom_sheet.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String type;
  final String title;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.type,
    required this.title,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final ChatArgs _args;
  FlutterSoundRecorder? _recorder;
  bool _isRecorderInitialized = false;
  bool _isRecording = false;
  String? _recordingPath;
  StreamSubscription? _recordingSubscription;
  Duration _recordingDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _args = ChatArgs(id: widget.conversationId, type: widget.type);
    _initRecorder();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      return;
    }
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
    _recorder!.setSubscriptionDuration(const Duration(milliseconds: 100));
    setState(() {
      _isRecorderInitialized = true;
    });
  }

  @override
  void dispose() {
    _recordingSubscription?.cancel();
    _recorder?.closeRecorder();
    _recorder = null;
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final ext = path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).onlyImagesAllowed), backgroundColor: Colors.red),
        );
        return;
      }
      ref.read(chatProvider(_args).notifier).sendMedia(path, MessageType.image);
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final ext = path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).onlyImagesAllowed), backgroundColor: Colors.red),
        );
        return;
      }
      ref.read(chatProvider(_args).notifier).sendMedia(path, MessageType.image);
    }
  }

  Future<void> _startRecording() async {
    if (!_isRecorderInitialized) return;
    final tempDir = await getTemporaryDirectory();
    _recordingPath = '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.aac';
    await _recorder!.startRecorder(toFile: _recordingPath);
    _recordingSubscription = _recorder!.onProgress!.listen((e) {
      if (mounted) {
        setState(() {
          _recordingDuration = e.duration;
        });
      }
    });
    setState(() {
      _isRecording = true;
      _recordingDuration = Duration.zero;
    });
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    await _recorder!.stopRecorder();
    _recordingSubscription?.cancel();

    final duration = _recordingDuration;

    setState(() {
      _isRecording = false;
      _recordingDuration = Duration.zero;
    });

    if (_recordingPath != null) {
      final file = File(_recordingPath!);
      if (await file.exists()) {
        final size = await file.length();
        if (size < 100 || duration.inMilliseconds < 800) {
          await file.delete();
          return;
        }
      }
      ref.read(chatProvider(_args).notifier).sendMedia(_recordingPath!, MessageType.audio);
    }
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    ref.read(chatProvider(_args).notifier).sendMessage(_controller.text.trim());
    _controller.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatProvider(_args));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) => ListView.builder(
                controller: _scrollController,
                reverse: true, // Start from bottom
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  return GestureDetector(
                    key: ValueKey(msg.id),
                    onLongPress: msg.isMe ? () => _showOptions(msg) : null,
                    child: _buildMessage(msg),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  void _showOptions(Message msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (msg.type == MessageType.text)
              ListTile(
                leading: const Icon(Icons.edit, color: AppColors.primary),
                title: Text(AppStrings.of(context).edit),
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(msg);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(AppStrings.of(context).delete, style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(msg.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppStrings.of(context).deleteConfirmTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(AppStrings.of(context).deleteConfirmBody),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: Text(AppStrings.of(context).cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(messageId);
            },
            child: Text(
              AppStrings.of(context).delete,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteMessage(String messageId) {
    ref.read(chatProvider(_args).notifier).deleteMessage(messageId);
  }

  void _editMessage(Message msg) {
    final editController = TextEditingController(text: msg.content);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.of(context).edit),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter new text'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final newText = editController.text.trim();
              if (newText.isNotEmpty && newText != msg.content) {
                ref.read(chatProvider(_args).notifier).editMessage(msg.id, newText);
              }
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(Message msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          gradient: msg.isMe ? AppColors.primaryGradient : null,
          color: msg.isMe 
              ? null 
              : (isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(msg.isMe ? 20 : 4),
            bottomRight: Radius.circular(msg.isMe ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!msg.isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4),
                child: Text(msg.senderName ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
            if (msg.type == MessageType.image)
              msg.mediaUrl == null 
                ? _buildUploadingState(isDark)
                : ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.6,
                      maxHeight: 250,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        msg.mediaUrl!, 
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.black12,
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        },
                      ),
                    ),
                  ),
            if (msg.type == MessageType.audio)
              msg.mediaUrl == null 
                ? _buildUploadingState(isDark)
                : _AudioPlayerWidget(url: msg.mediaUrl!, isMe: msg.isMe),
            if (msg.type == MessageType.file && msg.mediaUrl != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description, color: msg.isMe ? Colors.white : AppColors.primary),
                  const SizedBox(width: 8),
                  Flexible(child: Text('File Attachment', style: TextStyle(color: msg.isMe ? Colors.white : (isDark ? Colors.white : Colors.black87)))),
                ],
              ),
            if (msg.content.isNotEmpty && msg.mediaUrl != null) // Only show text if media is also present or if it's a text message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(msg.content, style: TextStyle(color: msg.isMe ? Colors.white : (isDark ? Colors.white : Colors.black87))),
              ),
            if (msg.type == MessageType.text && msg.content.isNotEmpty && msg.metadata?['type'] != 'OFFER')
               Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(msg.content, style: TextStyle(color: msg.isMe ? Colors.white : (isDark ? Colors.white : Colors.black87))),
              ),
            if (msg.metadata?['type'] == 'OFFER')
              _buildOfferBubble(msg, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferBubble(Message msg, bool isDark) {
    final s = AppStrings.of(context);
    final product = msg.metadata?['product'] as Map<String, dynamic>?;
    if (product == null) return const SizedBox();

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => OrderOfferBottomSheet(
            product: product,
            vendorId: widget.conversationId, // In vendor chat, this is the vendorId
            vendorName: widget.title, // In vendor chat, this is the vendorName
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: msg.isMe ? Colors.white.withOpacity(0.1) : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: msg.isMe ? Colors.white.withOpacity(0.2) : AppColors.primary.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.package, color: msg.isMe ? Colors.white : AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.offerTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: msg.isMe ? Colors.white : AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (product['image'] != null && product['image'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: ImageUtils.formatImageUrl(product['image'] as String?),
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 120,
                      color: Colors.grey.withOpacity(0.1),
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  ),
                ),
              ),
            Text(
              product['name'] ?? '',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: msg.isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${product['price']} ${s.egp}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: msg.isMe ? Colors.white70 : AppColors.primary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => OrderOfferBottomSheet(
                      product: product,
                      vendorId: widget.conversationId,
                      vendorName: widget.title,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: msg.isMe ? Colors.white : AppColors.primary,
                  foregroundColor: msg.isMe ? AppColors.primary : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(s.viewOffer, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadingState(bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          AppStrings.of(context).uploading,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
        top: 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Directionality(
        textDirection: ui.TextDirection.ltr,
        child: Row(
          children: [
            GestureDetector(
              onLongPress: _startRecording,
              onLongPressUp: _stopRecording,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isRecording ? AppColors.error.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isRecording ? AppColors.error.withOpacity(0.3) : AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _isRecording ? LucideIcons.stopCircle : LucideIcons.mic,
                  color: _isRecording ? AppColors.error : AppColors.primary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF383838) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    _isRecording
                        ? Expanded(
                            child: Row(
                              children: [
                                const SizedBox(width: 12),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_recordingDuration.inMinutes.toString().padLeft(2, "0")}:${(_recordingDuration.inSeconds % 60).toString().padLeft(2, "0")}',
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const Spacer(),
                                Flexible(
                                  child: Text(
                                    AppStrings.of(context).releaseToSend,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                            ),
                          )
                        : Expanded(
                            child: Directionality(
                              textDirection: Directionality.of(context),
                              child: TextField(
                                controller: _controller,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15),
                                decoration: InputDecoration(
                                  hintText: AppStrings.of(context).typeAMessage,
                                  hintStyle: TextStyle(color: Colors.grey.shade500),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                          ),
                    IconButton(
                      icon: const Icon(LucideIcons.image, color: AppColors.textHint, size: 18),
                      onPressed: _pickDocument,
                      padding: const EdgeInsets.only(right: 12),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                height: 44,
                width: 44,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: const Icon(LucideIcons.send, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioPlayerWidget extends StatefulWidget {
  final String url;
  final bool isMe;

  const _AudioPlayerWidget({Key? key, required this.url, required this.isMe}) : super(key: key);

  @override
  State<_AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<_AudioPlayerWidget> {
  FlutterSoundPlayer? _player;
  bool _isPlaying = false;
  bool _isPlayerInitialized = false;
  StreamSubscription? _playerSubscription;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _player = FlutterSoundPlayer();
    await _player!.openPlayer();
    _player!.setSubscriptionDuration(const Duration(milliseconds: 100));
    _playerSubscription = _player!.onProgress!.listen((e) {
      if (mounted) {
        setState(() {
          _position = e.position;
          _duration = e.duration;
        });
      }
    });
    if (mounted) {
      setState(() {
        _isPlayerInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _playerSubscription?.cancel();
    _player?.closePlayer();
    _player = null;
    super.dispose();
  }

  Future<void> _playPause() async {
    if (!_isPlayerInitialized || _player == null) return;
    
    if (_isPlaying) {
      await _player!.pausePlayer();
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    } else {
      if (_player!.isPaused) {
        await _player!.resumePlayer();
        if (mounted) {
          setState(() => _isPlaying = true);
        }
      } else {
        if (mounted) {
          setState(() => _isPlaying = true);
        }
        try {
          await _player!.startPlayer(
            fromURI: widget.url,
            whenFinished: () {
              if (mounted) {
                setState(() {
                  _isPlaying = false;
                  _position = Duration.zero;
                });
              }
            },
          );
        } catch (e) {
          print('Error playing audio: $e');
          if (mounted) {
            setState(() => _isPlaying = false);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String posStr = "${_position.inMinutes.toString().padLeft(2, "0")}:${(_position.inSeconds % 60).toString().padLeft(2, "0")}";
    String durStr = "${_duration.inMinutes.toString().padLeft(2, "0")}:${(_duration.inSeconds % 60).toString().padLeft(2, "0")}";
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _playPause,
          child: Icon(
            _isPlaying ? LucideIcons.pauseCircle : LucideIcons.playCircle,
            color: widget.isMe ? Colors.white : AppColors.primary,
            size: 32,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              height: 20,
              child: SliderTheme(
                data: SliderThemeData(
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  trackHeight: 2,
                ),
                child: Slider(
                  value: _duration.inMilliseconds > 0 
                      ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0) 
                      : 0.0,
                  activeColor: widget.isMe ? Colors.white : AppColors.primary,
                  inactiveColor: widget.isMe ? Colors.white.withOpacity(0.3) : AppColors.primary.withOpacity(0.2),
                  onChanged: (val) async {
                    if (_duration != Duration.zero && _player != null) {
                      final position = val * _duration.inMilliseconds;
                      await _player!.seekToPlayer(Duration(milliseconds: position.round()));
                    }
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                _duration == Duration.zero ? AppStrings.of(context).voiceMessage : "$posStr / $durStr",
                style: TextStyle(
                  fontSize: 10,
                  color: widget.isMe ? Colors.white.withOpacity(0.8) : AppColors.textHint,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
