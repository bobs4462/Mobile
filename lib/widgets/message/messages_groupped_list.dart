import 'package:flutter/material.dart';
import 'package:sticky_grouped_list/sticky_grouped_list.dart';
import 'package:twake_mobile/config/dimensions_config.dart' show Dim;
import 'package:twake_mobile/models/message.dart';
import 'package:twake_mobile/services/dateformatter.dart';
import 'package:twake_mobile/widgets/message/message_tile.dart';
import 'package:provider/provider.dart';
import 'package:twake_mobile/providers/messages_provider.dart';

class MessagesGrouppedList extends StatelessWidget {
  final List<Message> messages;

  MessagesGrouppedList(this.messages);
  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          Provider.of<MessagesProvider>(context, listen: false)
              .loadMoreMessages();
        }
        return true;
      },
      child: Expanded(
        // height: Dim.maxScreenHeight - // taking all available vertical space
        // Dim.heightPercent(
        // (kToolbarHeight * 0.19).round()) - // deducting toolbar height
        // Dim.heightPercent(11), // deducting height of text input for reply
        // padding: EdgeInsets.only(bottom: Dim.hm3),
        child: StickyGroupedListView<Message, DateTime>(
          reverse: true,
          elements: messages,
          // floatingHeader: true,
          order: StickyGroupedListOrder.ASC,
          groupBy: (Message m) {
            final DateTime dt =
                DateTime.fromMillisecondsSinceEpoch(m.creationDate * 1000);
            return DateTime(dt.year, dt.month, dt.day);
          },
          groupComparator: (DateTime value1, DateTime value2) =>
              value2.compareTo(value1),
          itemComparator: (Message m1, Message m2) {
            return m1.creationDate.compareTo(m2.creationDate);
          },
          // floatingHeader: true,
          separator: SizedBox(height: Dim.hm2),
          groupSeparatorBuilder: (Message message) {
            return Container(
              height: Dim.hm3,
              margin: EdgeInsets.symmetric(vertical: Dim.hm2),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Divider(
                      thickness: 0.0,
                      // color: Theme.of(context).accentColor,
                    ),
                  ),
                  Align(
                    // alignment: Alignment.center,
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: Dim.widthPercent(30),
                      // decoration: BoxDecoration(
                      // borderRadius: BorderRadius.circular(Dim.widthMultiplier),
                      // color: Theme.of(context).accentColor,
                      // border: Border.all(
                      // color: Theme.of(context).accentColor.withOpacity(0.5),
                      // ),
                      // ),
                      child: Padding(
                        padding: const EdgeInsets.all(1.0),
                        child: Text(
                          DateFormatter.getVerboseDate(message.creationDate),
                          style: Theme.of(context).textTheme.subtitle1,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          itemBuilder: (_, Message message) {
            return MessageTile(message);
          },
        ),
      ),
    );
  }
}
