import 'dart:ui';

import 'package:fehviewer/models/galleryItem.dart';
import 'package:fehviewer/pages/item/controller/galleryitem_controller.dart';
import 'package:fehviewer/route/navigator_util.dart';
import 'package:fehviewer/utils/logger.dart';
import 'package:fehviewer/const/theme_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'gallery_clipper.dart';
import 'gallery_item.dart';

const double kRadius = 6.0;
const double kWidth = 28.0;
const double kHeight = 18.0;

class GalleryItemFlow extends StatelessWidget {
  GalleryItemFlow({Key key, @required this.tabIndex, this.galleryItem})
      : _galleryItemController = Get.put(
            GalleryItemController.initData(galleryItem, tabIndex: tabIndex),
            tag: galleryItem.gid),
        super(key: key);

  final String tabIndex;
  final GalleryItem galleryItem;
  final GalleryItemController _galleryItemController;

  @override
  Widget build(BuildContext context) {
    final Widget item = LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      final GalleryItem galleryItem = _galleryItemController.galleryItem;

      final Color _colorCategory = CupertinoDynamicColor.resolve(
          ThemeColors.catColor[galleryItem?.category ?? 'default'] ??
              CupertinoColors.systemBackground,
          context);

      // 获取图片高度
      num _getHeigth() {
        if (galleryItem.imgWidth >= constraints.maxWidth) {
          return galleryItem.imgHeight *
              constraints.maxWidth /
              galleryItem.imgWidth;
        } else {
          return galleryItem.imgHeight;
        }
      }

      final Widget container = Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Hero(
              tag: '${galleryItem.gid}_${galleryItem.token}_cover_$tabIndex',
              child: Container(
                decoration: BoxDecoration(
                    // borderRadius: BorderRadius.circular(kRadius), //圆角
                    // ignore: prefer_const_literals_to_create_immutables
                    boxShadow: [
                      //阴影
                      BoxShadow(
                        color: CupertinoDynamicColor.resolve(
                            CupertinoColors.systemGrey6, context),
                        blurRadius: 5,
                      )
                    ]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(kRadius),
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: <Widget>[
                      Container(
                        alignment: Alignment.center,
                        height:
                            galleryItem.imgWidth != null ? _getHeigth() : null,
                        child: CoverImg(imgUrl: galleryItem.imgUrl),
                      ),
                      ClipPath(
                        clipper:
                            CategoryClipper(width: kWidth, height: kHeight),
                        child: Container(
                          width: kWidth,
                          height: kHeight,
                          color: _colorCategory,
                        ),
                      ),
                      Container(
                        height: (kHeight + kRadius) / 2,
                        width: (kWidth + kRadius) / 2,
                        alignment: Alignment.center,
                        child: Text(
                          galleryItem?.translated ?? '',
                          style: const TextStyle(
                              fontSize: 8,
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.bold,
                              height: 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        child: container,
        onTap: () {
          logger.v(galleryItem.englishTitle);
          NavigatorUtil.goGalleryPage(
              galleryItem: galleryItem, tabIndex: tabIndex);
        },
      );
    });

    return item;
  }
}
