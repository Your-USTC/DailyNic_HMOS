import { webview } from '@kit.ArkWeb';
import UpdateInfo from '../view/UpdateInfo';
import UnifiedPreferences from '../utils/UnifyPreference';
import { currentAppVersion } from '../constants/BasicConstants';

@Entry
@Component
struct UpdateLog {
  @State agreePolitic: boolean = false;
  @State showSheet: boolean = false;
  private webController: webview.WebviewController | undefined = undefined;

  onBackPress(): boolean {
    return true;
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.icon_round'))
          .height(80)
          .width(80)
        Column() {
          Text($r('app.string.have_updated'))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 6 })
          Text($r('app.string.update_log'))
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
        }
        .margin({ left: 12 })
      }
      .margin({ bottom: 5 })

      Column() {
        UpdateInfo()
          .width('100%')
      }
      .padding({ top: 16, bottom: 16 })
      .margin({ left: 10, right: 10 })
      .backgroundColor($r('app.color.normal_background'))
      .borderRadius(20)
      .width('100%')
      .constraintSize({ maxWidth: 750 })
      .layoutWeight(1)

      Row() {
        Checkbox()
          .onChange((value: boolean) => {
            this.agreePolitic = value;
          })
        Text() {
          Span($r('app.string.updated_privacy_policy'))
            .fontColor($r('app.color.red'))
          Span($r('app.string.terms_of_use_and_privacy_policy'))
            .fontColor($r('app.color.active_text'))
            .onClick(() => {
              if (this.webController === undefined)
                this.webController = new webview.WebviewController();
              this.showSheet = true;
            })
            .decoration({
              type: TextDecorationType.Underline,
              color: $r('app.color.active_text')
            })
        }
        .bindSheet($$this.showSheet, this.agreementSheet(), {
          detents: [SheetSize.LARGE],
          preferType: SheetType.CENTER,
          title: { title: $r('app.string.terms_of_use_and_privacy_policy'), subtitle: $r('app.string.version', currentAppVersion) }
        })
      }

      Row() {
        Blank()
        Button($r('app.string.nic_launch'))
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .enabled(this.agreePolitic)
          .onClick(() => {
            UnifiedPreferences.putSync('AppVersion', currentAppVersion);
            this.getUIContext().getRouter().back();
          })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  agreementSheet() {
    Web({ src: $rawfile('TermsOfUse.html'), controller: this.webController })
      .height('100%')
      .width('100%')
      .darkMode(WebDarkMode.Auto)
      .backgroundColor($r('app.color.normal_background'))
  }
}