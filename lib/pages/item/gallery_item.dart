import 'package:cached_network_image/cached_network_image.dart';
import 'package:fehviewer/common/exts.dart';
import 'package:fehviewer/common/global.dart';
import 'package:fehviewer/common/service/ehconfig_service.dart';
import 'package:fehviewer/common/service/layout_service.dart';
import 'package:fehviewer/const/theme_colors.dart';
import 'package:fehviewer/extension.dart';
import 'package:fehviewer/models/index.dart';
import 'package:fehviewer/pages/item/controller/galleryitem_controller.dart';
import 'package:fehviewer/utils/logger.dart';
import 'package:fehviewer/utils/utility.dart';
import 'package:fehviewer/widget/blur_image.dart';
import 'package:fehviewer/widget/rating_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

const double kPaddingHorizontal = 12.0;
const double kPaddingVertical = 18.0;

/// 画廊列表项
/// 标题和tag需要随设置变化重构ui
// ignore: must_be_immutable
class GalleryItemWidget extends StatefulWidget {
  const GalleryItemWidget(
      {Key? key, required this.tabTag, required this.galleryItem})
      : super(key: key);

  final GalleryItem galleryItem;
  final dynamic tabTag;

  @override
  _GalleryItemWidgetState createState() => _GalleryItemWidgetState();
}

class _GalleryItemWidgetState extends State<GalleryItemWidget> {
  late GalleryItemController galleryItemController;
  @override
  void initState() {
    logger.d('_GalleryItemWidgetState initState');
    super.initState();
    galleryItemController = Get.put(GalleryItemController(widget.galleryItem),
        tag: widget.galleryItem.gid);
  }

  @override
  void didChangeDependencies() {
    logger.d('_GalleryItemWidgetState didChangeDependencies');
    super.didChangeDependencies();
    if (Get.isRegistered<GalleryItemController>(tag: widget.galleryItem.gid)) {
      Get.replace(GalleryItemController(widget.galleryItem),
          tag: widget.galleryItem.gid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Center(
        child: Stack(
          children: [
            _buildItem(),
            if (Get.find<EhConfigService>().debugMode)
              Positioned(
                left: 4,
                top: 4,
                child: Text('${widget.galleryItem.pageOfList ?? ''}',
                    style: const TextStyle(
                        fontSize: 20,
                        color: CupertinoColors.secondarySystemBackground,
                        shadows: <Shadow>[
                          Shadow(
                            color: Colors.black,
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          )
                        ])),
              ),
          ],
        ),
      ),
      behavior: HitTestBehavior.opaque,
      onTap: () => galleryItemController.onTap(widget.tabTag),
      onTapDown: galleryItemController.onTapDown,
      onTapUp: galleryItemController.onTapUp,
      onTapCancel: galleryItemController.onTapCancel,
      onLongPress: galleryItemController.onLongPress,
    ).autoCompressKeyboard(context);
  }

  Widget _buildItem() {
    return Obx(() => Column(
          children: <Widget>[
            Container(
              color: galleryItemController.colorTap.value,
              padding: const EdgeInsets.symmetric(
                  horizontal: kPaddingHorizontal, vertical: kPaddingVertical),
              child: IntrinsicHeight(
                child: Row(children: <Widget>[
                  // 封面图片
                  _buildCoverImage(),
                  Container(
                    width: 8,
                  ),
                  // 右侧信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // 标题 provider
                        _buildTitle(),
                        // 上传者
                        Text(
                          galleryItemController.galleryItem.uploader ?? '',
                          style: const TextStyle(
                              fontSize: 12, color: CupertinoColors.systemGrey),
                        ),
                        // 标签
                        TagBox(
                          simpleTags:
                              galleryItemController.galleryItem.simpleTags ??
                                  [],
                        ),

                        Spacer(),
                        // 评分行
                        GetBuilder(
                          init: galleryItemController,
                          tag: galleryItemController.galleryItem.gid,
                          builder: (_) => Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              // 评分
                              _buildRating(),
                              // 占位
                              const Spacer(),
                              // 收藏图标
                              _buildFavcatIcon(),
                              // 图片数量
                              _buildFilecontWidget(),
                            ],
                          ),
                        ),
                        Container(
                          height: 4,
                        ),
                        // 类型和时间
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            // 类型
                            _buildCategory(),
                            const Spacer(),
                            // 上传时间
                            _buildPostTime(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
            Divider(
              height: 0.5,
              indent: kPaddingHorizontal,
              color: CupertinoDynamicColor.resolve(
                  CupertinoColors.systemGrey4, Get.context!),
            ),
          ],
        ));
  }

  /// 构建标题
  Widget _buildTitle() {
    return Obx(() => Text(
          galleryItemController.title,
          maxLines: 4,
          textAlign: TextAlign.left, // 对齐方式
          overflow: TextOverflow.ellipsis, // 超出部分省略号
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            // color: CupertinoColors.label,
          ),
        ));
  }

  /// 构建封面图片
  Widget _buildCoverImage() {
    final GalleryItem _item = galleryItemController.galleryItem;

    final double coverImageWidth =
        Get.context!.isPhone ? Get.context!.mediaQueryShortestSide / 3 : 120;

    // 获取图片高度 用于占位
    double? _getHeigth() {
      if ((_item.imgWidth ?? 0) >= coverImageWidth) {
        return (_item.imgHeight ?? 0) * coverImageWidth / (_item.imgWidth ?? 0);
      } else {
        return _item.imgHeight;
      }
    }

    // logger.v('hero item => ${galleryItem.gid}_cover_$tabTag');
    // logger.d('${_item.englishTitle} ${_getHeigth()}');

    Widget image = Container(
      decoration: BoxDecoration(boxShadow: [
        //阴影
        BoxShadow(
          color: CupertinoDynamicColor.resolve(
              CupertinoColors.systemGrey4, Get.context!),
          blurRadius: 10,
        )
      ]),
      child: ClipRRect(
        // 圆角
        borderRadius: BorderRadius.circular(6),
        child: CoverImg(
          imgUrl: _item.imgUrl ?? '',
          height: _item.imgWidth != null ? _getHeigth() : null,
        ),
      ),
    );

    return Container(
      width: coverImageWidth,
      height: _item.imgWidth != null ? _getHeigth() : null,
      alignment: Alignment.center,
      child: !isLayoutLarge
          ? Hero(
              tag: '${_item.gid}_cover_${widget.tabTag}',
              child: image,
            )
          : image,
    );
  }

  Widget _buildRating() {
    // logger.d(
    //     'ratingFallBack ${_galleryItemController.galleryItem.ratingFallBack} ');
    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
          child: StaticRatingBar(
            size: 16.0,
            rate: galleryItemController.galleryItem.ratingFallBack ?? 0,
            radiusRatio: 1.5,
            colorLight: ThemeColors.colorRatingMap[
                galleryItemController.galleryItem.colorRating?.trim() ?? 'ir'],
            colorDark: CupertinoDynamicColor.resolve(
                CupertinoColors.systemGrey3, Get.context!),
          ),
        ),
        Text(
          galleryItemController.galleryItem.rating?.toString() ?? '',
          style: TextStyle(
            fontSize: 11,
            color: CupertinoDynamicColor.resolve(
                CupertinoColors.systemGrey, Get.context!),
          ),
        ),
      ],
    );
  }

  Widget _buildFilecontWidget() {
    return Row(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Text(
            galleryItemController.galleryItem.translated ?? '',
            style: const TextStyle(
                fontSize: 12, color: CupertinoColors.systemGrey),
          ),
        ),
        const Icon(
          Icons.panorama,
          size: 13,
          color: CupertinoColors.systemGrey,
        ),
        Container(
          padding: const EdgeInsets.only(left: 2),
          child: Text(
            galleryItemController.galleryItem.filecount ?? '',
            style: const TextStyle(
                fontSize: 12, color: CupertinoColors.systemGrey),
          ),
        ),
      ],
    );
  }

  Widget _buildFavcatIcon() {
    return Obx(() {
      // logger.d('${_galleryItemController.isFav}');
      return Container(
        child: galleryItemController.isFav
            ? Container(
                padding: const EdgeInsets.only(bottom: 2, right: 2, left: 2),
                child: Icon(
                  FontAwesomeIcons.solidHeart,
                  size: 12,
                  color: ThemeColors
                      .favColor[galleryItemController.galleryItem.favcat],
                ),
              )
            : Container(),
      );
    });
  }

  Widget _buildPostTime() {
    return Text(
      galleryItemController.galleryItem.postTime ?? '',
      style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
    );
  }

  Widget _buildCategory() {
    final Color _colorCategory = CupertinoDynamicColor.resolve(
        ThemeColors.catColor[
                galleryItemController.galleryItem.category ?? 'default'] ??
            CupertinoColors.systemBackground,
        Get.context!);

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 3, 6, 3),
        color: _colorCategory,
        child: Text(
          galleryItemController.galleryItem.category ?? '',
          style: const TextStyle(
            fontSize: 14,
            height: 1,
            color: CupertinoColors.white,
          ),
        ),
      ),
    );
  }
}

class TagItem extends StatelessWidget {
  const TagItem({
    Key? key,
    this.text,
    this.color,
    this.backgrondColor,
  }) : super(key: key);

  final String? text;
  final Color? color;
  final Color? backgrondColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        // height: 18,
        padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
        color: backgrondColor ??
            CupertinoDynamicColor.resolve(ThemeColors.tagBackground, context),
        child: Text(
          text ?? '',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            height: 1,
            fontWeight:
                backgrondColor == null ? FontWeight.w400 : FontWeight.w500,
            color: color ??
                CupertinoDynamicColor.resolve(ThemeColors.tagText, context),
          ),
          strutStyle: const StrutStyle(height: 1),
        ),
      ),
    );
  }
}

/// 传入原始标签和翻译标签
/// 用于设置切换的时候变更
class TagBox extends StatelessWidget {
  const TagBox({Key? key, this.simpleTags}) : super(key: key);

  final List<SimpleTag>? simpleTags;

  @override
  Widget build(BuildContext context) {
    final EhConfigService _ehConfigService = Get.find();
    return simpleTags != null && simpleTags!.isNotEmpty
        ? Obx(() => Container(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
              child: Wrap(
                spacing: 4, //主轴上子控件的间距
                runSpacing: 4, //交叉轴上子控件之间的间距
                children:
                    List<Widget>.from(simpleTags!.map((SimpleTag _simpleTag) {
                  final String? _text = _ehConfigService.isTagTranslat
                      ? _simpleTag.translat
                      : _simpleTag.text;
                  return TagItem(
                    text: _text,
                    color: ColorsUtil.getTagColor(_simpleTag.color),
                    backgrondColor:
                        ColorsUtil.getTagColor(_simpleTag.backgrondColor),
                  );
                }).toList()), //要显示的子控件集合
              ),
            ))
        : Container();
  }
}

class TagListViewBox extends StatelessWidget {
  const TagListViewBox({Key? key, this.simpleTags}) : super(key: key);

  final List<SimpleTag>? simpleTags;

  @override
  Widget build(BuildContext context) {
    final EhConfigService _ehConfigService = Get.find();
    return simpleTags != null && simpleTags!.isNotEmpty
        ? Obx(() => Container(
              height: 18,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children:
                    List<Widget>.from(simpleTags!.map((SimpleTag _simpleTag) {
                  final String? _text = _ehConfigService.isTagTranslat
                      ? _simpleTag.translat
                      : _simpleTag.text;
                  return TagItem(
                    text: _text,
                    color: ColorsUtil.getTagColor(_simpleTag.color),
                    backgrondColor:
                        ColorsUtil.getTagColor(_simpleTag.backgrondColor),
                  ).paddingOnly(right: 4.0);
                }).toList()), //要显示的子控件集合
              ),
            ))
        : Container();
  }
}

/// 封面图片Widget
class CoverImg extends StatelessWidget {
  const CoverImg({
    Key? key,
    required this.imgUrl,
    this.height,
    this.width,
  }) : super(key: key);

  final String imgUrl;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final EhConfigService ehConfigService = Get.find();
    final Map<String, String> _httpHeaders = {
      'Cookie': Global.profile.user.cookie ?? '',
      'host': Uri.parse(imgUrl).host,
    };

    Widget image() {
      if (imgUrl.isNotEmpty) {
        return CachedNetworkImage(
          placeholder: (_, __) {
            return Container(
              alignment: Alignment.center,
              color: CupertinoDynamicColor.resolve(
                  CupertinoColors.systemGrey5, context),
              child: const CupertinoActivityIndicator(),
            );
          },
          // height: height,
          width: width,
          httpHeaders: _httpHeaders,
          imageUrl: imgUrl.dfUrl,
          fit: BoxFit.contain,
        );
        // return NetworkExtendedImage(
        //   url: imgUrl,
        // );
      } else {
        return Container();
      }
    }

    return Obx(() => BlurImage(
          isBlur: ehConfigService.isGalleryImgBlur.value,
          child: image(),
        ));
  }
}

class GalleryItemPlaceHolder extends StatelessWidget {
  const GalleryItemPlaceHolder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double coverImageWidth =
        Get.context!.isPhone ? Get.context!.mediaQueryShortestSide / 3 : 120;

    final _line = ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        color:
            CupertinoDynamicColor.resolve(CupertinoColors.systemGrey5, context),
        height: 16,
      ),
    ).paddingSymmetric(vertical: 4);

    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: kPaddingHorizontal, vertical: kPaddingVertical),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  // 封面图片
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      constraints:
                          const BoxConstraints(maxHeight: 250, minHeight: 100),
                      color: CupertinoDynamicColor.resolve(
                          CupertinoColors.systemGrey5, context),
                      width: coverImageWidth,
                      child: const SizedBox(
                        height: 150,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  // 右侧信息
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _line,
                          _line,
                          Container(width: 70, child: _line),
                          const SizedBox(height: 4),
                          _line,
                          Container(width: 70, child: _line),

                          // 评分行
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              // 评分
                              Container(width: 50, child: _line),
                              // 占位
                              const Spacer(),
                              Container(width: 50, child: _line),
                            ],
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          // 类型和时间
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              // 类型
                              // _buildCategory(),
                              const Spacer(),
                              // 上传时间
                              // _buildPostTime(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Divider(
          height: 0.5,
          indent: kPaddingHorizontal,
          color: CupertinoDynamicColor.resolve(
              CupertinoColors.systemGrey4, Get.context!),
        ),
      ],
    );
  }
}
