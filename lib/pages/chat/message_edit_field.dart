import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_emoji_keyboard/flutter_emoji_keyboard.dart';
import 'package:twake/utils/extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:twake/blocs/file_upload_bloc/file_upload_bloc.dart';
import 'package:twake/blocs/mentions_cubit/mentions_cubit.dart';

// const _categoryHeaderHeight = 40.0;
// const _categoryTitleHeight = _categoryHeaderHeight; // to

class MessageEditField extends StatefulWidget {
  final bool autofocus;
  final Function(String, BuildContext) onMessageSend;
  final Function(String, BuildContext) onTextUpdated;
  final String initialText;

  MessageEditField({
    @required this.onMessageSend,
    @required this.onTextUpdated,
    this.autofocus = false,
    this.initialText = '',
  });

  @override
  _MessageEditField createState() => _MessageEditField();
}

class _MessageEditField extends State<MessageEditField> {
  final _userMentionRegex = RegExp(r'(^|\s)@[A-Za-z1-9_-]+$');
  bool _emojiVisible = false;
  bool _mentionsVisible = false;
  bool _forceLooseFocus = false;
  bool _canSend = false;
  int _fileNumber = 0;

  final _focusNode = FocusNode();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  List<PlatformFile> _paths;
  String _extension;
  FileType _pickingType = FileType.any;

  @override
  void initState() {
    super.initState();

    widget.onTextUpdated(widget.initialText, context);
    if (widget.initialText.isNotReallyEmpty) {
      _controller.text = widget.initialText; // possibly retrieved from cache.
      setState(() {
        _canSend = true;
      });
    }

    _focusNode.addListener(() {
      if (_focusNode.hasPrimaryFocus)
        setState(() {
          _emojiVisible = false;
        });
    });

    _controller.addListener(() {
      var text = _controller.text;
      if (_userMentionRegex.hasMatch(text)) {
        BlocProvider.of<MentionsCubit>(context).fetchMentionableUsers(
          searchTerm: text.split('@').last.trimRight(),
        );
        Future.delayed(const Duration(milliseconds: 100), () {
          mentionsVisible();
        });
      }
      // Update for cache handlers
      widget.onTextUpdated(text, context);
      // Sendability  validation
      if (text.isReallyEmpty && _canSend) {
        setState(() {
          _canSend = false;
        });
      } else if (text.isNotReallyEmpty && !_canSend) {
        setState(() {
          _canSend = true;
        });
      }
    });
  }

  void mentionsVisible() async {
    final mentionsState = BlocProvider.of<MentionsCubit>(context).state;
    if (mentionsState is MentionableUsersLoaded) {
      setState(() {
        _mentionsVisible = true;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MessageEditField oldWidget) {
    if (oldWidget.initialText != widget.initialText) {
      _controller.text = widget.initialText;
    }
    // print('FORCE LOOSE FOCUS: $_forceLooseFocus');
    if (widget.autofocus && !_forceLooseFocus) {
      _focusNode.requestFocus();
    }
    super.didUpdateWidget(oldWidget);
  }

  void toggleEmojiBoard() async {
    if (_focusNode.hasPrimaryFocus) {
      _focusNode.unfocus();
      _forceLooseFocus = true;
    }
    await Future.delayed(Duration(milliseconds: 150));
    setState(() {
      _emojiVisible = !_emojiVisible;
    });
    if (!_emojiVisible) {
      _forceLooseFocus = false;
      _focusNode.requestFocus();
    }
  }

  void mentionReplace(String username) async {
    final text = _controller.text;
    _controller.text = text.replaceRange(
      text.lastIndexOf('@'),
      text.length,
      '@$username ',
    );
    _controller.selection = TextSelection.fromPosition(
      TextPosition(
        offset: _controller.text.length,
      ),
    );
  }

  Future<bool> onBackPress() async {
    if (_emojiVisible) {
      setState(() {
        _emojiVisible = false;
      });
    } else {
      Navigator.pop(context);
    }

    return false;
  }

  void _openFileExplorer() async {
    try {
      _paths = (await FilePicker.platform.pickFiles(
        type: _pickingType,
        allowMultiple: true,
        allowedExtensions: (_extension?.isNotEmpty ?? false)
            ? _extension.replaceAll(' ', '').split(',')
            : null,
      ))
          ?.files;
    } on PlatformException catch (e) {
      print("Unsupported operation" + e.toString());
    } catch (ex) {
      print(ex);
    }
    if (!mounted) return;
    //final path = _paths.map((e) => e.path).toList()[0].toString();
    // final name = _paths.map((e) => e.name).toList()[0].toString();
    //if possible to send the list of paths
    //listPath when will it be possible to send the sheet
    // final List<String> listPath = [];
    // _paths.forEach((element) {
    //   listPath.add(element.path.toString());
    //  });

    _paths.forEach((element) {
      BlocProvider.of<FileUploadBloc>(context)
          .add(StartUpload(path: element.path));
    });

    setState(() {
      _fileNumber += _paths.length;
    });

    BlocProvider.of<FileUploadBloc>(context).listen((FileUploadState state) {
      if (state is FileUploaded) {
        setState(() {
          _canSend = true;
        });
      }
    });
  }

  void _fileNumClear() async {
    _fileNumber = 0;
    _paths = [];
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onBackPress,
      child: Column(
        children: [
          _mentionsVisible
              ? BlocBuilder<MentionsCubit, MentionState>(
                  builder: (context, state) {
                    if (state is MentionableUsersLoaded) {
                      final List<Widget> _listW = [];
                      _listW.add(Divider(thickness: 1));
                      for (int i = 0; i < state.users.length; i++) {
                        _listW.add(
                          InkWell(
                            child: Container(
                              alignment: Alignment.center,
                              height: 40,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  SizedBox(width: 15),
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(30)),
                                    child: CircleAvatar(
                                      child: Image.network(
                                        state.users[i].thumbnail,
                                        fit: BoxFit.contain,
                                        loadingBuilder:
                                            (context, child, progres) {
                                          return progres == null
                                              ? child
                                              : CircleAvatar(
                                                  child: Icon(Icons.person,
                                                      color: Colors.grey),
                                                  backgroundColor:
                                                      Colors.blue[50],
                                                );
                                        },
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 15,
                                  ),
                                  Text(
                                    '${state.users[i].firstName} ',
                                    style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w300),
                                  ),
                                  Text(
                                    ' ${state.users[i].lastName}',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                    ),
                                  ),
                                  Expanded(child: SizedBox()),
                                  Icon(
                                    Icons.message_rounded,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(width: 15),
                                ],
                              ),
                            ),
                            onTap: () {
                              BlocProvider.of<MentionsCubit>(context)
                                  .clearMentions();
                              mentionReplace(state.users[i].username);
                              setState(
                                () {
                                  _mentionsVisible = false;
                                },
                              );
                            },
                          ),
                        );
                        if (i < state.users.length - 1) {
                          _listW.add(Divider(thickness: 1));
                        }
                      }
                      return ConstrainedBox(
                        constraints: BoxConstraints(
                            maxHeight:
                                MediaQuery.of(context).size.height * 0.3),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: _listW,
                          ),
                        ),
                      );
                    } else if (state is MentionsEmpty) {
                      return Container();
                      //Text("Empty");
                    }
                    return Container();
                  },
                )
              : Container(),
          TextInput(
            controller: _controller,
            scrollController: _scrollController,
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            toggleEmojiBoard: toggleEmojiBoard,
            emojiVisible: _emojiVisible,
            onMessageSend: widget.onMessageSend,
            canSend: _canSend,
            openFileExplorer: _openFileExplorer,
            fileNumber: _fileNumber,
            fileNumClear: _fileNumClear,
          ),
          if (_emojiVisible)
            EmojiKeyboard(
              onEmojiSelected: (emoji) {
                _controller.text += emoji.text;
                _scrollController
                    .jumpTo(_scrollController.position.maxScrollExtent);
              },
              height: MediaQuery.of(context).size.height * 0.35,
            ),
        ],
      ),
    );
  }
}

class TextInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final Function toggleEmojiBoard;
  final bool autofocus;
  final bool emojiVisible;
  final bool canSend;
  final Function onMessageSend;
  final Function openFileExplorer;
  final Function fileNumClear;
  int fileNumber;

  TextInput(
      {this.onMessageSend,
      this.controller,
      this.focusNode,
      this.autofocus,
      this.emojiVisible,
      this.scrollController,
      this.toggleEmojiBoard,
      this.openFileExplorer,
      this.canSend,
      this.fileNumber,
      this.fileNumClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300], width: 1.5)),
      ),
      child: Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(emojiVisible ? Icons.keyboard : Icons.tag_faces),
            onPressed: toggleEmojiBoard,
            color: Colors.black54,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: TextField(
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w400,
                  color: Color(0xff444444),
                ),
                cursorHeight: 20,
                maxLines: 4,
                minLines: 1,
                autofocus: autofocus,
                focusNode: focusNode,
                scrollController: scrollController,
                controller: controller,
                decoration: InputDecoration.collapsed(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: Colors.blueGrey),
                ),
              ),
            ),
          ),
          BlocBuilder<FileUploadBloc, FileUploadState>(
            builder: (context, state) {
              if (state is NothingToUpload) {
                return CircleAvatar(
                  backgroundColor: Colors.indigo[50],
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.attachment),
                    onPressed: openFileExplorer,
                    color: Colors.black54,
                  ),
                );
              } else if (state is FileUploading) {
                return CircularProgressIndicator();
              } else if (state is FileUploaded) {
                return InkWell(
                  child: CircleAvatar(
                    child: (Text('$fileNumber')),
                    //  await fileNumClear;
                    backgroundColor: Colors.indigo[50],
                  ),
                  onTap: openFileExplorer,
                );
              }
              return CircleAvatar(
                backgroundColor: Colors.indigo[50],
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.attachment),
                  onPressed: openFileExplorer,
                  color: Colors.black54,
                ),
              );
            },
          ),
          IconButton(
            padding: EdgeInsets.only(bottom: 5.0),
            icon: Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationZ(-3 / 4), // rotate 45ish degree cc
              child: Icon(
                canSend ? Icons.send : Icons.send_outlined,
                color:
                    canSend ? Theme.of(context).accentColor : Colors.grey[400],
              ),
            ),
            onPressed: canSend
                ? () async {
                    await onMessageSend(controller.text, context);
                    controller.clear();
                    fileNumClear();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
