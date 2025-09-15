import { notificationManager } from '@kit.NotificationKit';
import { vibrator } from '@kit.SensorServiceKit';
import { MediaController } from '../utils/MediaController';
import { ReminderStorageType } from '../model/ReminderStorageType';
import { BusinessError } from '@kit.BasicServicesKit';

export class AlarmService {
  private static instance: AlarmService;
  private intervalId: number | null = null;

  private constructor() {}

  public static getInstance(): AlarmService {
    if (!AlarmService.instance) {
      AlarmService.instance = new AlarmService();
    }
    return AlarmService.instance;
  }

  public startWatcher() {
    if (this.intervalId !== null) return;
    console.info("AlarmService started");

    this.intervalId = setInterval(() => {
      let list = AppStorage.get('alarmList') as ReminderStorageType[] | undefined;
      if (!list) return;

      let now = Date.now();
      let updatedList: ReminderStorageType[] = [];

      list.forEach(alarm => {
        if (alarm.endTime <= now) {
          console.error("Alarm time reached: " + alarm.reminderId);

          let publishCallback = (err: BusinessError): void => {
            if (err) {
              console.error(`Failed to publish notification. Code is ${err.code}, message is ${err.message}`);
            } else {
              console.info(`Succeeded in publishing notification.`);
            }
          }

          let notificationRequest: notificationManager.NotificationRequest = {
            id: 1,
            content: {
              notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
              normal: {
                title: "Alarm Finished!",
                text: "Your cooking timer is up!",
                additionalText: "test_additionalText"
              }
            }
          };
          notificationManager.publish(notificationRequest, publishCallback);

          vibrator.startVibration({
            type: 'time',
            duration: 2000,
          }, {
            id: 0,
            usage: 'alarm'
          });

          MediaController.getInstance().startByIndex(0);

          setTimeout(() => {
            MediaController.getInstance().release();
            MediaController.clearController()
          }, 6000);

        } else {
          updatedList.push(alarm);
        }
      });

      AppStorage.setOrCreate('alarmList', updatedList);
    }, 1000);
  }

  public stopWatcher() {
    if (this.intervalId !== null) {
      clearInterval(this.intervalId);
      this.intervalId = null;
      console.info("AlarmService stopped");
    }
  }
}
