import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meow_music/ui/select_trimmed_sound_state.dart';
import 'package:meow_music/ui/select_trimmed_sound_view_model.dart';

final selectTrimmedSoundViewModelProvider = StateNotifierProvider.autoDispose
    .family<SelectTrimmedSoundViewModel, SelectTrimmedSoundState,
        SelectTrimmedSoundArgs>(
  (ref, args) => SelectTrimmedSoundViewModel(
    args: args,
  ),
);

class SelectTrimmedSoundScreen extends ConsumerStatefulWidget {
  SelectTrimmedSoundScreen({
    required SelectTrimmedSoundArgs args,
    Key? key,
  })  : viewModel = selectTrimmedSoundViewModelProvider(args),
        super(key: key);

  static const name = 'SelectTrimmedSoundScreen';

  final AutoDisposeStateNotifierProvider<SelectTrimmedSoundViewModel,
      SelectTrimmedSoundState> viewModel;

  static MaterialPageRoute route({
    required SelectTrimmedSoundArgs args,
  }) =>
      MaterialPageRoute<SelectTrimmedSoundScreen>(
        builder: (_) => SelectTrimmedSoundScreen(args: args),
        settings: const RouteSettings(name: name),
      );

  @override
  ConsumerState<SelectTrimmedSoundScreen> createState() =>
      _SelectTrimmedSoundState();
}

class _SelectTrimmedSoundState extends ConsumerState<SelectTrimmedSoundScreen> {
  static const _aspectRatio = 1.5;

  @override
  void initState() {
    super.initState();

    ref.read(widget.viewModel.notifier).setup();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(widget.viewModel);

    final title = Text(
      '使いたい鳴き声を\n選ぼう',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headline5,
    );

    final segmentPanels = state.choices.mapIndexed(
      (index, choice) {
        const height = 64.0;
        const width = height * _aspectRatio;
        final thumbnailPath = choice.thumbnailPath;
        final thumbnailBackground = thumbnailPath != null
            ? Image.file(
                File(thumbnailPath),
                fit: BoxFit.fill,
                width: width,
                height: height,
              )
            : const SizedBox(
                width: width,
                height: height,
              );

        final thumbnailButtonIcon = Container(
          decoration: const BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.play_arrow),
        );
        final thumbnail = InkWell(
          onTap: () {
            debugPrint('Thumbnail was tapped');
          },
          child: Stack(
            children: [
              thumbnailBackground,
              Center(
                child: thumbnailButtonIcon,
              ),
            ],
          ),
        );

        final title = Text('セグメント ${index + 1}');

        final subtitle = Text(
          '${choice.segment.startMilliseconds}ms - '
          '${choice.segment.endMilliseconds}ms',
        );

        final selectButton = IconButton(
          onPressed: () {},
          icon: const Icon(Icons.reply),
          iconSize: 24,
        );

        const playingIndicator = LinearProgressIndicator();

        final splitThumbnails = state.splitThumbnails;
        final seekBarBackgroundLayer = splitThumbnails != null
            ? SizedBox(
                height: 24,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final splitWidth = width ~/ splitThumbnails.length;
                    final imageWidth = constraints.maxHeight * _aspectRatio;
                    final imageCount = width ~/ imageWidth + 1;
                    final thumbnails = List.generate(imageCount, (index) {
                      final positionX = index * imageWidth;
                      final imageIndex = positionX ~/ splitWidth;
                      final imagePath = splitThumbnails[imageIndex];

                      return Padding(
                        padding: EdgeInsets.only(left: positionX),
                        child: Image.file(
                          File(imagePath),
                          width: imageWidth,
                          fit: BoxFit.fill,
                        ),
                      );
                    });

                    return ClipRect(
                      child: Stack(
                        children: [
                          ...thumbnails,
                          Container(
                            color: Colors.white.withOpacity(0.5),
                          )
                        ],
                      ),
                    );
                  },
                ),
              )
            : Container(
                color: Colors.grey,
              );

        const seekBarPadding = 4.0;
        final lengthMilliseconds = state.lengthMilliseconds;
        final seekBar = lengthMilliseconds != null
            ? Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(seekBarPadding),
                    child: seekBarBackgroundLayer,
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final seekBarWidth =
                          constraints.maxWidth - seekBarPadding * 2;
                      final startRatio =
                          choice.segment.startMilliseconds / lengthMilliseconds;
                      final endRatio =
                          choice.segment.endMilliseconds / lengthMilliseconds;
                      final positionX1 = seekBarWidth * startRatio;
                      final positionX2 = seekBarWidth * endRatio;

                      return Container(
                        margin: EdgeInsets.only(left: positionX1),
                        width: positionX2 - positionX1,
                        height: constraints.maxHeight,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.red,
                            width: seekBarPadding,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    },
                  ),
                ],
              )
            : Container();

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          thumbnail,
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 24),
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      title,
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: subtitle,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Visibility(
                        child: playingIndicator,
                      ),
                    ],
                  ),
                ),
                selectButton,
              ],
            ),
            seekBar,
          ],
        );
      },
    ).toList();

    final body = SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 203),
      child: Column(
        children: [
          ...segmentPanels,
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: title,
          ),
          Expanded(
            child: body,
          ),
        ],
      ),
    );
  }
}
