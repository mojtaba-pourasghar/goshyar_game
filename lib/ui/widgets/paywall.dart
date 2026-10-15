import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/billing/billing.dart';
import '../../core/design/theme.dart';
import '../../core/design/tokens.dart';
import '../../core/fa.dart';
import '../../data/access_store.dart';
import '../../data/content_repository.dart';
import '../routes.dart';
import '../screens/parent_screens.dart';
import 'clay.dart';
import 'mascot.dart';

/// دروازه‌ی والدین در حالت «فقط تأیید»: true اگر بزرگ‌تر پاسخ درست داد.
Future<bool> verifyParent(BuildContext context) async {
  // مسیرها بی‌نوع ساخته می‌شوند (Routes.generate)؛ pushNamed<bool> این‌جا خطای نوع می‌داد.
  final ok = await Navigator.of(context).pushNamed(Routes.parentGate, arguments: ParentGateMode.verify);
  return ok == true;
}

/// برگه‌ی «نسخه‌ی کامل»: چه چیزی باز می‌شود، قیمت، خرید (پشت دروازه‌ی والدین) و بازیابی خرید.
/// [parentVerified]: از بخش والدین باز شده و دروازه از قبل گذرانده شده است.
Future<void> showPaywall(BuildContext context, {bool parentVerified = false}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PaywallSheet(parentVerified: parentVerified),
  );
}

class _PaywallSheet extends StatelessWidget {
  const _PaywallSheet({required this.parentVerified});

  final bool parentVerified;

  Future<void> _buy(BuildContext context) async {
    final access = context.read<AccessStore>();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    if (!parentVerified && !await verifyParent(context)) return;
    final r = await access.buy();
    final text = switch (r) {
      PurchaseResult.purchased => 'ممنون! همه‌ی مرحله‌ها باز شد.',
      PurchaseResult.cancelled => 'خرید انجام نشد.',
      PurchaseResult.failed => 'خرید ناموفق بود. دوباره امتحان کنید.',
      PurchaseResult.unavailable => 'برای خرید، کافه‌بازار باید روی گوشی نصب و وارد حساب شده باشد.',
    };
    if (r == PurchaseResult.purchased && nav.canPop()) nav.pop();
    messenger.showSnackBar(SnackBar(content: Text(text, style: GText.body.copyWith(color: Colors.white))));
  }

  Future<void> _restore(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final found = await context.read<AccessStore>().restore();
    final text = switch (found) {
      true => 'خرید قبلی پیدا شد؛ همه‌ی مرحله‌ها باز است.',
      false => 'خریدی با این حساب کافه‌بازار پیدا نشد.',
      null => 'به کافه‌بازار وصل نشد. اینترنت و ورود به حساب بازار را بررسی کنید.',
    };
    if (found == true && nav.canPop()) nav.pop();
    messenger.showSnackBar(SnackBar(content: Text(text, style: GText.body.copyWith(color: Colors.white))));
  }

  @override
  Widget build(BuildContext context) {
    final access = context.watch<AccessStore>();
    final content = context.read<ContentRepository>();
    final paid = content.totalLevels - content.modes.length;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(GSpace.md),
        child: ClayCard(
          padding: const EdgeInsets.all(GSpace.lg),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Mascot(pose: MascotPose.celebrate, size: 96),
                Text('همه‌ی مرحله‌ها را باز کن', style: GText.title.copyWith(color: GColors.purple), textAlign: TextAlign.center),
                const SizedBox(height: GSpace.xs),
                Text(
                  'مرحله‌ی اول هر بازی رایگان است. با نسخه‌ی کامل ${faDigits(paid)} مرحله‌ی دیگر در '
                  '${faDigits(content.modes.length)} بازی باز می‌شود؛ یک بار خرید، برای همیشه.',
                  style: GText.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: GSpace.md),
                Text(access.price, style: GText.display.copyWith(fontSize: 30, color: GColors.orange)),
                const SizedBox(height: GSpace.md),
                ClayButton(
                  label: access.busy ? 'در حال خرید…' : 'خرید نسخه‌ی کامل',
                  icon: Icons.lock_open_rounded,
                  color: GColors.green,
                  big: true,
                  onTap: access.busy ? null : () => _buy(context),
                ),
                const SizedBox(height: GSpace.xs),
                Text('خرید فقط با اجازه‌ی بزرگ‌ترها انجام می‌شود.', style: GText.caption, textAlign: TextAlign.center),
                const SizedBox(height: GSpace.sm),
                TextButton(
                  onPressed: access.busy ? null : () => _restore(context),
                  child: Text('قبلاً خریده‌ام', style: GText.bodyStrong.copyWith(color: GColors.purple)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('بعداً', style: GText.body),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
