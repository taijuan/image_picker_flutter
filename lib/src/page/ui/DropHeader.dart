import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_flutter/image_picker_flutter.dart';

typedef OnSelected<T> = void Function(T value);

class DropHeader extends StatefulWidget {
  final ImagePickerType type;
  final Widget title;
  final OnSelected<String> onSelect;

  const DropHeader({Key key, this.type, this.title, this.onSelect})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return DropHeaderState();
  }
}

class DropHeaderState extends State<DropHeader> {
  List<String> _folders = [];
  String _folder = "";

  @override
  void initState() {
    WidgetsBinding.instance
        .addPostFrameCallback((d) => Utils.getFolders(widget.type)
          ..then((folders) {
            setState(() {
              _folders.clear();
              _folders.addAll(folders);
              _folder = _folders[0];
              widget.onSelect(_folder);
            });
          }));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 48),
      child: _folders.isEmpty
          ? SizedBox.shrink()
          : SizedBox.expand(
              child: FlatButton(
                onPressed: () {
                  _showDropPopup();
                },
                child: Text(
                  _folder.split("/").last,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
    );
  }

  void _showDropPopup() async {
    final RenderBox button = context.findRenderObject();
    final RenderBox overlay = Overlay.of(context).context.findRenderObject();
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomCenter(Offset(32,80)),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    await showMenu<String>(
            initialValue: _folder,
            context: context,
            position: position,
            shape: Border(),
            items: _folders.map((item) {
              return PopupMenuItem<String>(
                value: item,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 48 * 2,
                  height: 48,
                  child: Container(
                    alignment: AlignmentDirectional.center,
                    child: Text(
                      item.split("/").last,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ),
                ),
              );
            }).toList())
        .then((item) {
      if (item != null) {
        _folder = item;
        widget.onSelect(item);
      }
    });
  }
}
