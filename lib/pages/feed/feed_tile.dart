import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:twake/blocs/draft_bloc/draft_bloc.dart';
import 'package:twake/blocs/profile_bloc/profile_bloc.dart';
import 'package:twake/config/dimensions_config.dart';
import 'package:twake/repositories/draft_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:twake/utils/dateformatter.dart';
import 'package:twake/utils/navigation.dart';
import 'package:twake/widgets/common/channel_title.dart';
import 'package:twake/widgets/common/text_avatar.dart';

class FeedTile extends StatelessWidget {
  final String id;
  final String name;
  final String icon;
  final bool hasUnread;
  final bool isPrivate;
  final int lastActivity;
  final int messagesUnread;
  final Map<String, dynamic> lastMessage;

  const FeedTile({
    Key key,
    this.id,
    this.name,
    this.icon,
    this.hasUnread,
    this.isPrivate,
    this.lastActivity,
    this.messagesUnread,
    this.lastMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        var draftType = DraftType.channel;
        // Load draft from local storage
        context.read<DraftBloc>().add(LoadDraft(id: id, type: draftType));
        openChannel(context, id);
      },
      child: SizedBox(
        height: 62.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // SizedBox(width: 12),
            TextAvatar(icon),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ChannelTitle(
                          name: name,
                          hasUnread: hasUnread,
                          isPrivate: isPrivate,
                        ),
                      ),
                      Text(
                        DateFormatter.getVerboseDateTime(lastActivity),
                        style: Theme.of(context).textTheme.subtitle2,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text(
                          lastMessage['text'] ?? 'No messages yet',
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w400,
                            color: Color(0xff444444),
                          ),
                        ),
                      ),
                      Spacer(),
                      if (messagesUnread != 0) SizedBox(width: Dim.wm2),
                      // if (channel.messagesUnread != 0)
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (_, curr) => curr is ProfileLoaded,
                        builder: (ctx, state) {
                          final count = (state as ProfileLoaded)
                              .getBadgeForChannel(id);
                          if (count > 0) {
                            return Badge(
                              shape: BadgeShape.square,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5)),
                              padding: EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              badgeContent: Text(
                                '$count',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: Dim.tm2(),
                                ),
                              ),
                            );
                          } else {
                            return Container();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}