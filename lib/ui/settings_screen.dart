import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:my_pet_melody/data/definitions/app_definitions.dart';
import 'package:my_pet_melody/data/definitions/app_features.dart';
import 'package:my_pet_melody/data/model/profile.dart';
import 'package:my_pet_melody/data/service/app_service.dart';
import 'package:my_pet_melody/data/service/in_app_purchase_service.dart';
import 'package:my_pet_melody/data/usecase/auth_use_case.dart';
import 'package:my_pet_melody/root_view_model.dart';
import 'package:my_pet_melody/ui/component/is_premium_plan_text.dart';
import 'package:my_pet_melody/ui/component/profile_icon.dart';
import 'package:my_pet_melody/ui/component/rounded_settings_list_tile.dart';
import 'package:my_pet_melody/ui/debug_screen.dart';
import 'package:my_pet_melody/ui/definition/display_definition.dart';
import 'package:my_pet_melody/ui/definition/list_tile_position_in_group.dart';
import 'package:my_pet_melody/ui/join_premium_plan_screen.dart';
import 'package:my_pet_melody/ui/link_with_account_screen.dart';
import 'package:my_pet_melody/ui/settings_state.dart';
import 'package:my_pet_melody/ui/settings_view_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

final _settingsViewModelProvider =
    StateNotifierProvider.autoDispose<SettingsViewModel, SettingsState>(
  (ref) => SettingsViewModel(ref: ref),
);

class SettingsScreen extends ConsumerStatefulWidget {
  SettingsScreen({
    Key? key,
  }) : super(key: key);

  static const name = 'SettingsScreen';

  final viewModelProvider = _settingsViewModelProvider;

  static MaterialPageRoute<SettingsScreen> route() =>
      MaterialPageRoute<SettingsScreen>(
        builder: (_) => SettingsScreen(),
        settings: const RouteSettings(name: name),
        fullscreenDialog: true,
      );

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(widget.viewModelProvider);

    final profileTile = _ProfileTile(
      onTapCreateAccountTile: () =>
          Navigator.push<void>(context, LinkWithAccountScreen.route()),
    );

    const currentPlanTile = RoundedSettingsListTile(
      title: Text('現在のプラン'),
      trailing: _IsPremiumPlanText(),
      positionInGroup: ListTilePositionInGroup.first,
    );
    final registerPremiumPlanTile = RoundedSettingsListTile(
      title: const Text('プレミアムプランに登録する'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push<void>(context, JoinPremiumPlanScreen.route()),
      positionInGroup: ListTilePositionInGroup.last,
    );

    final writeReviewTile = RoundedSettingsListTile(
      title: const Text('レビューを書く'),
      trailing: const Icon(Icons.open_in_browser),
      onTap: _writeReview,
      positionInGroup: ListTilePositionInGroup.first,
    );
    final shareWithFriendsTile = RoundedSettingsListTile(
      title: const Text('友達に教える'),
      trailing: const Icon(Icons.open_in_browser),
      onTap: _shareWithFriends,
      positionInGroup: ListTilePositionInGroup.middle,
    );
    final termsOfServiceTile = RoundedSettingsListTile(
      title: const Text('利用規約'),
      trailing: const Icon(Icons.open_in_browser),
      onTap: _openTermsOfService,
      positionInGroup: ListTilePositionInGroup.middle,
    );
    final privacyPolicyTile = RoundedSettingsListTile(
      title: const Text('プライバシーポリシー'),
      trailing: const Icon(Icons.open_in_browser),
      onTap: _openPrivacyPolicy,
      positionInGroup: ListTilePositionInGroup.last,
    );

    final debugTile = RoundedSettingsListTile(
      title: const Text('デバッグ'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(context, DebugScreen.route()),
      positionInGroup: ListTilePositionInGroup.first,
    );
    const versionTile = RoundedSettingsListTile(
      title: Text('バージョン'),
      trailing: _FullVersionNameText(),
      positionInGroup: ListTilePositionInGroup.last,
    );

    final body = SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          top: 16,
          bottom: MediaQuery.of(context).viewPadding.bottom,
          left: DisplayDefinition.screenPaddingSmall,
          right: DisplayDefinition.screenPaddingSmall,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            profileTile,
            const SizedBox(height: 32),
            currentPlanTile,
            registerPremiumPlanTile,
            const SizedBox(height: 32),
            writeReviewTile,
            shareWithFriendsTile,
            termsOfServiceTile,
            privacyPolicyTile,
            const SizedBox(height: 32),
            if (debugScreenAvailable) debugTile,
            versionTile,
            const SizedBox(height: 32),
            _DeleteAccountPanel(
              onTap: _deleteAccount,
            ),
          ],
        ),
      ),
    );

    final scaffold = Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: body,
      ),
      resizeToAvoidBottomInset: false,
    );

    return state.isProcessingToDeleteAccount
        ? Stack(
            children: [
              scaffold,
              Container(
                alignment: Alignment.center,
                color: Colors.black.withOpacity(0.5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'アカウントを削除しています',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge!
                          .copyWith(color: Colors.white),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: LinearProgressIndicator(),
                    ),
                  ],
                ),
              ),
            ],
          )
        : scaffold;
  }

  Future<void> _writeReview() async {
    // In-app reviews are limited to the number of times they can be
    // displayed, so go to Store and open the page to write a review.
    await InAppReview.instance.openStoreListing(appStoreId: appStoreId);
  }

  Future<void> _shareWithFriends() async {
    final storeUrl = Platform.isIOS
        ? 'https://apps.apple.com/us/app/うちのコメロディー/id6450181110'
        : 'https://play.google.com/store/apps/details?id=ide.shota.colomney.MyPetMelody';
    await Share.share('あなたのネコのオリジナルソングを作ろう！ $storeUrl');
  }

  Future<void> _openTermsOfService() async {
    await launchUrl(
      Uri.parse(
        'https://tricolor-fright-c89.notion.site/8b169d10b790461ab72b961064e16c49',
      ),
    );
  }

  Future<void> _openPrivacyPolicy() async {
    await launchUrl(
      Uri.parse(
        'https://tricolor-fright-c89.notion.site/19903a30a07e4499887f37ee67fdf876',
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: const Text('本当にアカウントを削除しますか？削除すると、これまで製作した作品を閲覧できなくなります。'),
          actions: [
            TextButton(
              child: const Text('削除する'),
              onPressed: () => Navigator.pop(context, true),
            ),
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        );
      },
    );

    if (shouldContinue == null || !shouldContinue) {
      return;
    }

    final result =
        await ref.read(widget.viewModelProvider.notifier).deleteAccount();

    await result.when(
      success: (_) async {
        await ref.read(rootViewModelProvider.notifier).restart();

        if (!mounted) {
          return;
        }

        Navigator.popUntil(context, (route) => route.isFirst);
      },
      failure: (error) => error.when(
        cancelledByUser: () {},
        unrecoverable: () async {
          const snackBar = SnackBar(
            content: Text('エラーが発生しました。しばらくしてから再度お試しください'),
          );

          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        },
      ),
    );
  }
}

class _IsPremiumPlanText extends ConsumerWidget {
  const _IsPremiumPlanText({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremiumPlan = ref.watch(isPremiumPlanProvider);

    return IsPremiumPlanText(isPremiumPlan: isPremiumPlan);
  }
}

class _FullVersionNameText extends ConsumerWidget {
  const _FullVersionNameText({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fullVersionNameAsyncValue = ref.watch(fullVersionNameProvider);
    final fullVersionName = fullVersionNameAsyncValue.whenOrNull(
          data: (fullVersionName) => fullVersionName,
        ) ??
        '';
    return Text(fullVersionName);
  }
}

class _ProfileTile extends ConsumerWidget {
  const _ProfileTile({
    required this.onTapCreateAccountTile,
    Key? key,
  }) : super(key: key);

  final VoidCallback onTapCreateAccountTile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(nonAnonymousProfileProvider);
    return profile != null
        ? _LoggedInProfileTile(profile: profile)
        : _NotLoggedInTile(onTap: onTapCreateAccountTile);
  }
}

class _LoggedInProfileTile extends StatelessWidget {
  const _LoggedInProfileTile({
    required this.profile,
    Key? key,
  }) : super(key: key);

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final photoUrl = profile.photoUrl;
    final icon = ProfileIcon(photoUrl: photoUrl);

    final name = profile.name;
    final titleText = name ?? '(No Name)';

    return ListTile(
      leading: SizedBox(
        width: 48,
        height: 48,
        child: icon,
      ),
      title: Text(titleText),
    );
  }
}

class _NotLoggedInTile extends StatelessWidget {
  const _NotLoggedInTile({
    required this.onTap,
    Key? key,
  }) : super(key: key);

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RoundedSettingsListTile(
      title: const Text('アカウントを作成する'),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _DeleteAccountPanel extends ConsumerWidget {
  const _DeleteAccountPanel({
    required this.onTap,
    Key? key,
  }) : super(key: key);

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(isLoggedInNotAnonymouslyProvider);

    if (!isLoggedIn) {
      return const SizedBox.shrink();
    }

    return RoundedSettingsListTile(
      title: Text(
        'アカウント削除',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      onTap: onTap,
    );
  }
}
