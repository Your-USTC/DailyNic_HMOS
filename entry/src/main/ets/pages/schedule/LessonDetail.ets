import { LessonInfo } from "../../utils/ScheduleData";
import { PopoverDialog, Popup } from "@kit.ArkUI";
import UnifiedPreferences from '../../utils/UnifyPreference';
import { seconds2Time } from "../../utils/tools";
import dayjs from "dayjs";

@Component
export struct LessonDetail {
  @Require @Prop lesson: LessonInfo;

  @State showScrollHint: boolean = false;

  build() {
    Column() {
      Row({ space: 6 }) {
        Text($r('app.string.class_detail'))
          .fontWeight(FontWeight.Bold)
          .fontSize(24)
          .layoutWeight(1)
          .margin({ left: 8 })

        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.close'))
            .height(24)
            .width(24)
        }
        .width(42)
        .height(42)

        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.checkmark'))
            .height(24)
            .width(24)
        }
        .width(42)
        .height(42)
      }
      .margin({ bottom: 7 })
      .bindPopup(this.showScrollHint, {
        builder: this.scrollHintPopup,
        placement: Placement.Bottom,
        width: 300,
        onStateChange: (status) => {
          if (!status.isVisible) {
            this.showScrollHint = false;
          }
        }
      });

      Scroll() {
        Column() {
          Row() {
            Text($r('app.string.class_detail_name'));
            Text(this.lesson.courseName)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
          }
          .margin({ bottom: 5 });

          Row() {
            Text($r('app.string.class_detail_teacher'));
            Text(this.lesson.teachers.join("，"))
              .layoutWeight(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .margin({ bottom: 5 });

          Row() {
            Text($r('app.string.class_detail_location'));
            Text(this.lesson.place)
              .layoutWeight(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .margin({ bottom: 5 });

          Row() {
            Text($r('app.string.class_detail_id'));
            Text(this.lesson.lessonCode)
              .layoutWeight(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .margin({ bottom: 5 });

          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
            Row() {
              Text($r('app.string.class_detail_time'))
                .textAlign(TextAlign.Start);
              Text(seconds2Time(this.lesson.start) + " ~ " + seconds2Time(this.lesson.end))
            }
            .margin({ bottom: 5, right: 10 })

            Text($r(`app.string.${dayjs.weekdays()[this.lesson.weekday]}`))
              .textAlign(TextAlign.Start)
              .margin({ bottom: 5 })
          }

          // Row() {
          //   Text('学分：')
          //     .textAlign(TextAlign.Start);
          //   TextInput({ text: this.classInfo.credits })
          //     .layoutWeight(1)
          //     .type(InputType.NUMBER_DECIMAL)
          //     .textOverflow(TextOverflow.Ellipsis)
          //     .onChange((input: string) => this.classInfo.credits = input)
          //     .selectAll(true);
          // }
          // .margin({ bottom: 5 })

          // Row() {
          //   Text($r('app.string.class_detail_color'))
          //     .textAlign(TextAlign.Start);
          //   Stack({ alignContent: Alignment.End }) {
          //     TextInput({ text: this.lesson.color ?? "#FFFFFF" })
          //       .textOverflow(TextOverflow.Ellipsis)
          //       .onChange((input: string) => {
          //         // console.log('test'); 此处证明了this.classColor = input;不会导致死循环
          //         if (/^#([A-Fa-f0-9]{3}|[A-Fa-f0-9]{4}|[A-Fa-f0-9]{6}|[A-Fa-f0-9]{8})$/.test(input)) {
          //           this.isColorLegal = true;
          //           this.classInfo.color = input;
          //           this.colorARGB = tools.stringToRgba(input);
          //         } else {
          //           this.isColorLegal = false;
          //         }
          //         this.classColor = input;
          //       })
          //       .width('100%')
          //       .selectAll(true);
          //     Circle()
          //       .fill(this.isColorLegal ? this.classColor : '#00d00721')
          //       .width(32)
          //       .height(32)
          //       .offset({ x: -4 })
          //       .stroke(this.isColorLegal ? $r('app.color.grid_border') : $r('app.color.red'))
          //       .bindPopup(this.showColorHint, {
          //         builder: this.colorHintPopup(),
          //         placement: Placement.Left,
          //         width: 300,
          //         onStateChange: (status) => {
          //           if (!status.isVisible) {
          //             this.showColorHint = false;
          //           }
          //         }
          //       });
          //     Image($r('app.media.paintpalette'))
          //       .height(25)
          //       .offset({ x: -7 })
          //       .onClick(() => {
          //         if (this.classColor.length === 4) {
          //           this.colorDialogText = this.classColor[0] + this.classColor[1] + this.classColor[1]
          //             + this.classColor[2] + this.classColor[2] + this.classColor[3] + this.classColor[3];
          //         } else if (this.classColor.length === 5) {
          //           this.colorDialogText = this.classColor[0] + this.classColor[1] + this.classColor[1]
          //             + this.classColor[2] + this.classColor[2] + this.classColor[3] + this.classColor[3]
          //             + this.classColor[4] + this.classColor[4];
          //         } else {
          //           this.colorDialogText = this.classColor;
          //         }
          //         this.colorARGB = tools.stringToRgba(this.colorDialogText);
          //         if (this.colorDialogText.length === 7)
          //           this.colorDialogText = `#FF${this.colorDialogText.slice(1,7)}`;
          //         this.showColorPicker = true;
          //       });
          //   }
          //   .layoutWeight(1);
          //   PopoverDialog({
          //     visible: this.showColorPicker,
          //     targetBuilder: () => {},
          //     popover: {
          //       width: 300,
          //       placement: Placement.Top,
          //       arrowPointPosition: ArrowPointPosition.END,
          //       builder: () => { this.colorPicker() },
          //       onStateChange: (popup) => {
          //         if (!popup.isVisible) {
          //           // 关闭弹窗后记录颜色值
          //           this.showColorPicker = false;
          //           if (this.colorARGB[0] === 255) {
          //             this.classColor = '#' + this.colorARGB[1].toString(16).padStart(2, '0').toUpperCase()
          //               + this.colorARGB[2].toString(16).padStart(2, '0').toUpperCase()
          //               + this.colorARGB[3].toString(16).padStart(2, '0').toUpperCase();
          //           } else {
          //             this.classColor = '#' + this.colorARGB[0].toString(16).padStart(2, '0').toUpperCase()
          //               + this.colorARGB[1].toString(16).padStart(2, '0').toUpperCase()
          //               + this.colorARGB[2].toString(16).padStart(2, '0').toUpperCase()
          //               + this.colorARGB[3].toString(16).padStart(2, '0').toUpperCase();
          //           }
          //           this.classInfo.color = this.classColor;
          //         }
          //       }
          //     },
          //   })
          // }
          // .margin({ bottom: 5 })

          // Row() {
          //   Text($r('app.string.class_detail_weeks', tools.shrinkContArrayToString(this.weekOfTerm)))
          //     .textAlign(TextAlign.Start)
          //     .layoutWeight(1)
          //     .maxLines(2)
          //     .textOverflow({ overflow: TextOverflow.Ellipsis });
          //   CheckboxGroup({ group: `checkboxGroup${this.checkBoxGroup}` })
          //     .checkboxShape(CheckBoxShape.ROUNDED_SQUARE)
          //     .selectedColor(presetColor[BackgroundImage.themeColor][2])
          //     .onChange((itemName: CheckboxGroupResult) => {
          //       let selectAny: boolean = false;
          //       this.weekOfTerm = [];
          //       for (let weekRepeat = 1; weekRepeat <= 20; weekRepeat++) {
          //         if (this.rectifyWeekOfTerm[weekRepeat]) {
          //           this.weekOfTerm.push(weekRepeat);
          //           selectAny = true;
          //         }
          //       }
          //       this.isWeeksLegal = selectAny;
          //     });
          //   Text($r('app.string.select_all'));
          // }
          // .width('100%');
        }
        .alignItems(HorizontalAlign.Start)
        .width('90%');
      }
      .fadingEdge(true)
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.Top)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false });
    }
    .padding({ top: 16, left: 16, right: 16})
    .width('100%')
    .height('100%')
  }

  @Builder
  scrollHintPopup() {
    Row() {
      Popup({
        icon: { image: $r("app.media.lightbulb") },
        message: { text: $r("app.string.change_detail_size") },
        showClose: false,
        buttons: [{
            text: $r("app.string.no_reminding"),
            action: () => {
              UnifiedPreferences.putSync("ShowColorHint", false);
              this.showScrollHint = false;
            },
          }],
      });
    }
  }
}