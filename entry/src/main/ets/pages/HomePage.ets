import { HomeViewModel } from '../viewmodel/HomeViewModel';

@Component
struct HomePage {
  homeVm : HomeViewModel = new HomeViewModel()

  build() {
    Scroll() {
      Column({ space: 12 }) {
        Text('Kitchen Clock')
          .fontSize(24)
          .fontWeight(FontWeight.Bolder)
          .fontColor(Color.Green)

          Button('Create Cook Alarm').onClick(() => {
            this.homeVm.goToPage('Create')
          }).buttonsStyle()

          Button('📋 Show Reminders').onClick(() => {
            this.homeVm.goToPage('List')
          }).buttonsStyle()
      }
      .padding(20)
    }
    .height('100%')
    .width('100%')
    .backgroundColor(Color.White)
  }
}

@Extend(Button)
function buttonsStyle() {
  .width('100%')
  .height(30)
  .borderRadius(10)
  .fontSize(13)
  .backgroundColor(Color.Green)
}

export { HomePage };
