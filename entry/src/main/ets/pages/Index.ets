import { NavigationService } from '../services/NavigationService';
import { HomePage } from './HomePage';
import { CreatePage } from './CreatePage';
import { ListPage } from './ListPage';
import { DetailsPage } from './DetailsPage';
import { notificationManager } from '@kit.NotificationKit';
import { common } from '@kit.AbilityKit';
import { AlarmService } from '../services/AlarmService';
import { MediaController } from '../utils/MediaController';
import { DataModel } from '../viewmodel/DataModel';

@Entry
@Component
struct Index {
  navigationService: NavigationService = NavigationService.getInstance();
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;

  aboutToAppear() {
    AppStorage.setOrCreate('songList', DataModel.ALARM);
    MediaController.getInstance();

    this.openNotificationPermission(this.context);
    AlarmService.getInstance().startWatcher();
  }

  aboutToDisappear() {
    AlarmService.getInstance().stopWatcher()
  }

  @Builder
  routeMap(name: string) {
    NavDestination() {
      if (name === 'Home') {
        HomePage();
      } else if (name === 'Create') {
        CreatePage();
      } else if (name === 'List') {
        ListPage()
      } else if (name === 'Details') {
        DetailsPage();
      }
    }
    .hideTitleBar(true)
  }

  build() {
    Navigation(this.navigationService.pageInfos) {
      HomePage();
    }
    .mode(NavigationMode.Stack)
    .navDestination(this.routeMap)
    .ignoreLayoutSafeArea()
    .hideTitleBar(true)
    .width('100%')
    .height('100%')
  }

  private openNotificationPermission(context: common.UIAbilityContext) {
    notificationManager.requestEnableNotification(context).then(() => {
      console.info('Enable notification success');
    }).catch((err: Error) => {
      console.error(`Enable notification failed because ${JSON.stringify(err)}`);
    });
  }
}
