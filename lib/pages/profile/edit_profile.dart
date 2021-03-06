import 'dart:io';
import 'dart:isolate';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:twake/blocs/account_cubit/account_cubit.dart';
import 'package:twake/blocs/sheet_bloc/sheet_bloc.dart';
import 'package:twake/widgets/common/button_field.dart';
import 'package:twake/widgets/common/rounded_image.dart';
import 'package:twake/widgets/common/rounded_shimmer.dart';
import 'package:twake/widgets/common/selectable_avatar.dart';
import 'package:twake/widgets/common/rounded_text_field.dart';
import 'package:twake/widgets/common/switch_field.dart';
import 'package:twake/utils/extensions.dart';
import 'package:twake/utils/image_processor.dart';

class EditProfile extends StatefulWidget {
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _userNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  var _canSave = true;
  var _picture = '';

  String _fileName;

  @override
  void initState() {
    super.initState();
    _userNameController.text = '';
    _firstNameController.text = '';
    _lastNameController.text = '';
    _oldPasswordController.text = '';
    _newPasswordController.text = '';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _save() {
    print('Save profile!');
    final firstName = _firstNameController.text;
    final lastName = _lastNameController.text;
    context.read<AccountCubit>().updateInfo(
      firstName: firstName,
      lastName: lastName,
    );
    FocusScope.of(context).requestFocus(FocusNode());
    context.read<SheetBloc>().add(CloseSheet());
    context.read<AccountCubit>().updateAccountFlowStage(AccountFlowStage.info);
  }

  Future<void> _openFileExplorer() async {
    List<PlatformFile> paths;
    try {
      paths = (await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
        withReadStream: true,
      ))
          ?.files;

      if (paths != null && paths.length > 0) {
        final path = paths[0].path;
        print('Source path: $path');
        print('Source size: ${paths[0].size}');

        final file = File(path);
        final processed = await processFile(file);
        // print('Processed file bytes: ${processed.path}');
        // print('Processed file size: ${processed.lengthSync()}');

        // final platformFile = PlatformFile(path: processed.path, bytes: processed.readAsBytesSync(), size: processed.lengthSync());
        // Image processor

        // _fileName = paths[0].path;
        // print('Filename to be saved: $_fileName');
        // context.read<AccountCubit>().updateImage(context, processed.path);
      }
    } on PlatformException catch (e) {
      print("Unsupported operation" + e.toString());
    } catch (ex) {
      print(ex);
    }
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountCubit, AccountState>(
      builder: (context, state) {
        final _isUpdating = state is AccountSaving;

        if (state is AccountLoaded ||
            state is AccountSaved ||
            state is AccountInitial) {
          _userNameController.text = '@${state.userName}';
          _firstNameController.text = state.firstName;
          _lastNameController.text = state.lastName;
          _picture = state.picture;
        }

        return GestureDetector(
          onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 56.0,
                  child: OverflowBox(
                    maxWidth: MediaQuery.of(context).size.width,
                    maxHeight: 56.0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 0.0),
                      color: Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              context
                                  .read<AccountCubit>()
                                  .updateAccountFlowStage(
                                  AccountFlowStage.info);
                              FocusScope.of(context).requestFocus(FocusNode());
                            },
                            child: Icon(
                              Icons.arrow_back_ios,
                              color: Color(0xff3840f7),
                            ),
                          ),
                          // SizedBox(width: 24.0),
                          GestureDetector(
                            onTap: _canSave ? () => _save() : null,
                            child: Text(
                              'Save',
                              style: TextStyle(
                                color: _canSave
                                    ? Color(0xff3840f7)
                                    : Color(0xffa2a2a2),
                                fontSize: 17.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 25.0),
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _isUpdating
                              ? RoundedShimmer(size: 100.0)
                              : SelectableAvatar(
                            size: 100.0,
                            userpic: _picture,
                            onTap: () => _openFileExplorer(),
                          ),
                          SizedBox(height: 12.0),
                          GestureDetector(
                            onTap: () => _openFileExplorer(),
                            child: Text(
                              'Tap to upload',
                              style: TextStyle(
                                color: Color(0xff3840f7),
                                fontSize: 13.0,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 36.0),
                    RoundedTextField(
                      controller: _userNameController,
                      prefix: 'Username',
                      hint: 'Not assigned',
                      borderRadius: BorderRadius.circular(10.0),
                      enabled: false,
                    ),
                    SizedBox(height: 43.0),
                    Text(
                      'NAME',
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withOpacity(0.35),
                      ),
                    ),
                    SizedBox(height: 12.0),
                    RoundedTextField(
                      controller: _firstNameController,
                      prefix: 'First name',
                      hint: 'Not assigned',
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10.0),
                        topRight: Radius.circular(10.0),
                      ),
                    ),
                    Divider(
                      height: 1.0,
                      color: Colors.black.withOpacity(0.1),
                    ),
                    RoundedTextField(
                      controller: _lastNameController,
                      prefix: 'Last name',
                      hint: 'Not assigned',
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(10.0),
                        bottomRight: Radius.circular(10.0),
                      ),
                    ),
                    // SizedBox(height: 8.0),
                    // Text(
                    //   '«Displayed name» is how people see your name in Twake\nin @mentions and by other users in channels and private chats',
                    //   style: TextStyle(
                    //     fontSize: 11.0,
                    //     fontWeight: FontWeight.w400,
                    //     color: Colors.black.withOpacity(0.35),
                    //   ),
                    // ),
                    SizedBox(height: 43.0),
                    Text(
                      'CHANGE PASSWORD',
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withOpacity(0.35),
                      ),
                    ),
                    SizedBox(height: 12.0),
                    RoundedTextField(
                      controller: _oldPasswordController,
                      prefix: 'Old',
                      hint: '',
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10.0),
                        topRight: Radius.circular(10.0),
                      ),
                    ),
                    Divider(
                      height: 1.0,
                      color: Colors.black.withOpacity(0.1),
                    ),
                    RoundedTextField(
                      controller: _newPasswordController,
                      prefix: 'New',
                      hint: '',
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(10.0),
                        bottomRight: Radius.circular(10.0),
                      ),
                    ),
                    // SizedBox(height: 24.0),
                    // Text(
                    //   'DATE & TIME',
                    //   style: TextStyle(
                    //     fontSize: 13.0,
                    //     fontWeight: FontWeight.w600,
                    //     color: Colors.black.withOpacity(0.35),
                    //   ),
                    // ),
                    // SizedBox(height: 12.0),
                    // ButtonField(
                    //   title: 'Time Zone',
                    //   titleStyle: TextStyle(
                    //     fontSize: 15.0,
                    //     fontWeight: FontWeight.w400,
                    //     color: Colors.black.withOpacity(0.4),
                    //   ),
                    //   trailingTitle: 'Paris',
                    //   trailingTitleStyle: TextStyle(
                    //     fontSize: 15.0,
                    //     fontWeight: FontWeight.w400,
                    //     color: Colors.black,
                    //   ),
                    //   hasArrow: true,
                    //   arrowColor: Color(0xff3c3c43).withOpacity(0.3),
                    //   borderRadius: BorderRadius.only(
                    //     topLeft: Radius.circular(10.0),
                    //     topRight: Radius.circular(10.0),
                    //   ),
                    //   onTap: () {
                    //     print('Tap on Time Zone');
                    //   },
                    // ),
                    // Divider(
                    //   height: 1.0,
                    //   color: Colors.black.withOpacity(0.1),
                    // ),
                    // SwitchField(
                    //   title: 'Set automatically',
                    //   titleStyle: TextStyle(
                    //     fontSize: 15.0,
                    //     fontWeight: FontWeight.w400,
                    //     color: Colors.black.withOpacity(0.4),
                    //   ),
                    //   value: true,
                    //   isExtended: true,
                    //   onChanged: (value) {},
                    //   borderRadius: BorderRadius.only(
                    //     bottomLeft: Radius.circular(10.0),
                    //     bottomRight: Radius.circular(10.0),
                    //   ),
                    // ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
