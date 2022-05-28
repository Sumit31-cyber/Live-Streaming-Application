import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:twitch_clone/models/user.dart';
import 'package:twitch_clone/providers/user_provider.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:twitch_clone/resources/firestore_methods.dart';
import 'package:twitch_clone/screens/home_screen.dart';

import '../config/appId.dart';
import '../widgets/chat.dart';

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen(
      {Key? key, required this.isBroadcaster, required this.channelId})
      : super(key: key);
  final bool isBroadcaster;
  final String channelId;
  static const routeName = '/broadcast';

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  late final RtcEngine _engine;
  List<int> remoteUid = [];
  bool switchCamera = true;
  bool isMuted = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initEngine();
  }

  void _initEngine() async {
    _engine = await RtcEngine.createWithContext(RtcEngineContext(appId));
    _addlistners();

    await _engine.enableVideo();
    await _engine.startPreview();
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    if (widget.isBroadcaster) {
      await _engine.setClientRole(ClientRole.Broadcaster);
    } else {
      await _engine.setClientRole(ClientRole.Audience);
    }
    _joinChannel();
  }

  void _addlistners() {
    _engine.setEventHandler(
        RtcEngineEventHandler(joinChannelSuccess: (channel, uid, elapsed) {
      debugPrint('joinChannelSuccess: $channel, $uid, $elapsed');
    }, userJoined: (uid, elapsed) {
      debugPrint('userJoined: $uid, $elapsed');
      setState(() {
        remoteUid.add(uid);
      });
    }, userOffline: (uid, reason) {
      debugPrint('userOffline: $uid, $reason');
      setState(() {
        remoteUid.removeWhere((element) => element == uid);
      });
    }, leaveChannel: (stats) {
      debugPrint('leaveChannel: $stats');
      setState(() {
        remoteUid.clear();
      });
    }));
  }

  void _joinChannel() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await [Permission.microphone, Permission.camera].request();
    }
    await _engine.joinChannelWithUserAccount(tempToken, 'testing123',
        Provider.of<UserProvider>(context, listen: false).user.uid);
  }

  void _switchCamera() {
    _engine
        .switchCamera()
        .then(
          (value) => setState(
            () {
              switchCamera = !switchCamera;
            },
          ),
        )
        .catchError((err) => {debugPrint(err)});
  }

  void _onToggleMute() {
    setState(() {
      isMuted = !isMuted;
    });
    _engine.muteLocalAudioStream(isMuted);
  }

  _leavChannel() async {
    await _engine.leaveChannel();
    if ('${Provider.of<UserProvider>(context, listen: false).user.uid}${Provider.of<UserProvider>(context, listen: false).user.username}' ==
        widget.channelId) {
      await FirestoreMethods().endLiveStream(widget.channelId);
    } else {
      await FirestoreMethods().updatedViewCount(widget.channelId, false);
    }
    Navigator.pushReplacementNamed(context, HomeScreen.routeName);
  }

  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    return WillPopScope(
      onWillPop: () async {
        await _leavChannel();
        return Future.value(true);
      },
      child: Scaffold(
        body: Padding(
            padding: const EdgeInsets.all(9),
            child: Column(
              children: [
                _renderVideo(user),
                if ('${user.uid}${user.username}' == widget.channelId)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: _switchCamera,
                        child: Text('Switch Camera'),
                      ),
                      InkWell(
                        onTap: _onToggleMute,
                        child: isMuted ? Text('UnMute') : Text('Mute'),
                      )
                    ],
                  ),
                Expanded(
                    child: Chat(
                  channelId: widget.channelId,
                ))
              ],
            )),
      ),
    );
  }

  _renderVideo(user) {
    return AspectRatio(
        aspectRatio: 16 / 9,
        child: "${user.uid}${user.username}" == widget.channelId
            ? const RtcLocalView.SurfaceView(
                zOrderMediaOverlay: true,
                zOrderOnTop: true,
              )
            : remoteUid.isNotEmpty
                ? kIsWeb
                    ? RtcRemoteView.SurfaceView(
                        uid: remoteUid[0],
                        channelId: widget.channelId,
                      )
                    : RtcRemoteView.TextureView(
                        uid: remoteUid[0],
                        channelId: widget.channelId,
                      )
                : Container(
                    color: Colors.black,
                  ));
  }
}
