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
  /** close() 为异步退场，退场动效期间按钮仍可命中点击，用一次性标记防止连点重复触发回调 */
  private handled: boolean = false;

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
            if (this.handled) return;
            this.handled = true;
            this.onCancel();
            this.controller.close();
          })
          .fontColor(this.cancelColor || presetColor[BackgroundImage.themeColor].accentColor)

        Button($r('app.string.ok'))
          .buttonStyle(ButtonStyleMode.EMPHASIZED)
          .width('50%')
          .backgroundColor(this.confirmColor || presetColor[BackgroundImage.themeColor].accentColor)
          .onClick(() => {
            if (this.handled) return;
            this.handled = true;
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