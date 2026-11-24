import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_animations.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../state/settings_provider.dart';
import '../escrow/service_escrow_screen.dart';

class ChatScreen extends StatefulWidget {
  final String driverName;
  final String driverCar;
  final String tripRoute;

  const ChatScreen({
    super.key,
    this.driverName = 'جاسم الكواري',
    this.driverCar = 'تويوتا كامري، أبيض لؤلؤي (قطر 482910)',
    this.tripRoute = 'الدوحة ← الخور',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [
    {
      'isMe': false,
      'text': 'السلام عليكم، أنا جاهز وبإذن الله نتحرك في الموعد المحدد 7:30 ص.',
      'textEn': 'Good morning! I am ready and will depart on schedule at 7:30 AM.',
      'time': '7:15 ص',
    },
    {
      'isMe': true,
      'text': 'وعليكم السلام كابتن، أنا في طريقي لنقطة الانطلاق عند محطة وقود (WOQOD).',
      'textEn': 'Good morning Captain! I am on my way to the pickup WOQOD station.',
      'time': '7:18 ص',
    },
    {
      'isMe': false,
      'text': 'حياك الله، أنا واقف عند المقهى عند مدخل المحطة. سيارة بيضاء.',
      'textEn': 'Hello! I parked in front of the cafe at the station entrance. White car.',
      'time': '7:22 ص',
    },
  ];

  final List<String> _quickChipsAr = [
    'أنا عند نقطة الالتقاء الآن',
    'أرفقت صورة الفاتورة في الضمان',
    'شاركني الموقع الدقيق',
    'جاهز للتسليم ومطابقة كود OTP',
  ];

  final List<String> _quickChipsEn = [
    'I arrived at meetup spot',
    'Uploaded store receipt to Escrow',
    'Share exact location',
    'Ready to settle with 4-digit OTP',
  ];

  void _sendMessage([String? quickText]) {
    final text = quickText ?? _msgController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'isMe': true,
        'text': text,
        'textEn': text,
        'time': 'الآن',
      });
      _msgController.clear();
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Simulate driver reply
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'isMe': false,
            'text': 'أبشر، حياك الله ومستعد لك بالسيارة.',
            'textEn': 'Noted! Looking forward to seeing you.',
            'time': 'الآن',
          });
        });
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isAr = settings.isArabic;
    final quickChips = isAr ? _quickChipsAr : _quickChipsEn;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,
        leading: const BackButton(color: AppColors.navy),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.navy.withValues(alpha: 0.14), width: 1.5),
              ),
              child: Center(
                child: Text(
                  widget.driverName.isNotEmpty ? widget.driverName[0] : (isAr ? 'ك' : 'D'),
                  style: AppTypography.title(color: AppColors.navy).copyWith(fontSize: 18),
                ),
              ),
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
                          style: AppTypography.title().copyWith(fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 6),
                      MashwarBadge(type: BadgeType.verified, customLabel: isAr ? 'موثق' : 'Verified'),
                    ],
                  ),
                  Text(
                    widget.driverCar,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.tealSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.phone_in_talk_rounded, color: AppColors.teal, size: 18),
            ),
            tooltip: isAr ? 'اتصال بالسائق' : 'Call Driver',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isAr ? 'جاري الاتصال بالسائق على 5523 4567...' : 'Calling driver at +974 5523 4567...'),
                  backgroundColor: AppColors.teal,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                // Trip Route Context + 1-Tap Location Share & Escrow Shortcut Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Color(0xFFEDF2F7))),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.route_rounded, color: AppColors.teal, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.tripRoute,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      MashwarPressable(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          Navigator.of(context).push(
                            MashwarPageRoute(builder: (_) => const ServiceEscrowScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.escrowSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.escrowGreen.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_user_rounded, size: 13, color: AppColors.escrowGreen),
                              const SizedBox(width: 4),
                              Text(
                                isAr ? 'الضمان و OTP' : 'Escrow',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.escrowGreen,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      MashwarPressable(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _sendMessage(
                          isAr ? 'تمت مشاركة نقطة الالتقاء الحالية عبر الخريطة.' : 'Shared current pickup location via map.',
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.tealSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.my_location_rounded, size: 13, color: AppColors.teal),
                              const SizedBox(width: 4),
                              Text(
                                isAr ? 'مشاركة موقعي' : 'Share Map',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.teal,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Safety banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  color: AppColors.goldSurface,
                  child: Row(
                    children: [
                      const Icon(Icons.security_rounded, color: AppColors.navy, size: 15),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isAr
                              ? 'أمان مشوار: لا تشارك بياناتك البنكية أو أرقام OTP داخل المحادثة.'
                              : 'Safety notice: Never share bank cards or OTP codes in chat.',
                          style: AppTypography.label(color: AppColors.navy),
                        ),
                      ),
                    ],
                  ),
                ),

                // Messages List
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final bubbleMaxWidth = (constraints.maxWidth * 0.78).clamp(200.0, 520.0);
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(AppDimens.space16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg['isMe'] as bool;
                          final rawTime = msg['time'] as String;
                          final displayTime = rawTime == 'الآن' && !isAr ? 'Now' : rawTime;
                          return MashwarFadeSlideIn(
                            duration: const Duration(milliseconds: 220),
                            offsetY: 8,
                            child: Align(
                              alignment: isMe
                                  ? AlignmentDirectional.centerEnd
                                  : AlignmentDirectional.centerStart,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: isMe
                                      ? const LinearGradient(
                                          colors: [AppColors.navy, Color(0xFF173D61)],
                                        )
                                      : null,
                                  color: isMe ? null : Colors.white,
                                  border: isMe
                                      ? null
                                      : Border.all(color: AppColors.borderDisabled, width: 0.8),
                                  borderRadius: BorderRadiusDirectional.only(
                                    topStart: const Radius.circular(18),
                                    topEnd: const Radius.circular(18),
                                    bottomStart: Radius.circular(isMe ? 18 : 4),
                                    bottomEnd: Radius.circular(isMe ? 4 : 18),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isAr ? msg['text'] : msg['textEn'],
                                      style: AppTypography.bodySecondary(
                                        color: isMe ? Colors.white : AppColors.textPrimary,
                                      ).copyWith(height: 1.45),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          displayTime,
                                          style: AppTypography.label(
                                            color: isMe ? Colors.white70 : AppColors.textSecondary,
                                          ).copyWith(fontSize: 10),
                                        ),
                                        if (isMe) ...[
                                          const SizedBox(width: 4),
                                          const Icon(Icons.done_all_rounded, size: 13, color: AppColors.gold),
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
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: quickChips.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return MashwarPressable(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _sendMessage(quickChips[index]),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt_rounded, size: 14, color: AppColors.gold),
                              const SizedBox(width: 4),
                              Text(
                                quickChips[index],
                                style: AppTypography.label(color: AppColors.navy).copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 6),

                // Chat input bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: AppColors.borderDisabled.withValues(alpha: 0.7)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgController,
                          decoration: InputDecoration(
                            hintText: isAr ? 'اكتب رسالتك هنا...' : 'Type your message...',
                            filled: true,
                            fillColor: const Color(0xFFF3F4F6),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(26),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(26),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(
                          color: AppColors.navy,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          tooltip: isAr ? 'إرسال' : 'Send',
                          icon: const Icon(Icons.send_rounded, color: AppColors.gold, size: 20),
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
