import BackgroundImage, { presetColor } from '../utils/BgImageManager';

@CustomDialog
export default struct MessageDialog {
  controller: CustomDialogController;
  mainTitle?: ResourceStr;
  message?: ResourceStr;
  confirmColor?: ResourceColor;
  cancelColor?: ResourceColor;
  onConfirm: () => void = () => {};
  onCancel: () => void = () => {};

  build() {
    Column({ space: 10 }) {
      if (this.mainTitle) {
        Text(this.mainTitle)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
      }
      if (this.message) {
        Text(this.message)
      }

      Row() {
        Button($r('app.string.cancel'))
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .width('50%')
          .onClick(() => {
            this.onCancel();
            this.controller.close();
          })
          .fontColor(this.cancelColor || presetColor[BackgroundImage.themeColor][2])

        Button($r('app.string.ok'))
          .buttonStyle(ButtonStyleMode.EMPHASIZED)
          .width('50%')
          .backgroundColor(this.confirmColor || presetColor[BackgroundImage.themeColor][2])
          .onClick(() => {
            this.onConfirm();
            this.controller.close();
          })
      }
      .margin({ top: 5 })
    }
    .width('100%')
    .padding(16)
  }
}