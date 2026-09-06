import 'package:border_player/app_settings.dart';
import 'package:border_player/page/settings_page/settings_dialog.dart';
import 'package:border_player/src/rust/api/utils.dart';
import 'package:border_player/utils.dart';
import 'package:border_player/version_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:github/github.dart';
import 'package:material_symbols_icons/symbols.dart';

class CheckForUpdate extends StatefulWidget {
  const CheckForUpdate({super.key});

  @override
  State<CheckForUpdate> createState() => _CheckForUpdateState();
}

class _CheckForUpdateState extends State<CheckForUpdate> {
  bool isChecking = false;
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      FilledButton.icon(
        icon: const Icon(Symbols.update),
        label: const Text("检查更新"),
        onPressed: isChecking
            ? null
            : () async {
                setState(() {
                  isChecking = true;
                });

                try {
                  final newest = await AppSettings.github.repositories
                      .listReleases(
                        RepositorySlug("tingzhouhuige", "Border-Player"),
                      )
                      .first;
                  if (!mounted) return;
                  if (isReleaseVersionNewer(
                    newest.tagName,
                    AppSettings.version,
                  )) {
                    if (context.mounted) {
                      showSettingsGlassDialog(
                        context: context,
                        builder: (context) => NewestUpdateView(release: newest),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      showTextOnSnackBar("无新版本");
                    }
                  }
                } catch (err, trace) {
                  LOGGER.e(err, stackTrace: trace);
                  if (mounted) {
                    showTextOnSnackBar("网络异常");
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      isChecking = false;
                    });
                  }
                }
              },
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: Text("当前版本：${AppSettings.version}"),
      ),
      if (isChecking)
        const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: SizedBox(
            width: 16.0,
            height: 16.0,
            child: CircularProgressIndicator(),
          ),
        ),
    ]);
  }
}

class NewestUpdateView extends StatelessWidget {
  const NewestUpdateView({
    super.key,
    required this.release,
  });

  final Release release;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    release.name ?? "新版本",
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Text(
                    "${release.tagName}\n${release.publishedAt}",
                    style: TextStyle(color: scheme.onSurface),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Markdown(
                data: release.body ?? "",
                onTapLink: (text, href, title) {
                  if (href != null) {
                    launchInBrowser(uri: href);
                  }
                },
                padding: EdgeInsets.zero,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("取消"),
                  ),
                  const SizedBox(width: 16.0),
                  TextButton.icon(
                    onPressed: () {
                      if (release.htmlUrl != null) {
                        launchInBrowser(uri: release.htmlUrl!);
                      }

                      Navigator.pop(context);
                    },
                    icon: const Icon(Symbols.arrow_outward),
                    label: const Text("获取更新"),
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
