import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../core/widgets/mashwar_user_avatar.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/repositories/app_repositories.dart';
import '../../state/auth_provider.dart';
import '../../state/rides_provider.dart';
import '../../state/settings_provider.dart';
import '../escrow/service_escrow_screen.dart';

class ChatScreen extends StatefulWidget {
  final String driverName;
  final String driverCar;
  final String tripRoute;
  final String? chatId;
  final String? driverPhone;

  const ChatScreen({
    super.key,
    this.driverName = 'جاسم الكواري',
    this.driverCar = 'تويوتا كامري، أبيض لؤلؤي (قطر 482910)',
    this.tripRoute = 'الدوحة ← الخور',
    this.chatId,
    this.driverPhone,
  });

  /// Deterministically derives a conversation ID from [chatId] or
  /// [driverName] + [tripRoute] so re-opening the screen restores messages.
  static String resolveChatId({
    String? chatId,
    required String driverName,
    required String tripRoute,
  }) {
    if (chatId != null && chatId.trim().isNotEmpty) {
      return chatId.trim();
    }
    final raw = '${driverName.trim()}_${tripRoute.trim()}'.toLowerCase();
    final sanitized = raw
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[/\\?#\[\]]'), '-');
    return 'chat_${sanitized.isEmpty ? "default" : sanitized}';
  }

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static final RegExp _urlRegex = RegExp(r'https?://[^\s]+');

  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessageModel> _messages = <ChatMessageModel>[];
  bool _isLoading = true;

  static const List<String> _quickChipsAr = [
    'أنا عند نقطة الالتقاء الآن',
    'أرفقت صورة الفاتورة في الضمان',
    'شاركني الموقع الدقيق',
    'جاهز للتسليم ومطابقة كود OTP',
  ];

  static const List<String> _quickChipsEn = [
    'I arrived at meetup spot',
    'Uploaded store receipt to Escrow',
    'Share exact location',
    'Ready to settle with 4-digit OTP',
  ];

  String get _effectiveChatId => ChatScreen.resolveChatId(
        chatId: widget.chatId,
        driverName: widget.driverName,
        tripRoute: widget.tripRoute,
      );

  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
  }

  Future<void> _loadInitialMessages() async {
    try {
      final loaded = await AppRepositories.instance.chat.getMessages(
        _effectiveChatId,
        peerName: widget.driverName,
        routeContext: widget.tripRoute,
      );
      if (!mounted) return;
      setState(() {
        _messages = List<ChatMessageModel>.from(loaded);
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (target > 0) {
        _scrollController.jumpTo(target);
      }
    });
  }

  String _resolveMySenderId() {
    final auth = Provider.of<AuthProvider?>(context, listen: false);
    final uid = auth?.user.id.trim() ?? '';
    return uid.isNotEmpty ? uid : 'usr_me_local';
  }

  String _resolveMySenderName(bool isAr) {
    final auth = Provider.of<AuthProvider?>(context, listen: false);
    final name = auth?.user.fullName.trim() ?? '';
    if (name.length >= 2) return name;
    return isAr ? 'مستخدم مشوار' : 'Mashwar User';
  }

  bool _isMyMessage(ChatMessageModel msg) {
    if (msg.senderId == 'peer_seed' || msg.senderId.startsWith('peer_')) {
      return false;
    }
    final myId = _resolveMySenderId();
    return msg.senderId == myId || msg.senderId == 'usr_me_local';
  }

  Future<void> _sendMessage([String? quickText]) async {
    final text = (quickText ?? _msgController.text).trim();
    if (text.isEmpty) return;

    final isAr = Provider.of<SettingsProvider?>(context, listen: false)?.isArabic ?? true;
    if (quickText == null) {
      _msgController.clear();
    }

    final senderId = _resolveMySenderId();
    final senderName = _resolveMySenderName(isAr);

    try {
      final saved = await AppRepositories.instance.chat.sendMessage(
        conversationId: _effectiveChatId,
        senderId: senderId,
        senderName: senderName,
        text: text,
      );
      if (!mounted) return;
      setState(() {
        _messages = List<ChatMessageModel>.from(_messages)..add(saved);
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      final fallback = ChatMessageModel(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: _effectiveChatId,
        senderId: senderId,
        senderName: senderName,
        text: text,
        timestamp: DateTime.now(),
        isRead: true,
      );
      setState(() {
        _messages = List<ChatMessageModel>.from(_messages)..add(fallback);
      });
      _scrollToBottom();
    }
  }

  String _extractOriginLocation(bool isAr) {
    final parts = widget.tripRoute.split(RegExp(r'\s*[←→·-]\s*'));
    for (final p in parts) {
      final clean = p.trim();
      if (clean.isNotEmpty) return clean;
    }
    return isAr ? 'الدوحة' : 'Doha';
  }

  Future<void> _shareLocation(bool isAr) async {
    final origin = _extractOriginLocation(isAr);
    final encodedQuery = Uri.encodeComponent('$origin, Qatar');
    final mapsUrl = 'https://www.google.com/maps/search/?api=1&query=$encodedQuery';
    final messageText = isAr
        ? 'مشاركة الموقع الحالي لنقطة الالتقاء ($origin):\n$mapsUrl'
        : 'Shared current meetup location ($origin):\n$mapsUrl';
    await _sendMessage(messageText);
  }

  String _resolveDriverPhone() {
    final explicit = widget.driverPhone?.trim() ?? '';
    if (explicit.isNotEmpty) return explicit;

    final rides = Provider.of<RidesProvider?>(context, listen: false);
    if (rides != null) {
      for (final r in rides.allRides) {
        if (r.driverName.trim() == widget.driverName.trim() &&
            r.driverPhone.trim().isNotEmpty) {
          return r.driverPhone.trim();
        }
      }
    }
    return '+97455234567';
  }

  String _normalizeDialablePhone(String raw) {
    final digitsAndPlus = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digitsAndPlus.isEmpty) return '+97455234567';
    if (digitsAndPlus.startsWith('+')) return digitsAndPlus;
    if (digitsAndPlus.length == 8) return '+974$digitsAndPlus';
    return '+$digitsAndPlus';
  }

  Future<void> _callDriver(bool isAr) async {
    final rawPhone = _resolveDriverPhone();
    final dialable = _normalizeDialablePhone(rawPhone);
    final telUri = Uri(scheme: 'tel', path: dialable);

    bool launched = false;
    try {
      launched = await launchUrl(telUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'الاتصال المباشر بـ ${widget.driverName} على $dialable'
                : 'Dialing ${widget.driverName} at $dialable',
          ),
          backgroundColor: AppColors.navy,
        ),
      );
    }
  }

  Future<void> _openMessageUrl(String url, bool isAr) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    bool launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'رابط الخريطة جاهز: $url'
                : 'Google Maps link ready: $url',
          ),
          backgroundColor: AppColors.navy,
        ),
      );
    }
  }

  String _displayMessageBody(ChatMessageModel msg, bool isAr) {
    if (!isAr && msg.id.startsWith('seed_1_')) {
      return 'Hello! I am ready to coordinate regarding (${widget.tripRoute}) on schedule.';
    }
    if (!isAr && msg.id.startsWith('seed_2_')) {
      return 'Please share your exact location when you arrive at the meetup point.';
    }
    return msg.text;
  }

  String _formatTimestamp(DateTime ts, bool isAr) {
    final now = DateTime.now();
    if (now.difference(ts).inSeconds.abs() < 45) {
      return isAr ? 'الآن' : 'Now';
    }
    final hour24 = ts.hour;
    final minute = ts.minute.toString().padLeft(2, '0');
    final isPm = hour24 >= 12;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final suffix = isAr ? (isPm ? 'م' : 'ص') : (isPm ? 'PM' : 'AM');
    return '$hour12:$minute $suffix';
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider?>(context);
    final isAr = settings?.isArabic ?? true;
    final quickChips = isAr ? _quickChipsAr : _quickChipsEn;

    return Scaffold(
      backgroundColor: AppColors.slateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: const BackButton(color: AppColors.navy),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.slateBorder),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            MashwarUserAvatar(
              avatarUrl: null,
              fullName: widget.driverName,
              size: 38,
              borderWidth: 1.0,
              borderColor: AppColors.slateBorder,
              autoCommunityPortrait: true,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.driverName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.title().copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      MashwarBadge(
                        type: BadgeType.verified,
                        customLabel: isAr ? 'موثق' : 'Verified',
                      ),
                    ],
                  ),
                  Text(
                    widget.driverCar,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label(color: AppColors.textSecondary).copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: IconButton(
              key: const ValueKey('chat_call_btn'),
              tooltip: isAr ? 'اتصال بالسائق' : 'Call Driver',
              onPressed: () => _callDriver(isAr),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.slateBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.slateBorder),
                ),
                child: const Icon(
                  Icons.phone_in_talk_rounded,
                  color: AppColors.navy,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                // Route Context + Escrow & Share Location Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: AppColors.slateBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.route_rounded,
                        color: AppColors.teal,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.tripRoute,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.label(color: AppColors.navy).copyWith(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      MashwarPressable(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          Navigator.of(context).push(
                            MashwarPageRoute(
                              builder: (_) => const ServiceEscrowScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.tealSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.teal.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_user_outlined,
                                size: 13,
                                color: AppColors.teal,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isAr ? 'الضمان و OTP' : 'Escrow',
                                style: AppTypography.label(color: AppColors.teal).copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      MashwarPressable(
                        key: const ValueKey('chat_share_location_btn'),
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _shareLocation(isAr),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.slateBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.my_location_rounded,
                                size: 13,
                                color: AppColors.navy,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isAr ? 'مشاركة الموقع' : 'Share Location',
                                style: AppTypography.label(color: AppColors.navy).copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Calm Executive Safety Notice
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: const BoxDecoration(
                    color: AppColors.sand,
                    border: Border(
                      bottom: BorderSide(color: AppColors.slateBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: AppColors.teal,
                        size: 15,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isAr
                              ? 'أمان مشوار: لا تشارك بياناتك البنكية أو رمز التسليم OTP داخل المحادثة.'
                              : 'Safety notice: Never share bank cards or handover OTP codes in chat.',
                          style: AppTypography.label(color: AppColors.navy).copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Messages List
                Expanded(
                  child: _isLoading && _messages.isEmpty
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.navy,
                            ),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final bubbleMaxWidth =
                                (constraints.maxWidth * 0.78).clamp(200.0, 520.0);
                            return ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(AppDimens.space16),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final msg = _messages[index];
                                final isMe = _isMyMessage(msg);
                                final bodyText = _displayMessageBody(msg, isAr);
                                final displayTime = _formatTimestamp(msg.timestamp, isAr);
                                final urlMatch = _urlRegex.firstMatch(bodyText);
                                final detectedUrl = urlMatch?.group(0);

                                return MashwarFadeSlideIn(
                                  duration: const Duration(milliseconds: 200),
                                  offsetY: 6,
                                  child: Align(
                                    alignment: isMe
                                        ? AlignmentDirectional.centerEnd
                                        : AlignmentDirectional.centerStart,
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isMe ? AppColors.navy : Colors.white,
                                        border: isMe
                                            ? null
                                            : Border.all(
                                                color: AppColors.slateBorder,
                                                width: 1.0,
                                              ),
                                        borderRadius: BorderRadiusDirectional.only(
                                          topStart: const Radius.circular(16),
                                          topEnd: const Radius.circular(16),
                                          bottomStart: Radius.circular(isMe ? 16 : 4),
                                          bottomEnd: Radius.circular(isMe ? 4 : 16),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: isMe
                                            ? CrossAxisAlignment.end
                                            : CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            bodyText,
                                            style: AppTypography.bodySecondary(
                                              color: isMe
                                                  ? Colors.white
                                                  : AppColors.textPrimary,
                                            ).copyWith(height: 1.45),
                                          ),
                                          if (detectedUrl != null) ...[
                                            const SizedBox(height: 8),
                                            InkWell(
                                              borderRadius: BorderRadius.circular(8),
                                              onTap: () => _openMessageUrl(detectedUrl, isAr),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isMe
                                                      ? Colors.white.withValues(alpha: 0.14)
                                                      : AppColors.slateBg,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: isMe
                                                        ? Colors.white.withValues(alpha: 0.24)
                                                        : AppColors.slateBorder,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.map_outlined,
                                                      size: 14,
                                                      color: isMe
                                                          ? Colors.white
                                                          : AppColors.teal,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Flexible(
                                                      child: Text(
                                                        isAr
                                                            ? 'فتح الموقع في Google Maps'
                                                            : 'Open in Google Maps',
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: AppTypography.label(
                                                          color: isMe
                                                              ? Colors.white
                                                              : AppColors.navy,
                                                        ).copyWith(
                                                          fontSize: 11.5,
                                                          fontWeight: FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                displayTime,
                                                style: AppTypography.label(
                                                  color: isMe
                                                      ? Colors.white70
                                                      : AppColors.textSecondary,
                                                ).copyWith(fontSize: 10.5),
                                              ),
                                              if (isMe) ...[
                                                const SizedBox(width: 4),
                                                const Icon(
                                                  Icons.done_all_rounded,
                                                  size: 13,
                                                  color: Colors.white70,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),

                // Quick Reply Chips
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    scrollDirection: Axis.horizontal,
                    itemCount: quickChips.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final chipText = quickChips[index];
                      return MashwarPressable(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          if (index == 2) {
                            _shareLocation(isAr);
                          } else {
                            _sendMessage(chipText);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.slateBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 13,
                                color: AppColors.teal,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                chipText,
                                style: AppTypography.label(color: AppColors.navy).copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // Chat Input Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: AppColors.slateBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const ValueKey('chat_message_input'),
                          controller: _msgController,
                          style: AppTypography.body().copyWith(fontSize: 14),
                          decoration: InputDecoration(
                            hintText:
                                isAr ? 'اكتب رسالتك هنا...' : 'Type your message...',
                            hintStyle: AppTypography.bodySecondary().copyWith(
                              fontSize: 13.5,
                            ),
                            filled: true,
                            fillColor: AppColors.slateBg,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 11,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: AppColors.slateBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: AppColors.slateBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: AppColors.navy,
                                width: 1.4,
                              ),
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: AppColors.navy,
                        shape: const CircleBorder(),
                        child: IconButton(
                          key: const ValueKey('chat_send_btn'),
                          tooltip: isAr ? 'إرسال' : 'Send',
                          icon: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                          onPressed: () => _sendMessage(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
