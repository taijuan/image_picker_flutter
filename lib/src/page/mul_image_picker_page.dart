import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker_flutter/src/image/asset_data_image.dart';
import 'package:image_picker_flutter/src/image_picker.dart';
import 'package:image_picker_flutter/src/model/asset_data.dart';
import 'package:image_picker_flutter/src/page/ui/dialog_loading.dart';
import 'package:image_picker_flutter/src/page/ui/drop_header_popup.dart';
import 'package:image_picker_flutter/src/page/ui/image_picker_app_bar.dart';
import 'package:image_picker_flutter/src/utils.dart';

class MulImagePickerPage extends StatefulWidget {
  final int limit;
  final List<AssetData> selectedData;
  final ImagePickerType type;
  final Widget back, menu;
  final Decoration decoration;
  final Color appBarColor;
  final Language language;
  final ImageProvider placeholder;
  final Widget emptyView;

  const MulImagePickerPage({
    Key key,
    this.limit = 9,
    this.selectedData,
    this.type = ImagePickerType.imageAndVideo,
    this.back,
    this.menu,
    this.decoration,
    this.appBarColor = Colors.blue,
    this.language,
    this.placeholder,
    this.emptyView,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return MulImagePickerPageState();
  }
}

class MulImagePickerPageState extends State<MulImagePickerPage> {
  final List<AssetData> selectedData = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<AssetData> data = [];
  bool isFirst = true;

  @override
  void dispose() {
    Utils.cancelAll();
    super.dispose();
  }

  @override
  void initState() {
    if (widget.selectedData != null) {
      selectedData.addAll(widget.selectedData);
    }
    Utils.log("initState");
    super.initState();
  }

  void getData(String folder) {
    Utils.getImages(folder)
      ..then((data) {
        this.data.clear();
        this.data.addAll(data);
        this.isFirst = false;
      })
      ..whenComplete(() {
        if (mounted) {
          setState(() {});
          Utils.log("whenComplete");
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: ImagePickerAppBar(
        context: context,
        center: DropHeader(
          type: widget.type,
          onSelect: (item) {
            getData(item);
          },
        ),
        language: widget.language,
        back: widget.back ??
            Icon(
              Utils.back,
              color: Colors.white,
            ),
        onBackCallback: () {
          Navigator.of(context).pop();
        },
        menu: widget.menu ??
            Icon(
              Utils.save,
              color: Colors.white,
            ),
        onSaveCallback: () {
          LoadingDialog.showLoadingDialog(context);
          Utils.convertMulData(selectedData).whenComplete(() {
            Navigator.of(context)..pop()..pop(selectedData);
          });
        },
        decoration: widget.decoration,
        appBarColor: widget.appBarColor,
      ),
      body: body(),
    );
  }

  Widget body() {
    if (isFirst) {
      return Center(
        child: CircularProgressIndicator(),
      );
    } else if (data.isEmpty) {
      return Center(child: widget.emptyView ?? Text(widget.language.empty));
    } else {
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (context, index) => _createItem(data[index]),
        itemCount: data.length,
        padding: EdgeInsets.fromLTRB(
          8,
          8,
          8,
          8 + MediaQuery.of(context).padding.bottom,
        ),
      );
    }
  }

  Widget _createItem(AssetData data) {
    return Stack(
      alignment: AlignmentDirectional.bottomEnd,
      children: <Widget>[
        FadeInImage(
          placeholder: widget.placeholder ?? Utils.placeholder,
          image: AssetDataImage(
            data,
            targetWidth: Utils.width2px(context, ratio: 3),
            targetHeight: Utils.width2px(context, ratio: 3),
          ),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
        RawMaterialButton(
          fillColor:
              selectedData.contains(data) ? Colors.white54 : Colors.transparent,
          constraints: BoxConstraints.expand(),
          highlightElevation: 0,
          elevation: 0,
          disabledElevation: 0,
          shape: CircleBorder(
            side: BorderSide(
              color: selectedData.contains(data)
                  ? widget.appBarColor ?? Colors.blue
                  : Colors.transparent,
              width: 4,
            ),
          ),
          onPressed: () {
            if (selectedData.contains(data)) {
              setState(() {
                selectedData.removeWhere((a) {
                  return a == data;
                });
              });
            } else {
              if (selectedData.length < widget.limit) {
                setState(() {
                  selectedData
                    ..removeWhere((a) {
                      return a == data;
                    })
                    ..add(data);
                });
              } else {
                _scaffoldKey.currentState.showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.language.showToast.replaceAll(
                        "###",
                        "${widget.limit}",
                      ),
                    ),
                  ),
                );
              }
            }
          },
          child: Text(
            showNumberText(data),
            style: TextStyle(
              fontSize: 48,
              color: widget.appBarColor ?? Colors.blue,
            ),
          ),
        ),
        iconVideo(data),
      ],
    );
  }

  Widget iconVideo(AssetData data) {
    if (data.isImage) {
      return Container(
        width: 0,
        height: 0,
      );
    }
    return Icon(
      Utils.video,
      color: widget.appBarColor ?? Colors.blue,
    );
  }

  showNumberText(AssetData data) {
    int num = selectedData.indexOf(data) + 1;
    if (num == 0) {
      return "";
    } else {
      return "$num";
    }
  }
}
