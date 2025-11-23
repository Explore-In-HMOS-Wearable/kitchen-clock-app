import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ArcList, ArcListItem, ArcListAttribute, ArcListItemAttribute, ComponentContent } from '@kit.ArkUI';
import { HomeViewModel } from '../viewmodel/HomeViewModel';

@Builder
function buildText() {
  Column() {
    Text('Timer List')
      .fontSize(28)
      .fontWeight(FontWeight.Bolder)
      .fontColor(Color.White)
  }
  .margin(6)
}

@Entry
@Component
struct ListPage {
  context: UIContext = this.getUIContext()
  header: ComponentContent<Object> = new ComponentContent(this.context, wrapBuilder(buildText));
  private reminderId: number = -1;
  @State reminderStatus: string = 'Ready';
  @State reminderTitle: string = '';
  @State reminderContent: string = '';
  @State reminderTime: string = '';
  @State showInputForm: boolean = false;
  @State notificationId: number = 1000;
  @State reminderList : reminderAgentManager.ReminderRequest[] = []
  homeVm : HomeViewModel = new HomeViewModel()

  aboutToAppear(): void {
    this.listReminders()
  }

  build() {
    if (this.reminderList.length > 0) {
      ArcList({
        initialIndex: 0, header: this.header
      }) {
        ForEach(this.reminderList, (item: reminderAgentManager.ReminderRequest, index) => {
          ArcListItem() {
            Row({space: 10}) {
              Text(item.title)
                .fontSize(22)
                .fontColor('#ffeceaea')
                .fontWeight(FontWeight.Bold)
            }
            .padding({
              left: 26,
              bottom: 12,
              top: 12,
              right: 26,
            })
            .backgroundColor('#7a8bfc31')
            .width('100%')
            .height('100px')
            .borderRadius(48)
            .borderWidth(1)
            .borderColor('#ffeceaea')

          }
          .onClick(() => {
            this.homeVm.navigationService.pageInfos.pushPath(
              {
                name: 'Details',
                param: JSON.stringify(item)
              })
          })
          .width('90%')
          .margin({ bottom: 10 })
        }, (item: string) => item);
      }
      .backgroundColor(Color.Black)
      .scrollBar(BarState.Off)
      .zIndex(2)
      .padding({top:8, bottom: 8})
      .height('100%')
      .width('100%')
    } else {
      Column() {
        Text('No Active Reminder')
          .fontSize(22)
          .fontColor('#ffeceaea')
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .textAlign(TextAlign.Center)
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .height('100%')
      .width('100%')
    }
  }

  private listReminders() {
    console.info('listReminders() started');

    reminderAgentManager.getValidReminders().then((reminders) => {
      console.info(`Retrieved ${reminders.length} active reminders`);
      if (reminders.length === 0) {
        this.reminderStatus = 'No active reminders.';
        return;
      }

      this.reminderStatus = `Total reminders: ${reminders.length}`;
      this.reminderList = reminders
    }).catch((err: BusinessError) => {
      console.info(`Error while listing reminders: ${err.code}`);
      this.reminderStatus = `Listing error: ${err.code}`;
    });
  }
}

export { ListPage };