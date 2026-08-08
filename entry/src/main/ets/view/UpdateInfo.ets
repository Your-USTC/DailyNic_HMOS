
@Component
export default struct UpdateInfo {
  build() {
    List({ space: 8 }) {
      Repeat<string>(['2_2_0', '2_1_1', '2_1_0', '2_0_0', '1_0_0'])
        .each((ver: RepeatItem<string>) => {
          ListItem() {
            Column() {
              Text($r('app.string.version_' + ver.item + '_date'))
                .fontWeight(FontWeight.Bolder)
              Text($r('app.string.version_' + ver.item + '_extra'))
                .fontColor($r('app.color.red'))
              Row() {
                Text($r('app.string.feat'))
                  .fontWeight(FontWeight.Bold)
                  .fontSize(14)
                  .fontColor($r('app.color.pink'))
                  .margin({ right: 5 })
                Divider()
                  .layoutWeight(1)
              }
              .margin({ top: 5 })

              Text($r('app.string.version_' + ver.item + '_feat'))

              Row() {
                Text($r('app.string.fix'))
                  .fontWeight(FontWeight.Bold)
                  .fontSize(14)
                  .fontColor($r('app.color.bright_blue'))
                  .margin({ right: 5 })
                Divider()
                  .layoutWeight(1)
              }
              .margin({ top: 5 })

              Text($r('app.string.version_' + ver.item + '_fix'))
            }
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 16, right: 16 })
            .padding(16)
            .borderRadius(20)
            .backgroundColor($r('app.color.grid_background'))
          }
          .width('100%')
        })
    }
    .width('100%')
  }
}