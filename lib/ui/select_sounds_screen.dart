import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meow_music/data/model/template.dart';
import 'package:meow_music/ui/component/speaking_cat_image.dart';
import 'package:meow_music/ui/component/transparent_app_bar.dart';
import 'package:meow_music/ui/definition/display_definition.dart';
import 'package:meow_music/ui/select_sounds_state.dart';
import 'package:meow_music/ui/select_sounds_view_model.dart';
import 'package:meow_music/ui/select_trimmed_sound_state.dart';
import 'package:meow_music/ui/set_piece_title_screen.dart';
import 'package:meow_music/ui/trim_sound_for_detection_screen.dart';

final _selectSoundsViewModelProvider = StateNotifierProvider.autoDispose
    .family<SelectSoundsViewModel, SelectSoundsState, Template>(
  (ref, template) => SelectSoundsViewModel(
    selectedTemplate: template,
  ),
);

class SelectSoundsScreen extends ConsumerStatefulWidget {
  SelectSoundsScreen({required Template template, Key? key})
      : viewModelProvider = _selectSoundsViewModelProvider(template),
        super(key: key);

  static const name = 'SelectSoundsScreen';

  final AutoDisposeStateNotifierProvider<SelectSoundsViewModel,
      SelectSoundsState> viewModelProvider;

  static MaterialPageRoute route({
    required Template template,
  }) =>
      MaterialPageRoute<SelectSoundsScreen>(
        builder: (_) => SelectSoundsScreen(template: template),
        settings: const RouteSettings(name: name),
      );

  @override
  ConsumerState<SelectSoundsScreen> createState() => _SelectTemplateState();
}

class _SelectTemplateState extends ConsumerState<SelectSoundsScreen> {
  @override
  void initState() {
    super.initState();

    ref.read(widget.viewModelProvider.notifier).registerListener(
      pickVideoFile: () async {
        final pickedFileResult = await FilePicker.platform.pickFiles(
          type: FileType.video,
        );
        return pickedFileResult?.files.single.path;
      },
      selectTrimmedSound: (moviePath) async {
        return Navigator.push<SelectTrimmedSoundResult?>(
          context,
          TrimSoundForDetectionScreen.route(moviePath: moviePath),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(widget.viewModelProvider);

    final title = Text(
      '鳴き声の動画を選ぼう',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headlineMedium,
    );

    final template = state.template;

    final icon = template.status.when(
      stop: () => Icons.play_arrow,
      playing: (position) => Icons.stop,
    );
    final thumbnailImage = Container(
      width: DisplayDefinition.thumbnailWidth,
      height: DisplayDefinition.thumbnailHeight,
      color: Colors.blueGrey,
    );
    final thumbnail = Stack(
      alignment: Alignment.center,
      children: [
        thumbnailImage,
        Icon(icon),
      ],
    );

    final templateName = Text(template.template.name);

    final progressIndicator = template.status.when(
      stop: SizedBox.shrink,
      playing: (position) => LinearProgressIndicator(value: position),
    );

    final onTapTemplate = template.status.map(
      stop: (_) => () =>
          ref.read(widget.viewModelProvider.notifier).play(choice: template),
      playing: (_) => () =>
          ref.read(widget.viewModelProvider.notifier).stop(choice: template),
    );

    final templateTile = ClipRRect(
      borderRadius: const BorderRadius.all(
        Radius.circular(
          DisplayDefinition.cornerRadiusSizeSmall,
        ),
      ),
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(
            DisplayDefinition.cornerRadiusSizeSmall,
          ),
        ),
        child: InkWell(
          onTap: onTapTemplate,
          child: Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  thumbnail,
                  const SizedBox(width: 16),
                  Expanded(
                    child: templateName,
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: progressIndicator,
              ),
            ],
          ),
        ),
      ),
    );

    final description = Text(
      'あなたのねこが鳴いてる動画を選んでね！',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyLarge,
    );

    final sounds = state.sounds;
    final soundsList = ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sounds.length,
      itemBuilder: (context, index) {
        final sound = sounds[index];

        final leading = sound.status.map(
          stop: (_) => const Icon(Icons.play_arrow),
          playing: (_) => const Icon(Icons.stop),
        );

        final tile = sound.sound.when(
          none: (_) {
            final label = Text(
              '動画を選択する',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: Theme.of(context).disabledColor),
              textAlign: TextAlign.center,
            );

            Future<void> onTap() => ref
                .read(widget.viewModelProvider.notifier)
                .onTapSelectSound(choice: sound);

            return ClipRRect(
              borderRadius: const BorderRadius.all(
                Radius.circular(
                  DisplayDefinition.cornerRadiusSizeSmall,
                ),
              ),
              child: Material(
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    DisplayDefinition.cornerRadiusSizeSmall,
                  ),
                ),
                child: InkWell(
                  onTap: onTap,
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 24,
                            horizontal: 16,
                          ),
                          child: label,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          uploaded: (_, __, localFileName, remoteFileName) => ListTile(
            leading: leading,
            title: Text(
              localFileName,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => ref
                  .read(widget.viewModelProvider.notifier)
                  .delete(target: sound),
            ),
            onTap: sound.status.map(
              stop: (_) => () => ref
                  .read(widget.viewModelProvider.notifier)
                  .play(choice: sound),
              playing: (_) => () => ref
                  .read(widget.viewModelProvider.notifier)
                  .stop(choice: sound),
            ),
          ),
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: sound.status.when(
            stop: () => [
              tile,
              const Visibility(
                visible: false,
                maintainState: true,
                maintainAnimation: true,
                maintainSize: true,
                child: LinearProgressIndicator(),
              ),
            ],
            playing: (position) => [
              tile,
              LinearProgressIndicator(
                value: position,
              )
            ],
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 8),
    );

    final body = SingleChildScrollView(
      padding: const EdgeInsets.only(
        top: 16,
        bottom: SpeakingCatImage.height,
        left: DisplayDefinition.screenPaddingSmall,
        right: DisplayDefinition.screenPaddingSmall,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          templateTile,
          const SizedBox(height: 32),
          description,
          const SizedBox(height: 32),
          soundsList,
        ],
      ),
    );

    final footerButton = ElevatedButton(
      onPressed: state.isAvailableSubmission ? _showSetPieceTitleScreen : null,
      style: ButtonStyle(
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('次へ'),
      ),
    );
    final footerContent = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 343),
      child: footerButton,
    );

    final footer = Container(
      alignment: Alignment.center,
      color: Theme.of(context).secondaryHeaderColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: footerContent,
        ),
      ),
    );

    final scaffold = WillPopScope(
      onWillPop: () async {
        await ref.read(widget.viewModelProvider.notifier).beforeHideScreen();
        return true;
      },
      child: Scaffold(
        appBar: transparentAppBar(
          context: context,
          titleText: 'STEP 2/3',
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 32, left: 16, right: 16),
              child: title,
            ),
            Expanded(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: body,
                  ),
                  const Positioned(
                    bottom: 0,
                    right: 16,
                    child: SpeakingCatImage(),
                  ),
                ],
              ),
            ),
            footer,
          ],
        ),
        resizeToAvoidBottomInset: false,
      ),
    );

    return state.isPicking
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
                      '動画を選択しています',
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

  Future<void> _showSetPieceTitleScreen() async {
    final args =
        ref.read(widget.viewModelProvider.notifier).getSetPieceTitleArgs();

    await Navigator.push<void>(
      context,
      SetPieceTitleScreen.route(args: args),
    );
  }
}
