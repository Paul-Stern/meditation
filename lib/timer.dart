import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' hide Priority;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:do_not_disturb/do_not_disturb.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:get_it/get_it.dart';
import 'package:meditation/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:meditation/audioplayer.dart';
import 'package:meditation/utils.dart';
import 'package:meditation/session.dart';
import 'package:meditation/db.dart';

enum TimerState { stopped, delaying, meditating }

const int endingNotificationID = 100;
const int startingNotificationID = 101;
// intervalNotification is also going to use up the next few numbers
// reserve 200-299 for it
const int intervalNotificationID = 200;

class NotificationController {
  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {}

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    log.i("notification displayed. id = ${receivedNotification.id}");
    eventBus.fire(NotificationEvent("displayed", receivedNotification.id));
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {}

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {}
}

class TimerWidget extends StatefulWidget {
  const TimerWidget({Key? key}) : super(key: key);

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> with SingleTickerProviderStateMixin {
  final List<int> intervalNotificationIDs = [];

  final dndPlugin = DoNotDisturbPlugin();

  late Ticker ticker;

  TimerState timerState = TimerState.stopped;
  int timerMinutes = 0;
  int timerDelaySeconds = 0;
  String timerButtonText = "begin";

  DateTime startTime = DateTime.now();
  DateTime endTime = DateTime.now();
  Duration timeLeft = const Duration(minutes: 0, seconds: 0);
  double timerProgress = 0.0;

  bool intervalsEnabled = false;
  Duration intervalTime = const Duration(minutes: 0);
  int intervalCount = 0;

  int sessionID = 0;
  DatabaseHelper db = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();

    ticker = createTicker(tickerUpdate);
    // timerDelayTicker = createTicker(timerDelayUpdate);

    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        timerMinutes = prefs.getInt('timer-minutes') ?? 0;
      });
    });

    // get db
    db = DatabaseHelper.instance;

    AwesomeNotifications().setListeners(
        onActionReceivedMethod: NotificationController.onActionReceivedMethod,
        onNotificationCreatedMethod: NotificationController.onNotificationCreatedMethod,
        onNotificationDisplayedMethod: NotificationController.onNotificationDisplayedMethod,
        onDismissActionReceivedMethod: NotificationController.onDismissActionReceivedMethod);

    eventBus.on<NotificationEvent>().listen((notificationEvent) {
      // All events are of type UserLoggedInEvent (or subtypes of it).
      log.d(
          "received notification event - type: ${notificationEvent.type}, id: ${notificationEvent.id}");
      actOnNotificationDisplayed(notificationEvent.id);
    });
  }

  @override
  void dispose() {
    AwesomeNotifications().cancelAll();
    ticker.dispose();

    super.dispose();
  }

  void actOnNotificationDisplayed(int? notificationID) {
    // on ios this doesn't seem to get called immediately
    // so if the app isn't in the foreground, onTimerEnd execution is delayed
    // this likely doesn't allow the sound to play on time
    // so you'd rather have to play it through the notification
    // or find another way of executing code when the app is not in the foreground

    if (notificationID == endingNotificationID) {
      if (timerState == TimerState.meditating) {
        log.i(
            "ending timer through displayedStream notification callback. timeleft: ${timeLeft.inMilliseconds} ms");
        onTimerEnd();
      }
    }
    if (intervalNotificationIDs.contains(notificationID)) {
      if (timerState == TimerState.meditating) {
        log.i("reached interval timer through displayedStream notification callback");
        onTimerInterval();
        Timer(const Duration(seconds: 0), () {
          log.i("dismissing interval notification");
          AwesomeNotifications().dismiss(notificationID!);
        });
      }
    }
    if (notificationID == startingNotificationID) {
      if (timerState == TimerState.delaying) {
        log.i("reached starting timer through displayedStream notification callback");
        onMeditationStart();
        Timer(const Duration(seconds: 4), () {
          log.i("dismissing start notification");
          AwesomeNotifications().dismiss(startingNotificationID);
        });
      }
    }
  }

  // this function only gets called if the screen is on
  void tickerUpdate(Duration elapsed) {
    if (timerState == TimerState.stopped) {
      return;
    }

    if (timerState == TimerState.delaying) {
      // delaying

      var countdown = timerDelaySeconds - elapsed.inSeconds;

      setState(() {
        timerButtonText = countdown.toString();
      });

      // if (elapsed.inSeconds > timerDelaySeconds - 1) {
      //   // done delaying
      //   onMeditationStart();
      // }
    }

    if (timerState == TimerState.meditating) {
      // meditating

      // backup system for ending the timer in case notification fails
      if (timeLeft.inMilliseconds <= 200) {
        // better for this to end a little early than too late
        // not sure how fast ticker is called but maybe 60fps? so 16.6 ms between calls
        // 200ms allows for ~12 frames leeway
        log.i("ending timer through timerUpdate");
        onTimerEnd();
        return;
      }

      var timeElapsed = DateTime.now().difference(startTime);

      // if (intervalsEnabled && intervalCount > 0) {
      //   if (timeLeft <= intervalTime * intervalCount) {
      //     intervalCount -= 1;
      //     onTimerInterval();
      //   }
      // }

      // invlerp: t = (v-a) / (b-a);
      int vma = timeElapsed.inMilliseconds;
      int bma = endTime.difference(startTime).inMilliseconds;
      double t = vma / bma;

      setState(() {
        timerProgress = t;
        timeLeft = timeLeftTo(endTime);
      });
    }
  }

  // returns true if permissions ok
  Future<bool> checkIfPermissionsOkay() async {
    var userAction = false;

    if (Settings.getValue<bool>('dnd') == true) {
      bool hasAccess = await dndPlugin.isNotificationPolicyAccessGranted();
      if (!hasAccess) {
        await requestPermissionDND(context, dndPlugin, suggestDisable: true);
        userAction = true;

        // return early to let user disable dnd if needed
        return !userAction;
      }
    }

    var backgroundPermissionOkay = await FlutterBackground.hasPermissions;
    if (!backgroundPermissionOkay) {
      await requestBatteryOptimization(context);
      userAction = true;

      backgroundPermissionOkay = await FlutterBackground.hasPermissions;
      if (!backgroundPermissionOkay) {
        // if the user hasn't enabled the permission, return early
        // because without batteryoptimization permissions we can't enable precisealarms notification
        return !userAction;
      }
    }

    // request app permissions. this should be enough
    var (requestedUserAction, allowedPermissions) =
        await requestNotificationPermissions(context, channelKey: null, permissionList: [
      // generic default permissions are alert, sound, vibration, light
      NotificationPermission.Alert,
      // we remove badge support
      // NotificationPermission.Badge,
      NotificationPermission.Sound,
      NotificationPermission.Vibration,
      NotificationPermission.Light,
      // extra permissions
      NotificationPermission.CriticalAlert,
      NotificationPermission.FullScreenIntent,
      // precise alarms requires disabling of battery optimization?
      NotificationPermission.PreciseAlarms,
      // NotificationPermission.OverrideDnD,
    ]);
    if (requestedUserAction) {
      userAction = true;
    }

    var channelHelper = ChannelHelper();

    bool isChannelEnabled = await channelHelper.isNotificationChannelEnabled("timer-main");
    log.d("is channel timer-main enabled: $isChannelEnabled");
    if (!isChannelEnabled) {
      userAction = true;
      await requestUserToEnableChannel(context, "timer-main");
    }

    isChannelEnabled = await channelHelper.isNotificationChannelEnabled("timer-support");
    log.d("is channel timer-support enabled: $isChannelEnabled");
    if (!isChannelEnabled) {
      userAction = true;
      await requestUserToEnableChannel(context, "timer-support");
    }

    // these checks are extra checks to see if for any reason any of the individual channels was disabled
    // these extra checks are to see if we can enable the requested permissions
    // note that in case of user tampering with permissions, these can't be restored at all
    // but these permissions seem to be aesthetic so it should not affect us much
    // we use the Light permission because we have to check at least one
    // and this is the least intrusive that we can enable
    // but if only checking Light to check for channel activation, then the above checks are enough
    (requestedUserAction, allowedPermissions) = await requestNotificationPermissions(context,
        channelKey: "timer-main",
        permissionList: [NotificationPermission.Alert, NotificationPermission.Light]);
    if (requestedUserAction) {
      userAction = true;
    }

    // testing for Light is a way of simply testing whether the notification is enabled or not
    // vibration and sound won't work on testing for a min importance notification channel
    (requestedUserAction, allowedPermissions) = await requestNotificationPermissions(context,
        channelKey: "timer-support", permissionList: [NotificationPermission.Light]);
    if (requestedUserAction) {
      userAction = true;
    }

    // if we asked user for stuff, consider the check to have failed, letting user press start again
    return !userAction;
  }

  void onTimerButtonPress() async {
    if (timerState == TimerState.stopped) {
      // start pressed
      var permissionsOkay = await checkIfPermissionsOkay();

      if (permissionsOkay) {
        // all permissions are good. start!
        onTimerStart();
      } else {
        // user was prompted. let them press start button again
        return;
      }
    } else {
      // stop pressed
      if (timerDelaySeconds == 0 && DateTime.now().difference(startTime).inMilliseconds < 500) {
        // prevent accidental double tap
        // but not if coming from the delayed start
        return;
      }
      // AwesomeNotifications().cancelSchedule(endingNotificationID);
      AwesomeNotifications().cancel(endingNotificationID);
      AwesomeNotifications().cancel(intervalNotificationID);
      // onTimerEnd(playAudio: true);
      if (kReleaseMode) {
        onTimerEnd(playAudio: false);
      } else {
        onTimerEnd(playAudio: true);
      }
    }
  }

  void onTimerInterval() async {
    if (timerState != TimerState.meditating) {
      log.e("onTimerInterval called after meditation finished");
      return;
    }

    log.d("playing interval sound at $timeLeft");

    NAudioPlayer audioPlayer = GetIt.I.get<NAudioPlayer>();
    audioPlayer.playSound('interval-sound');
  }

  // this happens on either start or delay
  void onTimerStart() async {
    // cleaning up endingnotification in case it's still around
    // 10s timer for dismissal at onTimerEnd will still call and presumably do nothing
    // probably no need to fix that
    AwesomeNotifications().dismiss(endingNotificationID);

    await initFlutterBackground();
    if (Platform.isAndroid) {
      bool backgroundSuccess = await FlutterBackground.enableBackgroundExecution();
      log.i('enable background success: $backgroundSuccess');
    }

    if (Settings.getValue<bool>('dnd') == true) {
      log.i('enabling dnd');
      // we already checked permissions
      await dndPlugin.setInterruptionFilter(InterruptionFilter.alarms);
    }

    if (Settings.getValue<bool>('delay-enabled') ?? false) {
      timerDelaySeconds = int.parse(Settings.getValue<String>('delay-time') ?? '5');
      // unconditionally force screen wakelock for the delay part
      // this won't prevent manual turn off of display, but will save us from a short screen-off time
      // for the meditation part, wakelock can be user-set
      WakelockPlus.enable();
      // cannot send notifications at intervals <5
      // what happens with less than 5 seconds is unclear, so we prevent that
      await scheduleStartingNotification(timerDelaySeconds);
      // start delay
      timerState = TimerState.delaying;
      // onMeditationStart() will be called at the end of the elapsed time
    } else {
      // start meditation
      onMeditationStart();
    }

    ticker.start();
  }

  // pretty much just the visual/aural part and the switch of state
  void onMeditationStart() async {
    var timerDuration = Duration(minutes: timerMinutes);
    if (timerMinutes == 0) {
      // this is the test mode
      timerDuration += Duration(seconds: 10);
    }

    startTime = DateTime.now();
    endTime = startTime.add(timerDuration);

    // initial calculation. must happen before we start the ticker
    // we need to calculate timeleft before switching to meditating state
    // otherwise the first tickerupdate could run with the wrong timeleft
    timeLeft = timeLeftTo(endTime);

    bool wakelockEnabled = await WakelockPlus.enabled;
    if (Settings.getValue<bool>('screen-wakelock') == true) {
      if (wakelockEnabled) {
        // wakelock was already setup in onTimerStart
        log.i('maintaining screen wakelock for meditation');
      } else {
        log.e('wakelock is not enabled but was supposed to be');
      }
    } else {
      if (wakelockEnabled) {
        log.i('disabling screen wakelock for meditation');
        WakelockPlus.disable();
      }
    }

    // start the meditation

    timerState = TimerState.meditating;
    setState(() {
      timerButtonText = "end";
    });

    await scheduleEndingNotification(timerDuration.inSeconds);

    intervalsEnabled = Settings.getValue<bool>('intervals-enabled') ?? false;
    if (intervalsEnabled) {
      intervalTime =
          Duration(minutes: int.parse(Settings.getValue<String>('interval-time') ?? '0'));
      if (intervalTime.inMinutes >= 1) {
        log.i('enabling intervals');
        var diff = endTime.difference(startTime);
        intervalCount = (diff.inMinutes / intervalTime.inMinutes).floor();
        if (diff.inMinutes % intervalTime.inMinutes == 0) {
          // if no remainder, then we remove the last count
          // which would happen together with the end bell
          intervalCount -= 1;
        }
        log.d("interval count: $intervalCount");
        intervalNotificationIDs.clear();
        for (var i = 1; i <= intervalCount; i++) {
          var id = intervalNotificationID + i;
          log.d(
              "scheduling interval notification with id $id " + "in ${i * intervalTime.inMinutes}");
          await scheduleIntervalNotification(i * intervalTime.inSeconds, id: id);
          intervalNotificationIDs.add(id);
        }
      }
    }

    NAudioPlayer audioPlayer = GetIt.I.get<NAudioPlayer>();
    audioPlayer.playSound('start-sound');

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meditation started')));
  }

  void onTimerEnd({bool playAudio = true}) async {
    // log.i("timer-end", "called");
    // making sure this doesn't get called twice
    // since we do use the backup check on timerUpdate
    // as well as the notification
    if (timerState == TimerState.stopped) {
      // if (!meditating) {
      log.e("onTimerEnd called when it shouldn't have");
      return;
    }

    setState(() {
      // one last update so we know how much we were off on timeout
      if (timerState == TimerState.meditating) {
        log.d("ending meditation at timeLeft: $timeLeft");
        timeLeft = timeLeftTo(endTime, roundToZero: true);
      }
      timerButtonText = "begin";
    });

    timerState = TimerState.stopped;
    ticker.stop();

    // removing 'meditation started' snackbar in case it's still showing
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    WakelockPlus.disable();

    if (Settings.getValue<bool>('dnd') == true) {
      log.i('disabling dnd');
      await dndPlugin.setInterruptionFilter(InterruptionFilter.all);
      // await FlutterDnd.setInterruptionFilter(
      //     FlutterDnd.INTERRUPTION_FILTER_ALL);
    }

    if (Platform.isAndroid) {
      if (FlutterBackground.isBackgroundExecutionEnabled) {
        bool backgroundSuccess = await FlutterBackground.disableBackgroundExecution();
        log.i("disable flutter_background: success = $backgroundSuccess");
      } else {
        log.e("background wasn't enabled. why?");
      }
    }

    if (Platform.isAndroid) {
      // only dismiss on android
      // why do we want to dismiss?
      // Timer(const Duration(seconds: 10), () {
      //   log.i("dismissing end notification");
      //   AwesomeNotifications().dismiss(endingNotificationID);
      // });
    }

    AwesomeNotifications().cancelSchedulesByGroupKey('timer-interval');


    sessionID = await db.getNewId();

    log.d("sessionID: $sessionID");

    // Duration dur = endTime.difference(startTime) - timeLeft;
    Duration dur = Duration(minutes: timerMinutes) - timeLeft;
    log.d("session duration: ${dur.inSeconds} seconds");

    db.insertSession(Session(
      id: sessionID,
      started: startTime,
      ended: endTime,
      duration: dur,
      message: ""
    ));
    NAudioPlayer audioPlayer = GetIt.I.get<NAudioPlayer>();
    if (playAudio) {
      audioPlayer.playSound('end-sound');
    } else {
      audioPlayer.stopPrevious();
    }
  }

  Future<void> scheduleEndingNotification(int intervalSeconds) async {
    String localTimeZone = await AwesomeNotifications().getLocalTimeZoneIdentifier();
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: endingNotificationID,
        channelKey: 'timer-main',
        groupKey: 'timer-end',
        title: 'Meditation ended',
        body: 'Swipe to dismiss',
        // icon: 'resource://drawable/ic_notification',
        largeIcon: 'resource://mipmap/ic_launcher',
        // Alarm and Event seem to both show up in dnd mode (this is what we want)
        // Alarm also makes the notification undismissable with swiping and requires interaction
        // which we probably don't want
        // Event instead is dismissable
        // category: NotificationCategory.Alarm,
        category: NotificationCategory.Event,
        // notificationLayout: NotificationLayout.Default,
        notificationLayout: NotificationLayout.BigPicture,
        // criticalAlert: play sounds even when in dnd. likely only useful for ios
        criticalAlert: true,
        // autoDismissible: gets dismissed on tap (meaning even when it opens the app, it dismisses itself)
        // if false, tapping will open the app but the notification stays
        autoDismissible: true,
        // wakeUpScreen: wake up screen even when locked
        // shows app in fullscreen even from locked (but only if phone was locked with app in foreground)
        wakeUpScreen: true,
        // fullScreenIntent keeps showing the notification popup in front permanently until user dismisses it
        // for some reason fullscreenintent makes the notification not appear
        fullScreenIntent: false,
        // dismiss this automatically after a few seconds. or maybe better not? i quite like seeing the confirmation of end
        // timeoutAfter: Duration(seconds: 10),
        // don't open the app on tap
        actionType: ActionType.DisabledAction,
      ),
      schedule: NotificationInterval(
          interval: Duration(seconds: intervalSeconds),
          timeZone: localTimeZone,
          allowWhileIdle: true,
          preciseAlarm: true),
      // actionButtons: [
      //   NotificationActionButton(
      //     key: 'dismiss',
      //     label: 'Dismiss',
      //     autoDismissible: true,
      //   ),
      // ],
    );
  }

  Future<void> scheduleStartingNotification(int intervalSeconds) async {
    String localTimeZone = await AwesomeNotifications().getLocalTimeZoneIdentifier();
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: startingNotificationID,
        channelKey: 'timer-support',
        groupKey: 'timer-start',
        title: 'Meditation started',
        body: 'Tap to return to app',
        // icon: 'resource://drawable/ic_notification',
        largeIcon: 'resource://mipmap/ic_launcher',
        category: NotificationCategory.Event,
        notificationLayout: NotificationLayout.BigPicture,
        criticalAlert: false,
        autoDismissible: true,
        wakeUpScreen: false,
        fullScreenIntent: false,
      ),
      schedule: NotificationInterval(
          interval: Duration(seconds: intervalSeconds),
          timeZone: localTimeZone,
          allowWhileIdle: true,
          preciseAlarm: true),
    );
  }

  Future<void> scheduleIntervalNotification(int intervalSeconds,
      {int id = intervalNotificationID}) async {
    String localTimeZone = await AwesomeNotifications().getLocalTimeZoneIdentifier();
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'timer-support',
        groupKey: 'timer-interval',
        title: 'Meditation interval',
        body: 'Tap to return to app',
        icon: 'resource://drawable/ic_notification',
        largeIcon: 'resource://mipmap/ic_launcher',
        category: NotificationCategory.Event,
        notificationLayout: NotificationLayout.BigPicture,
        criticalAlert: true,
        autoDismissible: true,
        wakeUpScreen: true,
        fullScreenIntent: false,
      ),
      schedule: NotificationInterval(
          interval: Duration(seconds: intervalSeconds),
          timeZone: localTimeZone,
          allowWhileIdle: true,
          preciseAlarm: true),
    );
  }

  Future<void> showTimeChoice() async {
    var minutes;
    var timeChoices = [5, 10, 15, 20, 25, 30, 45, 60];

    var _selected = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: const Text('Select time'),
            //@formatter:off
            children: <Widget>[
              if (!kReleaseMode) SimpleDialogOption(
                onPressed: () { Navigator.pop(context, 0); },
                child: const Text('0 - 10s'),
              ),
              SimpleDialogOption(
                onPressed: () { Navigator.pop(context, 1); },
                child: const Text('1 minute'),
              ),
              for (var t in timeChoices) SimpleDialogOption(
                onPressed: () { Navigator.pop(context, t); },
                child: Text('$t minutes'),
              ),
              SimpleDialogOption(
                onPressed: () { Navigator.pop(context, -1); },
                child: const Text('custom...'),
              ),
            ],
            //@formatter:on
          );
        });

    if (_selected == null) {
      // we just closed the dialog without choosing anything
      return;
    }

    if (_selected >= 0) {
      // preset chosen
      minutes = _selected;
    } else if (_selected == -1) {
      // inputting custom time
      final Color borderColor = primaryColor!;
      final Color errorColor = secondaryColor!;
      final GlobalKey<FormState> formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      var cancelled = true;

      await showDialog(
          context: context,
          builder: (BuildContext context) {
            return SimpleDialog(
              title: const Text('Input time'),
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(16),
                  // do we need the form?
                  child: Form(
                    key: formKey,
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      controller: controller,
                      autofocus: true,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        FilteringTextInputFormatter.deny(RegExp(r"^0")),
                      ],
                      validator: timeInputValidatorConstructor(
                          minTimerTime: 1, maxTimerTime: maxMeditationTime) as Validator,
                      decoration: InputDecoration(
                        helperText: "Input time in minutes, between 1 and $maxMeditationTime.",
                        errorMaxLines: 3,
                        helperMaxLines: 3,
                        errorStyle: TextStyle(
                          color: errorColor,
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(5.0),
                          ),
                          borderSide: BorderSide(color: errorColor),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(5.0),
                          ),
                          borderSide: BorderSide(
                            color: borderColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(5.0),
                          ),
                          borderSide: BorderSide(
                            color: borderColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                ButtonBar(
                  alignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: Text("CANCEL"),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    TextButton(
                      child: Text("OK"),
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          cancelled = false;
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
              ],
            );
          });

      if (cancelled) {
        // pressed cancel or outside the dialog
        return;
      } else {
        minutes = int.parse(controller.text);
      }
    }

    if (minutes == null) {
      log.e("we didn't get to choose any value for minutes. something went very wrong");
    }

    setState(() {
      timerMinutes = minutes;
    });
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('timer-minutes', timerMinutes);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        if (Settings.getValue<bool>('show-countdown') == true)
          Align(
              alignment: Alignment(0, -0.70),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(timeLeftString(timeLeft), style: Theme.of(context).textTheme.bodyLarge),
                ],
              )),
        SizedBox(
          width: MediaQuery.of(context).size.shortestSide / 1.5,
          height: MediaQuery.of(context).size.shortestSide / 1.5,
          child: Stack(
            children: <Widget>[
              Align(
                alignment: Alignment(0, -0.1),
                child: Stack(
                  alignment: AlignmentDirectional.center,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.shortestSide / 1.5,
                      height: MediaQuery.of(context).size.shortestSide / 1.5,
                      child: CircularProgressIndicator(
                        value: timerState == TimerState.meditating ? timerProgress : 0.0,
                        strokeWidth: 10,
                      ),
                    ),
                    TextButton(
                      style: timerButtonStyle,
                      onPressed: () {
                        onTimerButtonPress();
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.shortestSide / 1.75,
                        height: MediaQuery.of(context).size.shortestSide / 1.75,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(shape: BoxShape.circle),
                        child: Text(timerButtonText.toUpperCase()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment(0, 0.75),
          child: TextButton(
            style: timeSelectionButtonStyle,
            onPressed: () {
              showTimeChoice();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule,
                  size: 30,
                ),
                Text(
                  ' ${timerMinutes}m',
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
