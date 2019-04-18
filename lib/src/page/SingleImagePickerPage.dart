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
  final List<AssetData> _data = [];
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void dispose() {
    Utils.cancelAll();
    super.dispose();
  }

  @override
  void initState() {
    Future.delayed(Duration()).whenComplete(() {
      _refreshKey.currentState.show();
    });
    super.initState();
  }

  Future<Null> _getData() async {
    final List<AssetData> data = await Utils.getImages(widget.type);
    _data.clear();
    if (mounted) {
      setState(() {
        _data.addAll(data);
      });
    }
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
      body: RefreshIndicator(
        key: _refreshKey,
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) => _createItem(_data[index]),
          itemCount: _data.length,
          padding: EdgeInsets.fromLTRB(
            8,
            8,
            8,
            8 + MediaQuery.of(context).padding.bottom,
          ),
        ),
        onRefresh: _getData,
      ),
    );
  }

  Widget _createItem(AssetData data) {
    return Stack(
      alignment: AlignmentDirectional.bottomEnd,
      children: <Widget>[
        FadeInImage(
          placeholder: widget.placeholder ?? Utils.placeholder,
          image: AssetDataImage(data),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
        iconVideo(data),
        InkWell(
          onTap: () {
            Navigator.of(context).pop(data);
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
