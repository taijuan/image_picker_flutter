import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker_flutter/src/ImagePicker.dart';
import 'package:image_picker_flutter/src/image/AssetDataImage.dart';
import 'package:image_picker_flutter/src/model/AssetData.dart';
import 'package:image_picker_flutter/src/page/ui/ImagePickerAppBar.dart';
import 'package:image_picker_flutter/src/utils/Utils.dart';

class SingleImagePickerPage extends StatefulWidget {
  final ImagePickerType type;
  final Widget title, back;
  final Decoration decoration;
  final Language language;
  final ImageProvider placeholder;
  final Color appBarColor;

  const SingleImagePickerPage({
    Key key,
    this.type = ImagePickerType.imageAndVideo,
    this.title,
    this.back,
    this.decoration,
    this.language,
    this.placeholder,
    this.appBarColor = Colors.blue,
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
    getData();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if(isFirst){
      isFirst = false;
      getData();
    }
    super.didChangeDependencies();
  }
  void getData() {
    Utils.getImages(widget.type)
      ..then((data) {
        this.data.clear();
        this.data.addAll(data);
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
    if (data.isEmpty) {
      return Center(
        child: CircularProgressIndicator(),
      );
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
            width: Utils.width2px(context, ratio: 3),
            height: Utils.width2px(context, ratio: 3),
          ),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
        iconVideo(data),
        InkWell(
          onTap: () async {
            Navigator.of(context).pop(await Utils.convertSingleData(data));
          },
        )
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
}
