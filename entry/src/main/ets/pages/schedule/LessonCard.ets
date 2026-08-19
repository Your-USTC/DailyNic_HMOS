import { LessonInfo } from "../../utils/ScheduleData";
import { time2Percent } from "../../utils/tools";
import { LessonDetail } from "./LessonDetail";
import { drawing } from "@kit.ArkGraphics2D";

@Component
export struct LessonCard {
  @Require lesson: LessonInfo | LessonInfo[];
  @Require @Prop parentHeight: number;
  weekday: number = 0;
  color: string = "";
  startPercent: number = 0;
  endPercent: number = 0;

  // 仅在叠课时用到
  startTime: number = 0;
  endTime: number = 0

  @State showOverlappedPopup: boolean = false; // 叠课详情弹窗

  aboutToAppear(): void {
    if(Array.isArray(this.lesson)) {
      this.weekday = this.lesson[0].weekday;
      let start = 86400, end = 0;
      const blended: [number, number, number] = [0, 0, 0];
      for(const l of this.lesson) {
        start = Math.min(start, l.start);
        end = Math.max(end, l.end);
        const c = drawing.Tool.makeColorFromResourceColor(l.color ?? "#FFFFFF");
        blended[0] += Math.pow(c.red / 255, 2.2);
        blended[1] += Math.pow(c.green / 255, 2.2);
        blended[2] += Math.pow(c.blue / 255, 2.2);
      }
      this.startTime = start;
      this.endTime = end;
      this.startPercent = time2Percent(start);
      this.endPercent = time2Percent(end);
      this.color = `#ff${
        Math.round(Math.pow(blended[0] / this.lesson.length, 1/2.2) * 255).toString(16).padStart(2, "0")
      }${
        Math.round(Math.pow(blended[1] / this.lesson.length, 1/2.2) * 255).toString(16).padStart(2, "0")
      }${
        Math.round(Math.pow(blended[2] / this.lesson.length, 1/2.2) * 255).toString(16).padStart(2, "0")
      }`;
    } else {
      this.weekday = this.lesson.weekday;
      this.startPercent = time2Percent(this.lesson.start);
      this.endPercent = time2Percent(this.lesson.end);
      this.color = this.lesson.color ?? "#FFFFFF";
    }
  }

  build() {
    Column() {
      if(Array.isArray(this.lesson)) {
        Text($r("app.string.overlapped"))
          .height("100%")
          .fontColor($r("sys.color.black"))
          .fontWeight(FontWeight.Bold)
          .fontSize(13)
          .textAlign(TextAlign.Center)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .onClick(() => { this.showOverlappedPopup = true; })
          .bindPopup($$this.showOverlappedPopup, {
            builder: this.overlappedPopup,
            placement: Placement.Right,
            enableArrow: true,
            radius: 17,
            onStateChange: (e) => {
              if(!e.isVisible) {
                this.showOverlappedPopup = false;
              }
            }
          });
      } else {
        LessonContent({
          lesson: this.lesson,
          parentHeight: this.parentHeight,
          startPercent: this.startPercent,
          endPercent: this.endPercent,
        })
      }
    }
    .size({ width: "14.29%", height: `${(this.endPercent - this.startPercent)}%` })
    .position({ left: `${(this.weekday * 100 / 7)}%`, top: `${this.startPercent}%` })
    .justifyContent(FlexAlign.Center)
    .clip(true)
    .backgroundColor(this.color)
    .padding(2)
    .borderRadius(12)
  }

  @Builder
  overlappedPopup() {
    Stack() {
      ForEach(this.lesson as LessonInfo[], (lesson: LessonInfo, index) => {
        LessonContent({
          lesson: lesson,
          parentHeight: this.parentHeight * (this.endPercent - this.startPercent) / 100 + 10,
          startPercent: 0,
          endPercent: 100,
        })
          .size({
            width: `${100 / (this.lesson as LessonInfo[]).length}%`,
            height: `${time2Percent(lesson.end, this.startTime, this.endTime) - time2Percent(lesson.start, this.startTime, this.endTime)}%`
          })
          .position({
            left: `${index * 100 / (this.lesson as LessonInfo[]).length}%`,
            top: `${time2Percent(lesson.start, this.startTime, this.endTime)}%`
          })
      })
    }
    .padding(5)
    .size({
      width: (this.lesson as LessonInfo[]).length * 60 + 10,
      height: this.parentHeight * (this.endPercent - this.startPercent) / 100 + 10
    })
  }
}

@Component
struct LessonContent {
  @Require lesson: LessonInfo;
  @Require parentHeight: number;
  @Require startPercent: number;
  @Require endPercent: number;

  @State showLessonDetail: boolean= false;

  maxLines() {
    return Math.floor((this.parentHeight * (this.endPercent - this.startPercent) / 100  - 50) / 16);
  }

  build() {
    Column({ space: 5 }) {
      Text(this.lesson.courseName)
        .fontColor($r("sys.color.black"))
        .fontWeight(FontWeight.Bold)
        .fontSize(13)
        .textAlign(TextAlign.Center)
        .maxLines(this.maxLines())
        .textOverflow({
          overflow: this.maxLines() === 1 ? TextOverflow.MARQUEE : TextOverflow.Ellipsis,
        });

      Text(this.lesson.place)
        .fontColor($r("sys.color.black"))
        .fontSize(9)
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis });

      Text(this.lesson.teachers.join("，"))
        .fontColor($r("sys.color.black"))
        .fontSize(9)
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis });
    }
    .size({ width: "100%", height: "100%" })
    .justifyContent(FlexAlign.Center)
    .clip(true)
    .backgroundColor(this.lesson.color ?? "#FFFFFF")
    .padding(2)
    .borderRadius(12)
    .onClick(() => {
      this.showLessonDetail = true;
    })
    .bindSheet($$this.showLessonDetail, this.lessonDetailDialog(this.lesson), {
      detents: [SheetSize.MEDIUM, SheetSize.LARGE],
      preferType: SheetType.CENTER,
      showClose: false,
      scrollSizeMode: ScrollSizeMode.CONTINUOUS,
      backgroundColor: '#00d00721',
      blurStyle: BlurStyle.Regular,
      onAppear: () => {
        // this.showColorHint = UnifiedPreferences.getBoolSync('ShowColorHint', true);
      },
      onWillDismiss: dismiss => {
        // this.classInfo.weekOfTerm = [...this.weekOfTerm];
        // if (this.rectifyTimeSpan[0] > this.rectifyTimeSpan[1]) {
        //   let swapTemp = this.rectifyTimeSpan[0];
        //   this.rectifyTimeSpan[0] = this.rectifyTimeSpan[1];
        //   this.rectifyTimeSpan[1] = swapTemp;
        // }
        // this.classInfo.timeSpan = tools.getContArray([this.rectifyTimeSpan]) as number[];
        // if (!areClassAttributesEqual(this.oriClassInfo, this.classInfo)) {
        //   this.msgDialogController = new CustomDialogController({
        //     builder: MessageDialog({
        //       mainTitle: $r('app.string.unsaved_change'),
        //       message: $r('app.string.back_to_schedule_or_not'),
        //       onConfirm: () => dismiss.dismiss()
        //     }),
        //     autoCancel: true,
        //     gridCount: 4
        //   });
        //   this.msgDialogController.open();
        // } else {
        dismiss.dismiss();
        // }
      }
    })
  }

  @Builder
  lessonDetailDialog(lesson: LessonInfo) {
    LessonDetail({ lesson: lesson })
  }
}