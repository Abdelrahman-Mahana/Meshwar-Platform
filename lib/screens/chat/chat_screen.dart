import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mashwar_badge.dart';
import '../../state/settings_provider.dart';

class ChatScreen extends StatefulWidget {
  final String driverName;
  final String driverCar;
  final String tripRoute;

  const ChatScreen({
    super.key,
    this.driverName = 'محمد سعيد',
    this.driverCar = 'هيونداي إلنترا، أبيض (س ق ر 1942)',
    this.tripRoute = 'كفر الشيخ ← القاهرة',
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
      'text': 'صباح الخير يا فندم، أنا جاهز وهتحرك في الميعاد المحدد 7:30 ص إن شاء الله.',
      'textEn': 'Good morning! I am ready and will depart on schedule at 7:30 AM.',
      'time': '7:15 ص',
    },
    {
      'isMe': true,
      'text': 'صباح النور يا كابتن، تمام أنا في طريقي لنقطة الصعود عند محطة الوقود.',
      'textEn': 'Good morning Captain! I am on my way to the pickup gas station.',
      'time': '7:18 ص',
    },
    {
      'isMe': false,
      'text': 'تمام يا غالي، أنا ركنت قدام الكافيه عند مدخل المحطة. سيارة بيضاء.',
      'textEn': 'Great! I parked in front of the cafe at the station entrance. White car.',
      'time': '7:22 ص',
    },
  ];

  final List<String> _quickChipsAr = [
    'أنا عند نقطة الصعود الآن',
    'الطريق زحمة 5 دقائق وأوصل',
    'معايا شنطة سفر متوسطة',
    'أنا لابس قميص كحلي',
  ];

  final List<String> _quickChipsEn = [
    'I arrived at pickup spot',
    'Traffic delay, 5 mins away',
    'I have 1 medium luggage',
    'I am wearing a navy shirt',
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
            'text': 'تمام يا فندم، مرحب بيك ومستنيك بالسيارة.',
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: AppColors.navy),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.driverName[0],
                  style: AppTypography.title(color: AppColors.navy).copyWith(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(widget.driverName, style: AppTypography.title().copyWith(fontSize: 15)),
                      const SizedBox(width: 6),
                      const MashwarBadge(type: BadgeType.verified, customLabel: 'موثق'),
                    ],
                  ),
                  Text(widget.driverCar, style: AppTypography.label(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_in_talk_rounded, color: AppColors.teal),
            tooltip: isAr ? 'اتصال بالسائق' : 'Call Driver',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isAr ? 'جاري الاتصال بالسائق على 0100 123 4567...' : 'Calling driver at 0100 123 4567...'),
                  backgroundColor: AppColors.teal,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Safety banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.goldSurface,
              child: Row(
                children: [
                  const Icon(Icons.security_rounded, color: AppColors.navy, size: 16),
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
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppDimens.space16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isMe = msg['isMe'] as bool;
                  return Align(
                    alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe ? AppColors.navy : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isMe ? 4 : 16),
                          bottomRight: Radius.circular(isMe ? 16 : 4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                        children: [
                          Text(
                            isAr ? msg['text'] : msg['textEn'],
                            style: TextStyle(
                              color: isMe ? Colors.white : AppColors.textPrimary,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            msg['time'],
                            style: TextStyle(
                              color: isMe ? Colors.white70 : AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Quick Reply Chips
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: quickChips.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ActionChip(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.borderDisabled),
                    label: Text(
                      quickChips[index],
                      style: AppTypography.label(color: AppColors.navy),
                    ),
                    onPressed: () => _sendMessage(quickChips[index]),
                  );
                },
              ),
            ),

            const SizedBox(height: 6),

            // Chat input bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppColors.borderDisabled.withValues(alpha: 0.5)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: InputDecoration(
                        hintText: isAr ? 'اكتب رسالتك للكابتن...' : 'Type message to driver...',
                        filled: true,
                        fillColor: AppColors.sand,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.teal,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Transform.flip(
                        flipX: isAr,
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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
    );
  }
}
