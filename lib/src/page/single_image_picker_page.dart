import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker_flutter/src/image/asset_data_image.dart';
import 'package:image_picker_flutter/src/image_picker.dart';
import 'package:image_picker_flutter/src/model/asset_data.dart';
import 'package:image_picker_flutter/src/page/ui/dialog_loading.dart';
import 'package:image_picker_flutter/src/page/ui/image_picker_app_bar.dart';
import 'package:image_picker_flutter/src/utils.dart';

class SingleImagePickerPage extends StatefulWidget {
  final ImagePickerType type;
  final Widget title, back;
  final Decoration decoration;
  final Language language;
  final ImageProvider placeholder;
  final Color appBarColor;
  final Widget emptyView;

  const SingleImagePickerPage({
    Key key,
    this.type = ImagePickerType.imageAndVideo,
    this.title,
    this.back,
    this.decoration,
    this.language,
    this.placeholder,
    this.appBarColor = Colors.blue,
    this.emptyView,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return SingleImagePickerPageState();
  }
}

class SingleImagePickerPageState extends State<SingleImagePickerPage> {
  final List<AssetData> data = [];
  bool isFirst = true;

  @override
  void dispose() {
    Utils.cancelAll();
    super.dispose();
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((d) => getData());
    super.initState();
  }

  void getData() {
    Utils.getImages(widget.type)
      ..then((data) {
        this.data.clear();
        this.data.addAll(data);
        this.isFirst = false;
      })
      ..whenComplete(() {
        if (mounted) {
          setState(() {});
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ImagePickerAppBar(
        context: context,
        title: widget.title,
        language: widget.language,
        back: widget.back ??
            Icon(
              Utils.back,
              color: Colors.white,
            ),
        onBackCallback: () {
          Navigator.of(context).pop();
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
          constraints: BoxConstraints.expand(),
          onPressed: () {
            LoadingDialog.showLoadingDialog(context);
            Utils.convertSingleData(data)
              ..whenComplete(() {
                Navigator.of(context)..pop()..pop(data);
              });
          },
          shape: CircleBorder(),
        ),
        iconVideo(data),
      ],
    );
  }

  Widget iconVideo(AssetData data) {
    if (data.isImage) {
      return SizedBox.shrink();
    }
    return Icon(
      Utils.video,
      color: widget.appBarColor ?? Colors.blue,
    );
  }
}
