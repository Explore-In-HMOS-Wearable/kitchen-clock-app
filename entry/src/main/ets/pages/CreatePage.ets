import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ReminderStorageType } from '../model/ReminderStorageType';
import { ArcList, ArcListItem, ArcListAttribute, ArcListItemAttribute, ComponentContent,
  PromptAction } from '@kit.ArkUI';

@Builder
function buildText() {
  Column() {
    Text('Create Timer')
      .fontSize(24)
      .fontWeight(FontWeight.Bolder)
      .fontColor(Color.White)
  }
  .margin(6)
}

@Entry
@Component
struct CreatePage {

  context: UIContext = this.getUIContext()
  private reminderId: number = -1;
  @State reminderStatus: string = 'Ready';
  @State reminderTitle: string = '';
  @State reminderContent: string = '';
  @State reminderTime: string = '';
  @State showInputForm: boolean = false;
  @State notificationId: number | undefined = 1000;
  @StorageLink('alarmList') list: ReminderStorageType[] | undefined = [];
  @State lastNotificationId : number = 1000
  header: ComponentContent<Object> = new ComponentContent(this.context, wrapBuilder(buildText));
  @State progressValue: number = 0
  private promptAction: PromptAction = this.context.getPromptAction()

  build() {
    ArcList({
      initialIndex: 0, header: this.header
    }) {
        ArcListItem() {
          Column({ space: 2 }) {
            Text('Title')
              .fontSize(13)
              .fontColor(Color.Gray)
              .width('80%')
              .textAlign(TextAlign.Start)
            TextInput()
              .onChange((val: string) => this.reminderTitle = val)
              .inputStyle(this.reminderTitle)
          }
        }
        .width('90%')
        .margin({ bottom: 10 })

      ArcListItem() {
        Column({ space: 2 }) {
          Text('Content')
            .fontSize(13)
            .fontColor(Color.Gray)
            .width('80%')
            .textAlign(TextAlign.Start)
          TextInput()
            .onChange((val: string) => this.reminderContent = val)
            .inputStyle(this.reminderContent)
        }
      }
      .width('90%')
      .margin({ bottom: 10 })


      ArcListItem() {
        Column({ space: 2 }) {
          Text('Time in minutes')
            .fontSize(13)
            .fontColor(Color.Gray)
            .width('80%')
            .textAlign(TextAlign.Start)
          Counter() {
            Text(this.progressValue.toString())
          }
          .onInc(() => {
            this.progressValue++
          })
          .onDec(() => {
            this.progressValue--
          })
          .height('20%')
          .width('80%')
          .borderRadius(16)
        }
      }
      .width('90%')
      .margin({ bottom: 10 })

      ArcListItem() {
        Button('💾 Save Reminder')
          .onClick(() => {
            this.createReminder();
          })
          .width('80%')
          .height(30)
          .borderRadius(10)
          .fontSize(13)
          .backgroundColor(Color.Green)
      }
      .margin({ bottom: 10 })
    }
    .scrollBar(BarState.Off)
    .zIndex(2)
    .padding({top:8, bottom: 8})
    .height('100%')
    .width('100%')
    .backgroundColor(Color.Black)
  }

  private createReminder() {
    console.info('createReminder() started');
    let value = this.progressValue * 60
    this.reminderTime = value.toString()
    const timeInSeconds = parseInt(this.reminderTime);

    if (isNaN(timeInSeconds) || timeInSeconds <= 0) {
      console.info('Invalid time input');
      this.reminderStatus = 'Please enter a valid time in seconds.';
      return;
    }

    if (!this.reminderTitle || !this.reminderContent) {
      console.info('Title or content missing');
      this.reminderStatus = 'Please fill in both title and content.';
      return;
    }

    this.lastNotificationId = AppStorage.get('lastNotificationId') || 1000
    this.lastNotificationId++;
    AppStorage.setOrCreate('lastNotificationId', this.lastNotificationId);

    let timerReminder: reminderAgentManager.ReminderRequestTimer = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_TIMER,
      triggerTimeInSeconds: timeInSeconds,
      title: this.reminderTitle,
      content: this.reminderContent,
      notificationId: this.lastNotificationId
    };

    let endTime = Date.now() + timeInSeconds * 1000
    let alarm : ReminderStorageType = new ReminderStorageType(this.lastNotificationId,endTime)

    let list : ReminderStorageType[] | undefined = AppStorage.get('alarmList')
    list?.push(alarm)
    AppStorage.setOrCreate('alarmList', list);

    this.list = AppStorage.get('alarmList')
    console.info(`Publishing reminder with ID: ${this.notificationId}`);

    reminderAgentManager.publishReminder(timerReminder).then((id: number) => {
      console.info(`Reminder published successfully with request ID: ${id}`);
      this.reminderId = id;
      this.reminderStatus = `Reminder set.`;
      this.showInputForm = false;
      this.reminderTitle = '';
      this.reminderContent = '';
      this.reminderTime = '';
      this.progressValue = 0;

      try {
        this.promptAction.showToast({
          message: 'Alarm setted',
          duration: 2000
        });
      } catch (error) {
        console.error(`showToast args error code is ${error}`);
      };

    }).catch((err: BusinessError) => {
      console.info(`Failed to publish reminder: ${err.code}, ${err.message}`);
      this.reminderStatus = `Error: ${err.code}, ${err.message}`;
    });
  }
}

@Extend(TextInput)
function inputStyle(value: string) {
  .width('90%')
  .height('20%')
  .padding(6)
  .borderWidth(1)
  .borderColor(Color.White)
  .opacity(0.7)
  .fontSize(14)
  .borderRadius(8)
  .fontColor(value ? Color.White : Color.Green)
}

export { CreatePage };