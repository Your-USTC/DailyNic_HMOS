
import UnifiedPreferences from '../utils/UnifyPreference';
import { BusinessError, pasteboard } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { examAttribute } from '../utils/ExamStorage';
import * as ScheduleStorage from '../utils/ScheduleStorage';
import * as ExamStorage from '../utils/ExamStorage';
import { WantAbility } from '../utils/WantAbility';

@Entry
@Component
struct FaultOccurred {
  private button1ClickTimes: number = 0;
  private button2ClickTimes: number = 0;
  private button3ClickTimes: number = 0;
  @State button1Text: ResourceStr = $r('app.string.delete_schedule');
  @State button2Text: ResourceStr = $r('app.string.delete_preference');
  @State button3Text: ResourceStr = $r('app.string.delete_exam_info');

  build() {
    Scroll() {
      Column() {
        Image($r('app.media.fault_occurred'))
          .height(180)
          .draggable(false)
        Text($r('app.string.runtime_error'))
          .fontColor($r('app.color.normal_text'))
          .fontSize(20)
          .margin({ bottom: 10 })
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center);
        Text($r('app.string.dangerous_behavior'))
          .fontSize(24)
          .fontWeight(FontWeight.Bolder)
          .fontColor($r('app.color.red'));
        Flex() {
          Button(this.button1Text)
            .backgroundColor($r('app.color.red'))
            .onClick(() => {
              this.button1ClickTimes++;
              if (this.button1ClickTimes == 2) {
                ScheduleStorage.clearScheduleData();
                this.button1Text = $r('app.string.clear_success');
              } else if (this.button1ClickTimes == 1) {
                this.button1Text = $r('app.string.click_again_to_delete');
              }
            });
          Button(this.button2Text)
            .backgroundColor($r('app.color.red'))
            .margin({ left: 8 })
            .onClick(() => {
              this.button2ClickTimes++;
              if (this.button2ClickTimes == 2) {
                UnifiedPreferences.clear();
                this.button2Text = $r('app.string.clear_success');
              } else if (this.button2ClickTimes == 1) {
                this.button2Text = $r('app.string.click_again_to_delete');
              }
            });
          Button(this.button3Text)
            .backgroundColor($r('app.color.red'))
            .margin({ left: 8 })
            .onClick(() => {
              this.button3ClickTimes++;
              if (this.button3ClickTimes == 2) {
                ExamStorage.clearExamData();
                this.button3Text = $r('app.string.clear_success');
              } else if (this.button3ClickTimes == 1) {
                this.button3Text = $r('app.string.click_again_to_delete');
              }
            });
        }
        .borderStyle(BorderStyle.Solid)
        .width('auto')
        .borderWidth(2)
        .borderColor($r('app.color.red'))
        .padding({ top: 10, bottom: 10, left: 10, right: 10 });

        Text('「导入和导出课表」功能现已迁移到课表页面')
          .margin({ top: 10 });

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center, alignContent: FlexAlign.Start }) {
          Row() {
              PasteButton({ icon: PasteIconStyle.LINES, buttonType: ButtonType.Circle})
                .size({ width: 30, height: 30 })
                .onClick((event: ClickEvent, result: PasteButtonOnClickResult, error?: BusinessError<void>) => {
                  if (result === PasteButtonOnClickResult.SUCCESS) {
                    pasteboard.getSystemPasteboard().getData((err: BusinessError, pasteData: pasteboard.PasteData) => {
                      if (err) {
                        this.getUIContext().getPromptAction().showToast({ message: $r('app.string.import_failed') });
                        return;
                      }
                      const pasteText: string = pasteData.getPrimaryText();
                      try {
                        const parsedData: examAttribute[] = JSON.parse(pasteText);
                        if (typeof parsedData !== 'object' || parsedData === null) {
                          throw new Error();
                        }
                        for (let singleData of parsedData)
                          if (singleData.id == undefined || singleData.type == undefined || singleData.name == undefined
                            || singleData.date == undefined || singleData.classroom == undefined
                            || singleData.building == undefined || singleData.campus == undefined
                            || singleData.info == undefined || singleData.beginTimeStamp == undefined
                            || singleData.endTimeStamp == undefined || singleData.beginTimeStamp > singleData.endTimeStamp
                            || !/^\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}~\d{2}:\d{2}$/.test(singleData.date)) {
                            throw new Error();
                          }
                        ExamStorage.setExams(parsedData);
                        this.getUIContext().getPromptAction().showToast({ message: $r('app.string.import_success') });
                      } catch (error) {
                        this.getUIContext().showAlertDialog({
                          title: $r('app.string.import_failed'),
                          subtitle: $r('app.string.import_from_clipboard_failed'),
                          message: ( pasteText === undefined ) ? $r('app.string.empty_clipboard') : $r('app.string.first_100_char_s', pasteText.slice(0, 100)),
                          confirm:{
                            value: "确认",
                            action: () => {}
                          },
                          cancel: () => {}
                        });
                      }
                    });
                  } else {
                    this.getUIContext().getPromptAction().showToast({ message: $r('app.string.import_failed') });
                  }
                });
              Text($r('app.string.import_exam'));
            }
            .margin({ right: 8 });

            Button($r('app.string.export_exam'))
              .buttonStyle(ButtonStyleMode.TEXTUAL)
              .onClick(() => {
                const pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, `${JSON.stringify(ExamStorage.getExams())}`);
                const systemPasteboard = pasteboard.getSystemPasteboard();
                systemPasteboard.setData(pasteboardData);
                systemPasteboard.getData().then((data) => {
                  if (data) {
                    this.getUIContext().getPromptAction().showToast({ message: $r('app.string.copy_success'), duration: 1000 });
                  } else {
                    this.getUIContext().getPromptAction().showToast({ message: $r('app.string.copy_failed'), duration: 1000 });
                  }
                });
              });
        }
        .width('100%')

        Button($r('app.string.normal_restart'))
          .margin({ top: 10 })
          .onClick(() => {
            UnifiedPreferences.putSync('RecoveryMode', false);
            UnifiedPreferences.putSync('FaultOccurred', false);
            WantAbility.restart(this.getUIContext().getHostContext() as common.UIAbilityContext);
          })
        Button($r('app.string.contact_developer'))
          .buttonStyle(ButtonStyleMode.NORMAL)
          .margin({ top: 10})
          .onClick(() => {
            WantAbility.openGitHub(this.getUIContext().getHostContext() as common.UIAbilityContext);
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
  }
}