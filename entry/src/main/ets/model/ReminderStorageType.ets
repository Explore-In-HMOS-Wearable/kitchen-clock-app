export class ReminderStorageType {
  reminderId: number;
  endTime : number;

  constructor( reminderId: number, endTime : number) {
    this.reminderId = reminderId
    this.endTime = endTime
  }
}