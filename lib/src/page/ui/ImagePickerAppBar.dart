import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker_flutter/src/ImagePicker.dart';

typedef OnBackCallback = Function();
typedef OnSaveCallback = Function();

class ImagePickerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final BuildContext context;
  final Widget title, back, menu;
  final OnBackCallback onBackCallback;
  final OnSaveCallback onSaveCallback;
  final Decoration decoration;
  final Color appBarColor;
  final Language language;

  const ImagePickerAppBar({
    Key key,
    @required this.context,
    @required this.title,
    this.back,
    this.menu,
    this.onBackCallback,
    this.onSaveCallback,
    this.decoration,
    this.language,
    this.appBarColor,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(
        48 + MediaQuery.of(context).padding.top,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48 + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: decoration ?? BoxDecoration(color: appBarColor),
      child: Stack(
        children: <Widget>[
          Center(
            child: title ??
                Text(
                  language.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: RawMaterialButton(
              onPressed: onBackCallback,
              child: back,
              highlightElevation: 0,
              elevation: 0,
              disabledElevation: 0,
              constraints: BoxConstraints(
                minWidth: 48,
                minHeight: 48,
                maxHeight: 48,
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: RawMaterialButton(
              onPressed: onSaveCallback,
              child: menu,
              highlightElevation: 0,
              elevation: 0,
              disabledElevation: 0,
              constraints: BoxConstraints(
                minWidth: 48,
                minHeight: 48,
                maxHeight: 48,
              ),
            ),
          )
        ],
      ),
    );
  }
}
