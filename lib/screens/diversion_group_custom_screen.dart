import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:karing/app/modules/server_manager.dart';
import 'package:karing/app/modules/setting_manager.dart';
import 'package:karing/app/runtime/return_result.dart';
import 'package:karing/app/utils/diversion_custom_utils.dart';
import 'package:karing/app/utils/error_reporter_utils.dart';
import 'package:karing/app/utils/path_utils.dart';
import 'package:karing/app/utils/platform_utils.dart';
import 'package:karing/app/utils/proxy_conf_utils.dart';
import 'package:karing/i18n/strings.g.dart';
import 'package:karing/screens/dialog_utils.dart';
import 'package:karing/screens/diversion_group_custom_edit_screen.dart';
import 'package:karing/screens/diversion_rules_custom_set_screen.dart';
import 'package:karing/screens/theme_config.dart';
import 'package:karing/screens/theme_define.dart';
import 'package:karing/screens/widgets/framework.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';

class DiversionGroupCustomScreen extends LasyRenderingStatefulWidget {
  static RouteSettings routSettings() {
    return const RouteSettings(name: "DiversionGroupCustomScreen");
  }

  final DiversionGroupCustomEditOptions? options;
  const DiversionGroupCustomScreen({super.key, this.options});

  @override
  State<DiversionGroupCustomScreen> createState() =>
      _DiversionGroupCustomScreenState();
}

class _DiversionGroupCustomScreenState
    extends LasyRenderingState<DiversionGroupCustomScreen> {
  final List<String> _groupData = [];

  @override
  void initState() {
    super.initState();
    _buildData();
  }

  void _buildData() {
    _groupData.clear();
    ServerDiversionGroupItem diversionItem =
        ServerManager.getDiversionCustomGroup();

    for (var group in diversionItem.groups) {
      _groupData.add(group.name);
    }
  }

  static int sortCompare(DiversionRulesGroup a, DiversionRulesGroup b) {
    if (a.index != b.index) {
      return (a.index - b.index);
    }
    return (a.index - b.index);
  }

  @override
  void dispose() {
    super.dispose();
    if (ServerManager.getDirty()) {
      ServerManager.saveDiversionGroupConfig();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tcontext = Translations.of(context);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.zero,
        child: AppBar(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const SizedBox(
                        width: 50,
                        height: 30,
                        child: Icon(
                          Icons.arrow_back_ios_outlined,
                          size: 26,
                        ),
                      ),
                    ),
                    Text(
                      tcontext.diversionCustomGroup,
                      style: const TextStyle(
                          fontWeight: ThemeConfig.kFontWeightTitle,
                          fontSize: ThemeConfig.kFontSizeTitle),
                    ),
                    InkWell(
                      onTap: () {
                        onTapMore();
                      },
                      child: const SizedBox(
                        width: 50,
                        height: 30,
                        child: Icon(
                          Icons.more_vert_outlined,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: Text(
                  tcontext.diversionCustomGroupAddTips,
                  style: const TextStyle(
                    fontSize: ThemeConfig.kFontSizeListSubItem,
                    fontWeight: ThemeConfig.kFontWeightListSubItem,
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Expanded(
                child: _loadListView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loadListView() {
    return ReorderableListView(
        header: Container(
          height: 0,
        ),
        children: _groupData.map((item) {
          return createWidget(item);
        }).toList(),
        onReorder: (int oldIndex, int newIndex) {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          var item = _groupData.removeAt(oldIndex);
          _groupData.insert(newIndex, item);

          ServerDiversionGroupItem diversionItem =
              ServerManager.getDiversionCustomGroup();

          for (var group in diversionItem.groups) {
            group.index = _groupData.indexOf(group.name);
          }
          diversionItem.groups.sort(sortCompare);

          ServerManager.setDirty(true);
          setState(() {});
        });
  }

  Widget createWidget(String current) {
    Size windowSize = MediaQuery.of(context).size;
    const double padding = 4;
    const double rightWidth = 80;
    double leftWidth = windowSize.width - rightWidth - padding * 2 - 4;
    return Column(key: Key(current), children: [
      Material(
        borderRadius: ThemeDefine.kBorderRadius,
        child: InkWell(
          onTap: () {
            onTapItem(current);
          },
          onDoubleTap: () {
            onTapModifyName(current);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: padding,
            ),
            width: double.infinity,
            height: ThemeConfig.kListItemHeight2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 4,
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: leftWidth,
                  ),
                  child: Text(
                    current,
                    style: TextStyle(
                      fontSize: ThemeConfig.kFontSizeGroupItem,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  alignment: Alignment.centerRight,
                  height: 40,
                  width: rightWidth,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      InkWell(
                          onTap: () async {
                            onTapDel(current);
                          },
                          child: const SizedBox(
                            width: 26,
                            height: ThemeConfig.kListItemHeight2,
                            child: Icon(Icons.remove_circle_outlined,
                                size: 26, color: Colors.red),
                          )),
                      const SizedBox(width: 20),
                      Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
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
    ]);
  }

  void onTapMore() {
    showMenu(
        context: context,
        position: const RelativeRect.fromLTRB(0.1, 0, 0, 0),
        items: [
          PopupMenuItem(
              value: 1,
              child: const SizedBox(
                width: 30,
                height: 30,
                child: Icon(
                  Icons.add,
                  size: 30,
                ),
              ),
              onTap: () async {
                onTapAddCustom();
              }),
          PopupMenuItem(
              value: 1,
              child: const SizedBox(
                width: 30,
                height: 30,
                child: Icon(
                  Icons.playlist_add_outlined,
                  size: 30,
                ),
              ),
              onTap: () async {
                final tcontext = Translations.of(context);
                var settingConfig = SettingManager.getConfig();
                var regionCode = settingConfig.regionCode.toLowerCase();

                DiversionCustomRules? rules =
                    await DiversionCustomRulesPreset.getPreset(regionCode);
                if (!mounted) {
                  return;
                }
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        settings: DiversionRulesCustomSetScreen.routSettings(),
                        builder: (context) => DiversionRulesCustomSetScreen(
                            title: tcontext.diversionCustomGroupPreset,
                            canGoBack: true,
                            nextText: null,
                            nextIcon: Icons.done_outlined,
                            rules: rules ?? DiversionCustomRules())));
                _buildData();
                setState(() {});
              }),
          PopupMenuItem(
              value: 1,
              child: const SizedBox(
                width: 30,
                height: 30,
                child: Icon(
                  AntDesign.import_outline,
                  size: 30,
                ),
              ),
              onTap: () async {
                onTapAddImport();
              }),
          PopupMenuItem(
              value: 1,
              child: const SizedBox(
                width: 30,
                height: 30,
                child: Icon(
                  AntDesign.export_outline,
                  size: 30,
                ),
              ),
              onTap: () async {
                onTapExport();
              }),
        ]);
  }

  void onTapAddImport() async {
    final tcontext = Translations.of(context);
    List<String> extensions = ['json'];
    try {
      FilePickerResult? fresult = await FilePicker.platform.pickFiles(
        type: Platform.isAndroid ? FileType.any : FileType.custom,
        allowedExtensions: Platform.isAndroid ? null : extensions,
      );
      if (fresult != null) {
        String ext = path
            .extension(fresult.files.first.name)
            .replaceAll('.', '')
            .toLowerCase();
        if (!extensions.contains(ext)) {
          if (!mounted) {
            return;
          }
          DialogUtils.showAlertDialog(
              context, tcontext.invalidFileType(p: ext));
          return;
        }
        ReturnResult result =
            await DiversionCustomRules.getFromFile(fresult.files.first.path!);
        if (result.error != null) {
          if (!mounted) {
            return;
          }
          DialogUtils.showAlertDialog(context, result.error!.message);
        }

        if (!mounted) {
          return;
        }
        await Navigator.push(
            context,
            MaterialPageRoute(
                settings: DiversionRulesCustomSetScreen.routSettings(),
                fullscreenDialog: true,
                builder: (context) => DiversionRulesCustomSetScreen(
                      title: tcontext.import,
                      canGoBack: true,
                      nextText: null,
                      nextIcon: Icons.done_outlined,
                      rules: result.data!,
                    )));
      }
    } catch (err, stacktrace) {
      if (!mounted) {
        return;
      }
      DialogUtils.showAlertDialog(context, err.toString());
    }

    _buildData();
    setState(() {});
  }

  Future<void> onTapExport() async {
    try {
      String fileName = "diversion_rules_custom.json";
      String? filePath;
      if (PlatformUtils.isMobile()) {
        String dir = await PathUtils.cacheDir();
        filePath = path.join(dir, fileName);
      } else {
        filePath = await FilePicker.platform.saveFile(
          fileName: fileName,
          lockParentWindow: true,
        );
      }

      if (filePath != null) {
        File file = File(filePath);
        DiversionCustomRules rules = DiversionCustomRules.exportRules();
        const JsonEncoder encoder = JsonEncoder.withIndent('  ');
        String content = encoder.convert(rules);
        try {
          await file.writeAsString(content, flush: true);
        } catch (err) {
          ErrorReporterUtils.tryReportNoSpace(err.toString());
          return;
        }

        if (PlatformUtils.isMobile()) {
          try {
            if (!mounted) {
              return;
            }
            final box = context.findRenderObject() as RenderBox?;
            Share.shareXFiles([XFile(filePath)],
                sharePositionOrigin:
                    box!.localToGlobal(Offset.zero) & box.size);
          } catch (err) {}
        }
      }
    } catch (err, stacktrace) {
      if (!mounted) {
        return;
      }
      DialogUtils.showAlertDialog(context, err.toString());
    }
  }

  void onTapAddCustom() async {
    final tcontext = Translations.of(context);
    String? text = await DialogUtils.showTextInputDialog(
        context, tcontext.remark, "", null, null, (text) {
      text = text.trim();
      if (text.isEmpty) {
        DialogUtils.showAlertDialog(context, tcontext.remarkCannotEmpty);
        return false;
      }

      if (text.length > kRemarkMaxLength) {
        DialogUtils.showAlertDialog(context, tcontext.remarkTooLong);
        return false;
      }
      ServerDiversionGroupItem diversionItem =
          ServerManager.getDiversionCustomGroup();
      for (var group in diversionItem.groups) {
        if (group.name == text) {
          DialogUtils.showAlertDialog(context, tcontext.remarkExist);
          return false;
        }
      }

      return true;
    });

    if (text != null) {
      ServerDiversionGroupItem diversionItem =
          ServerManager.getDiversionCustomGroup();
      DiversionRulesGroup drg = DiversionRulesGroup();
      drg.name = text;
      drg.groupid = diversionItem.groupid;
      drg.index = diversionItem.groups.length;
      diversionItem.groups.add(drg);
      diversionItem.groups.sort(sortCompare);
      ServerManager.saveDiversionGroupConfig();

      _buildData();
      setState(() {});
    }
  }

  void onTapModifyName(String current) async {
    final tcontext = Translations.of(context);
    String? text = await DialogUtils.showTextInputDialog(
        context, tcontext.remark, current, null, null, (text) {
      text = text.trim();
      if (text.isEmpty) {
        DialogUtils.showAlertDialog(context, tcontext.remarkCannotEmpty);
        return false;
      }

      if (text.length > kRemarkMaxLength) {
        DialogUtils.showAlertDialog(context, tcontext.remarkTooLong);
        return false;
      }
      ServerDiversionGroupItem diversionItem =
          ServerManager.getDiversionCustomGroup();
      for (var group in diversionItem.groups) {
        if (group.name == text) {
          DialogUtils.showAlertDialog(context, tcontext.remarkExist);
          return false;
        }
      }

      return true;
    });

    if (text != null) {
      ServerDiversionGroupItem diversionItem =
          ServerManager.getDiversionCustomGroup();
      for (var group in diversionItem.groups) {
        if (group.name == current) {
          var use = ServerManager.getUse();
          for (var d in use.diversionGroup) {
            if (d.diversionGroupId == ServerManager.getCustomGroupId() &&
                d.diversionName == group.name) {
              d.diversionName = text;
              ServerManager.saveUse();
              break;
            }
          }

          group.name = text;
          ServerManager.saveDiversionGroupConfig();
          _buildData();
          setState(() {});
          break;
        }
      }
    }
  }

  void onTapItem(String current) {
    DiversionGroupCustomEditOptions newOptions =
        DiversionGroupCustomEditOptions();
    newOptions.showLogicOperations = true;
    newOptions.domainSuffix = "";
    newOptions.domain = "";
    newOptions.domainKeyword = "";
    newOptions.domainRegex = "";
    newOptions.ipCidr = "";
    newOptions.port = "";
    newOptions.protocol = "";
    newOptions.ruleSet = "";
    newOptions.ruleSetBuildIn = "";
    newOptions.package = "";
    newOptions.processName = "";
    newOptions.processPath = "";

    DiversionGroupCustomEditOptions options =
        widget.options == null ? newOptions : widget.options!;

    Navigator.push(
        context,
        MaterialPageRoute(
            settings: DiversionGroupCustomEditScreen.routSettings(),
            builder: (context) => DiversionGroupCustomEditScreen(
                name: current, options: options)));
  }

  void onTapDel(String current) async {
    final tcontext = Translations.of(context);
    bool? del =
        await DialogUtils.showConfirmDialog(context, tcontext.removeConfirm);
    if (del == true) {
      ServerDiversionGroupItem diversionItem =
          ServerManager.getDiversionCustomGroup();

      var use = ServerManager.getUse();
      for (int i = 0; i < use.diversionGroup.length; i++) {
        if (use.diversionGroup[i].diversionGroupId == diversionItem.groupid &&
            use.diversionGroup[i].diversionName == current) {
          use.diversionGroup.removeAt(i);
          break;
        }
      }

      for (int i = 0; i < diversionItem.groups.length; i++) {
        if (diversionItem.groups[i].name == current) {
          diversionItem.groups.removeAt(i);
          diversionItem.groups.sort(sortCompare);
          ServerManager.setDirty(true);
          _buildData();
          setState(() {});
          break;
        }
      }
    }
  }
}