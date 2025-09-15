import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { HomeViewModel } from '../viewmodel/HomeViewModel';
import { uiObserver } from '@kit.ArkUI';
import { ReminderStorageType } from '../model/ReminderStorageType';
import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { MediaController } from '../utils/MediaController';

@Entry
@Component
struct DetailsPage {
  @State reminderTitle: string = '';
  @State reminderContent: string = '';
  @State reminderTime: string | undefined = '';
  @State notificationId: number | undefined = 1000;
  @State currCount : number = 0;
  @State total_time : number = 0;
  textTimerController: TextTimerController = new TextTimerController();
  @State format: string = 'mm:ss';
  homeVm : HomeViewModel = new HomeViewModel();
  navDesInfo: uiObserver.NavDestinationInfo | undefined;
  @State remainingMs: number = 0;
  @State remainingSn: number = 0;
  @State test: number = 100;
  @State reminderEndTime: number = 0;

  aboutToDisappear(): void {
    MediaController.getInstance().release();
    MediaController.clearController()
  }

  onBackPress(): boolean | void {
    MediaController.getInstance().release();
    MediaController.clearController()

    this.textTimerController.reset()
    this.textTimerController.pause()
  }

  aboutToAppear(): void {
    MediaController.getInstance();

    this.navDesInfo = this.queryNavDestinationInfo();
    if (this.navDesInfo?.param) {
      let item = JSON.parse(this.navDesInfo?.param as string) as reminderAgentManager.ReminderRequest

      this.reminderTitle = item.title || '';
      this.reminderContent = item.content || '';
      this.reminderTime = item.snoozeTimes?.toString();
      this.notificationId = item.notificationId;

      let list : ReminderStorageType[] | undefined = AppStorage.get('alarmList');
      let reminder = list?.find(r => r.reminderId === this.notificationId);
      if (reminder) {
        this.remainingMs = Math.max(0, Math.floor((reminder.endTime - Date.now())));
        this.remainingSn = Math.max(0, Math.floor((this.remainingMs/1000)));
        this.total_time = this.remainingSn
        this.reminderEndTime = reminder.endTime
        console.error("tag start remaining", this.remainingSn);
      }
    }
  }

  build() {
    Column({space: 10}) {

      Text('Alarm for')
        .fontSize(28)
        .fontColor(Color.Green)
        .width('100%')
        .fontWeight(FontWeight.Bolder)
        .textAlign(TextAlign.Center)

      Text(this.reminderTitle)
        .fontSize(18)
        .fontColor(Color.White)
        .width('100%')
        .textAlign(TextAlign.Center)

      TextTimer({ isCountDown: true, count: this.remainingMs, controller: this.textTimerController })
        .format(this.format)
        .fontColor(Color.White)
        .fontSize(40)
        .onTimer((utc: number, elapsedTime: number) => {

          console.error('tag elapsed',elapsedTime)
          let time = Math.max(0, Math.floor((this.reminderEndTime - Date.now())/1000));
          console.error('tag time : '+time)
          if (time <= 0) {
            console.error("tag timeover");
            this.textTimerController.pause();
            this.makeVibration()
            MediaController.getInstance().startByIndex(0);

            setTimeout(() => {
              MediaController.getInstance().release();
              MediaController.clearController()
            }, 6000);
          }
        })
        .onAppear(() => {
          this.textTimerController.start();
        })
        .fontWeight(FontWeight.Bolder)
        .zIndex(3)
    }
    .width('90%')
    .height('90%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  makeVibration()
  {
    try {
      vibrator.startVibration({
        type: 'time',
        duration: 2000,
      }, {
        id: 0,
        usage: 'alarm'
      }, (error: BusinessError) => {
        if (error) {
          console.error(`Failed to start vibration. Code: ${error.code}, message: ${error.message}`);
          return;
        }
        console.info('Succeed in starting vibration');
      });
    } catch (err) {
      let e: BusinessError = err as BusinessError;
      console.error(`An unexpected error occurred. Code: ${e.code}, message: ${e.message}`);
    }
  }
}

export { DetailsPage };