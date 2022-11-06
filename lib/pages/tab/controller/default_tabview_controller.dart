import 'dart:ui' show ImageFilter;

import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:dio/dio.dart';
import 'package:fehviewer/common/service/ehconfig_service.dart';
import 'package:fehviewer/common/service/layout_service.dart';
import 'package:fehviewer/common/service/theme_service.dart';
import 'package:fehviewer/component/exception/error.dart';
import 'package:fehviewer/const/theme_colors.dart';
import 'package:fehviewer/fehviewer.dart';
import 'package:fehviewer/pages/tab/controller/search_page_controller.dart';
import 'package:fehviewer/pages/tab/controller/tabhome_controller.dart';
import 'package:fehviewer/pages/tab/controller/toplist_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../utils/app_cupertino_localizations_delegate.dart';
import '../comm.dart';
import '../fetch_list.dart';
import 'enum.dart';
import 'tabview_controller.dart';

const CupertinoDynamicColor _kClearButtonColor =
    CupertinoDynamicColor.withBrightness(
  color: Color(0xFF636366),
  darkColor: Color(0xFFAEAEB2),
);

class DefaultTabViewController extends TabViewController {
  DefaultTabViewController();

  int? cats;

  final RxBool _isBackgroundRefresh = false.obs;

  bool get isBackgroundRefresh => _isBackgroundRefresh.value;

  set isBackgroundRefresh(bool val) => _isBackgroundRefresh.value = val;

  String? initSearchText;
  final RxString _searchText = ''.obs;

  String get searchText => _searchText.value;

  set searchText(String val) => _searchText.value = val;

  // 搜索类型
  final Rx<SearchType> _searchType = SearchType.normal.obs;

  SearchType get searchType => _searchType.value;

  set searchType(SearchType val) => _searchType.value = val;

  // 页码跳转输入框的控制器
  final TextEditingController pageJumpTextEditController =
      TextEditingController();

  final TextEditingController gidTextEditController = TextEditingController();

  final TextEditingController jumpOrSeekTextEditController =
      TextEditingController();
  final gidNode = FocusNode();

  FetchListClient? fetchClient;

  String? _curFavcat;

  String get curFavcat {
    return _curFavcat ?? ehConfigService.lastShowFavcat ?? 'a';
  }

  set curFavcat(String? val) {
    _curFavcat = val;
  }

  String get currToplist => topListVal[ehConfigService.toplist] ?? '15';

  int lastTopitemIndex = 0;

  final previousList = <GalleryProvider>[].obs;

  bool lastItemBuildComplete = false;

  @override
  Future<void> firstLoad() async {
    await super.firstLoad();
    lastItemBuildComplete = false;

    try {
      if (cancelToken?.isCancelled ?? false) {
        return;
      }
      isBackgroundRefresh = true;
      await reloadData();
    } catch (_) {
    } finally {
      isBackgroundRefresh = false;
    }
  }

  FetchListClient getFetchListClient(FetchParams fetchParams) {
    return DefaultFetchListClient(fetchParams: fetchParams);
  }

  @override
  Future<GalleryList?> fetchData({bool refresh = false}) async {
    final int _catNum = ehConfigService.catFilter.value;
    cancelToken = CancelToken();

    final fetchConfig = FetchParams(
      cats: cats ?? _catNum,
      toplist: currToplist,
      refresh: refresh,
      cancelToken: cancelToken,
      searchType: searchType,
      searchText: searchText,
    );

    pageState = PageState.Loading;

    try {
      FetchListClient fetchListClient = getFetchListClient(fetchConfig);
      final GalleryList? rult = await fetchListClient.fetch();

      if (cancelToken?.isCancelled ?? false) {
        return null;
      }

      pageState = PageState.None;

      final _list = rult?.gallerys
              ?.map((e) => e.simpleTags ?? [])
              .expand((List<SimpleTag> element) => element)
              .toList() ??
          [];

      tagController.addAllSimpleTag(_list);
      return rult;
    } on EhError catch (eherror) {
      logger.e('type:${eherror.type}\n${eherror.message}');
      showToast(eherror.message);
      pageState = PageState.LoadingError;
      rethrow;
    } on Exception catch (e) {
      pageState = PageState.LoadingError;
      rethrow;
    }
  }

  @override
  Future<void> reloadData() async {
    await super.reloadData();
    lastItemBuildComplete = false;
  }

  @override
  Future<void> onRefresh() async {
    isBackgroundRefresh = false;
    await super.onRefresh();
  }

  @override
  Future<void> reLoadDataFirst() async {
    logger.d('reLoadDataFirst isCancelled ${cancelToken?.isCancelled}');
    isBackgroundRefresh = false;
    await super.reLoadDataFirst();
  }

  @override
  Future<GalleryList?> fetchMoreData() async {
    final fetchConfig = FetchParams(
      pageType: PageType.next,
      gid: next,
      cats: cats ?? ehConfigService.catFilter.value,
      refresh: true,
      cancelToken: cancelToken,
      favcat: curFavcat,
      toplist: currToplist,
      searchType: searchType,
      searchText: searchText,
    );

    FetchListClient fetchListClient = getFetchListClient(fetchConfig);
    return await fetchListClient.fetch();
  }

  @override
  Future<GalleryList?> fetchPrevData() async {
    final fetchConfig = FetchParams(
      pageType: PageType.prev,
      gid: prev,
      cats: cats ?? ehConfigService.catFilter.value,
      refresh: true,
      cancelToken: cancelToken,
      favcat: curFavcat,
      toplist: currToplist,
      searchType: searchType,
      searchText: searchText,
    );
    FetchListClient fetchListClient = getFetchListClient(fetchConfig);
    return await fetchListClient.fetch();
  }

  @override
  Future<void> loadDataMore() async {
    // 增加延时 避免build期间进行 setState
    await Future<void>.delayed(const Duration(milliseconds: 100));

    super.loadDataMore();
    lastItemBuildComplete = false;
  }

  @override
  Future<GalleryList?> fetchDataFrom({
    String? gid,
    PageType? pageType,
    String? jump,
    String? seek,
  }) async {
    final fetchConfig = FetchParams(
      pageType: pageType,
      gid: gid,
      cats: cats ?? ehConfigService.catFilter.value,
      refresh: true,
      cancelToken: cancelToken,
      favcat: curFavcat,
      toplist: currToplist,
      searchType: searchType,
      searchText: searchText,
      jump: jump,
      seek: seek,
    );

    FetchListClient fetchListClient = getFetchListClient(fetchConfig);
    final result = await fetchListClient.fetch();
    return result;
  }

  // @override
  // Future<void> loadFromPage(int page, {bool previous = false}) async {
  //   await super.loadFromPage(page);
  //   logger.d('jump to page =>  $page');
  //
  //   final int _catNum = ehConfigService.catFilter.value;
  //   pageState = PageState.Loading;
  //   if (!previous) {
  //     change(state, status: RxStatus.loading());
  //   }
  //
  //   previousList.clear();
  //
  //   final fetchConfig = FetchParams(
  //     pageType: page,
  //     cats: cats ?? _catNum,
  //     refresh: true,
  //     cancelToken: cancelToken,
  //     favcat: curFavcat,
  //     toplist: currToplist,
  //     searchText: searchText,
  //     searchType: searchType,
  //   );
  //   try {
  //     FetchListClient fetchListClient = getFetchListClient(fetchConfig);
  //     final GalleryList? rult = await fetchListClient.fetch();
  //
  //     curPage = page;
  //     minPage = page;
  //     if (!previous) {
  //       nextPage = rult?.nextPage ?? page + 1;
  //     }
  //     prevPage = rult?.prevPage;
  //     logger.d('after loadFromPage nextPage is $nextPage');
  //     if (rult != null) {
  //       if (previous) {
  //         state?.insertAll(0, rult.gallerys ?? []);
  //         change(state, status: RxStatus.success());
  //       } else {
  //         change(rult.gallerys, status: RxStatus.success());
  //       }
  //     }
  //     pageState = PageState.None;
  //     lastItemBuildComplete = false;
  //   } catch (e) {
  //     pageState = PageState.LoadingError;
  //     if (!previous) {
  //       change(null, status: RxStatus.error('$e'));
  //     } else {
  //       showToast('$e');
  //     }
  //     rethrow;
  //   } finally {
  //     canLoadMore = true;
  //   }
  // }

  /// 跳转页码
  // Future<void> showJumpToPage() async {
  //   void _jump() {
  //     final String _input = pageJumpTextEditController.text.trim();
  //
  //     if (_input.isEmpty) {
  //       showToast(L10n.of(Get.context!).input_empty);
  //     }
  //
  //     // 数字检查
  //     if (!RegExp(r'(^\d+$)').hasMatch(_input)) {
  //       showToast(L10n.of(Get.context!).input_error);
  //     }
  //
  //     final int _toPage = int.parse(_input) - 1;
  //     if (_toPage >= 0 && _toPage <= maxPage - 1) {
  //       FocusScope.of(Get.context!).requestFocus(FocusNode());
  //       loadFromPage(_toPage);
  //       Get.back();
  //     } else {
  //       showToast(L10n.of(Get.context!).page_range_error);
  //     }
  //   }
  //
  //   return showJumpDialog(jump: _jump, maxPage: maxPage);
  // }

  final _showDatePicker = false.obs;

  bool get showDatePicker => _showDatePicker.value;

  set showDatePicker(bool value) => _showDatePicker.value = value;

  Future<void> showJumpDialog(BuildContext context) async {
    bool editingDate = false;
    bool editingGid = false;
    return showCupertinoDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(L10n.of(context).jump_or_seek),
          content: Container(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(L10n.of(context).enter_date_or_offset_or_gid),
                ),
                StatefulBuilder(builder: (context, setState) {
                  return CupertinoTextField(
                    decoration: BoxDecoration(
                      color: ehTheme.textFieldBackgroundColor,
                      borderRadius:
                          const BorderRadius.all(Radius.circular(8.0)),
                    ),
                    clearButtonMode: OverlayVisibilityMode.editing,
                    placeholder: L10n.of(context).date_or_offset,
                    controller: jumpOrSeekTextEditController,
                    autofocus: true,
                    suffix: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (editingDate)
                          GestureDetector(
                            onTap: () {
                              jumpOrSeekTextEditController.clear();
                              setState(() {
                                editingDate = false;
                              });
                            },
                            child: Icon(
                              FontAwesomeIcons.circleXmark,
                              size: 20.0,
                              color: CupertinoDynamicColor.resolve(
                                  _kClearButtonColor, Get.context!),
                            ).paddingSymmetric(horizontal: 6),
                          ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              showDatePicker = !showDatePicker;
                            });
                          },
                          child: Icon(
                            FontAwesomeIcons.calendar,
                            size: 20.0,
                            color: showDatePicker
                                ? null
                                : CupertinoDynamicColor.resolve(
                                    _kClearButtonColor, Get.context!),
                          ).paddingSymmetric(horizontal: 6),
                        ),
                      ],
                    ),
                    onChanged: (value) {
                      setState(() {
                        editingDate = value.isNotEmpty;
                      });
                    },
                    // keyboardType: TextInputType.number,
                    onEditingComplete: () {
                      // 点击键盘完成
                      FocusScope.of(context).requestFocus(gidNode);
                    },
                  );
                }),
                Obx(() {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(top: 8.0),
                    padding: const EdgeInsets.only(top: 1),
                    height: showDatePicker ? 120 : 1.1,
                    child: Localizations.override(
                      context: context,
                      delegates: const [
                        AppGlobalCupertinoLocalizationsDelegate(),
                      ],
                      child: CupertinoDatePicker(
                        // yyyy-MM-dd
                        mode: CupertinoDatePickerMode.date,
                        dateOrder: DatePickerDateOrder.ymd,
                        minimumYear: 2007,
                        maximumYear: DateTime.now().year,
                        onDateTimeChanged: (value) {
                          jumpOrSeekTextEditController.text =
                              DateFormat('yyyy-MM-dd').format(value);
                        },
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                StatefulBuilder(builder: (context, setState) {
                  return CupertinoTextField(
                    decoration: BoxDecoration(
                      color: ehTheme.textFieldBackgroundColor,
                      borderRadius:
                          const BorderRadius.all(Radius.circular(8.0)),
                    ),
                    clearButtonMode: OverlayVisibilityMode.editing,
                    focusNode: gidNode,
                    placeholder: 'GID',
                    controller: gidTextEditController,
                    // keyboardType: TextInputType.number,
                    suffix: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (editingGid)
                          GestureDetector(
                            onTap: () {
                              gidTextEditController.clear();
                              setState(() {
                                editingGid = false;
                              });
                            },
                            child: Icon(
                              FontAwesomeIcons.circleXmark,
                              size: 20.0,
                              color: CupertinoDynamicColor.resolve(
                                  _kClearButtonColor, Get.context!),
                            ).paddingSymmetric(horizontal: 6),
                          ),
                      ],
                    ),
                    onChanged: (value) {
                      setState(() {
                        editingGid = value.isNotEmpty;
                      });
                    },
                    onEditingComplete: () {
                      // 点击键盘完成
                      _jumpToPage(
                        pageType: PageType.next,
                      );
                    },
                  );
                }),
                const SizedBox(height: 8),
                if (prev.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.circleArrowLeft,
                        size: 16,
                        color: CupertinoDynamicColor.resolve(
                            CupertinoColors.secondaryLabel, context),
                      ).paddingSymmetric(horizontal: 8),
                      Expanded(
                          child: Text(
                        prev,
                        textAlign: TextAlign.start,
                      )),
                    ],
                  ),
                if (next.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.circleArrowRight,
                        size: 16,
                        color: CupertinoDynamicColor.resolve(
                            CupertinoColors.secondaryLabel, context),
                      ).paddingSymmetric(horizontal: 8),
                      Expanded(
                          child: Text(
                        next,
                        textAlign: TextAlign.start,
                      )),
                    ],
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              // child: Text(L10n.of(context).jump_prev),
              child: const Icon(
                FontAwesomeIcons.circleArrowLeft,
              ),
              onPressed: () async {
                // _jumpToPage(pageType: PageType.prev);
                try {
                  await _jumpToPage(pageType: PageType.prev);
                } catch (e, stack) {
                  logger.e('jump to Next error', e, stack);
                  showToast('$e');
                }
              },
            ),
            CupertinoDialogAction(
              // child: Text(L10n.of(context).jump_next),
              child: const Icon(
                FontAwesomeIcons.circleArrowRight,
              ),
              onPressed: () async {
                // 画廊跳转
                logger.d('jump to Next');
                try {
                  await _jumpToPage(
                    pageType: PageType.next,
                  );
                } catch (e, stack) {
                  logger.e('jump to Next error', e, stack);
                  showToast(e.toString());
                }
                // _jumpToPage(pageType: PageType.next);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _jumpToPage({
    PageType? pageType,
  }) async {
    final String jumpOrSeek = jumpOrSeekTextEditController.text.trim();
    final String _gid = gidTextEditController.text.trim();

    logger.d('jumpOrSeek is $jumpOrSeek _gid is $_gid');

    if (jumpOrSeek.isEmpty && _gid.isEmpty) {
      showToast(L10n.of(Get.context!).input_empty);
      return;
    }

    final jumpExp = RegExp(r'^\d+[wmy]?$');
    // YYYY, YYYY-MM or YYYY-MM-DD
    final dateExpFull = RegExp(r'^\d{4}(-\d{2}){0,2}$');
    // YY-MM or YY-MM-DD
    final dateExpShort = RegExp(r'^\d{2}(-\d{2}){1,2}$');

    String jump = '';
    String seek = '';
    if (jumpExp.hasMatch(jumpOrSeek)) {
      jump = jumpOrSeek;
    } else if (dateExpFull.hasMatch(jumpOrSeek) ||
        dateExpShort.hasMatch(jumpOrSeek)) {
      seek = jumpOrSeek;
    } else {
      showToast(L10n.of(Get.context!).input_error);
    }

    logger.d('jump is $jump, seek is $seek, gid is $_gid');

    FocusScope.of(Get.context!).requestFocus(FocusNode());

    // if _gid is not empty, toGid is _gid ,
    // else if pageType is prev, toGid is prev,
    // else if pageType is next, toGid is next
    final toGid = _gid.isEmpty
        ? pageType == PageType.prev
            ? prev
            : next
        : _gid;

    loadFrom(
      jump: jump,
      seek: seek,
      gid: toGid,
      pageType: pageType,
    );
    Get.back();
  }

  // Future showJumpDialog({VoidCallback? jump, int? maxPage}) {
  //   return showCupertinoDialog<void>(
  //     context: Get.context!,
  //     builder: (BuildContext context) {
  //       return CupertinoAlertDialog(
  //         title: Text(L10n.of(context).jump_to_page),
  //         content: Container(
  //           child: Column(
  //             children: <Widget>[
  //               Padding(
  //                 padding: const EdgeInsets.all(8.0),
  //                 child: Text('${L10n.of(context).page_range} 1~$maxPage'),
  //               ),
  //               CupertinoTextField(
  //                 decoration: BoxDecoration(
  //                   color: ehTheme.textFieldBackgroundColor,
  //                   borderRadius: const BorderRadius.all(Radius.circular(8.0)),
  //                 ),
  //                 controller: pageJumpTextEditController,
  //                 autofocus: true,
  //                 keyboardType: TextInputType.number,
  //                 onEditingComplete: () {
  //                   // 点击键盘完成
  //                   // 画廊跳转
  //                   jump?.call();
  //                 },
  //               )
  //             ],
  //           ),
  //         ),
  //         actions: <Widget>[
  //           CupertinoDialogAction(
  //             child: Text(L10n.of(context).cancel),
  //             onPressed: () {
  //               Get.back();
  //             },
  //           ),
  //           CupertinoDialogAction(
  //             child: Text(
  //               L10n.of(context).ok,
  //               style: const TextStyle(fontWeight: FontWeight.w500),
  //             ),
  //             onPressed: () {
  //               // 画廊跳转
  //               jump?.call();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  @override
  Future<void> lastComplete() async {
    lastItemBuildComplete = true;
  }

  final TabHomeController _tabHomeController = Get.find();

  int get hidenTagCount => _tabHomeController.tabMap.entries
      .where((MapEntry<String, bool> element) => !element.value)
      .length;

  // 至少收起两个的时候 使用PopupMenu
  bool get enablePopupMenu => hidenTagCount >= 2;

  bool get enableSingle => hidenTagCount == 1;

  String get singleTabFlag => _tabHomeController.tabMap.entries
      .where((MapEntry<String, bool> element) => !element.value)
      .first
      .key;

  final CustomPopupMenuController customPopupMenuController =
      CustomPopupMenuController();

  Widget get popupMenu {
    final List<Widget> _menu = <Widget>[];
    for (final MapEntry<String, bool> elem
        in _tabHomeController.tabMap.entries) {
      if (!elem.value) {
        _menu.add(
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              // vibrateUtil.light();
              customPopupMenuController.hideMenu();
              Get.toNamed(
                elem.key,
                id: isLayoutLarge ? 1 : null,
              );
            },
            child: Container(
              padding:
                  const EdgeInsets.only(left: 14, right: 18, top: 5, bottom: 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    tabPages.iconDatas[elem.key],
                    size: 20,
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(left: 10),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        tabPages.tabTitles[elem.key] ?? '',
                        style: TextStyle(
                          color: CupertinoDynamicColor.resolve(
                              CupertinoColors.label, Get.context!),
                          fontWeight: FontWeight.normal,
                          // fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: _menu,
    );
  }

  Widget buildLeadingSingle(BuildContext context) {
    if (!enableSingle) {
      return const SizedBox.shrink();
    }

    final tabFlag = singleTabFlag;

    return CupertinoButton(
        child: Icon(
          tabPages.iconDatas[tabFlag],
          size: 20,
        ),
        onPressed: () {
          Get.toNamed(
            tabFlag,
            id: isLayoutLarge ? 1 : null,
          );
        });
  }

  Widget buildLeadingCustomPopupMenu(BuildContext context) {
    return CupertinoTheme(
      data: ehTheme.themeData!,
      child: CustomPopupMenu(
        child: Container(
          padding: const EdgeInsets.only(left: 14, bottom: 2),
          child: const Icon(
            CupertinoIcons.ellipsis_circle,
            size: 24,
          ),
        ),
        // arrowColor: _color,
        showArrow: false,
        menuBuilder: () {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
              child: Container(
                color: CupertinoDynamicColor.resolve(
                    ThemeColors.dialogColor, context),
                child: IntrinsicWidth(
                  child: popupMenu,
                ),
              ),
            ),
          );
        },
        pressType: PressType.singleClick,
        verticalMargin: -2,
        horizontalMargin: 8,
        controller: customPopupMenuController,
      ),
    );
  }

  Widget? getLeading(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      return null;
    }

    return Obx(() {
      if (enablePopupMenu && (!Get.find<EhConfigService>().isSafeMode.value)) {
        return buildLeadingCustomPopupMenu(context);
      }

      if (enableSingle) {
        return buildLeadingSingle(context);
      }
      return const SizedBox.shrink();
    });
  }

  void initStateForListPage({
    required BuildContext context,
    required EhTabController ehTabController,
  }) {
    initEhTabController(context: context, ehTabController: ehTabController);

    initStateAddPostFrameCallback(context);
  }

  void initStateAddPostFrameCallback(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final _scrollController = PrimaryScrollController.of(context);
      _scrollController?.addListener(() async {
        if (_scrollController.position.pixels >
            _scrollController.position.maxScrollExtent -
                context.mediaQuerySize.longestSide) {
          if ((next).isNotEmpty &&
              lastItemBuildComplete &&
              pageState != PageState.Loading) {
            // 加载更多
            await loadDataMore();
          } else {
            // 没有更多了
            // showToast('No More');
          }
        }
      });
    });
  }
}
