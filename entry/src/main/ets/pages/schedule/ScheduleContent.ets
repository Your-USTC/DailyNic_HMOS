import { LessonInfo } from "../../utils/ScheduleData";
import dayjs from "dayjs";
import { commonClassTime } from "../../constants/ScheduleSources";
import { LessonCard } from "./LessonCard";
import { time2Percent, time2Seconds } from "../../utils/tools";
import { RectShape } from "@kit.ArkUI";
import { LessonDetail } from "./LessonDetail";

@Component
export struct ScheduleContent {
  initialized: boolean = false;

  @Require @Prop
  lessons: Array<LessonInfo | LessonInfo[]>;

  @State hideTime: boolean = false;
  @State contentHeight: number = 0;
  baseContentHeight: number = 0;
  minHeight: number = 0;

  @State timeLineY: number = 0;

  @State showLessonDetail: boolean = false;

  aboutToAppear(): void {
    setInterval(() => {
      this.getUIContext().animateTo({ duration: 1000, curve: Curve.EaseOut }, () => {
        this.timeLineY = this.contentHeight * time2Percent(time2Seconds(dayjs().format("HH:mm"))) / 100;
      });
    }, 60000); // 一分钟更新一次
  }

  build() {
    Column() {
      Row() {
        Text($r("app.string.class_span"))
          .fontSize(14)
          .layoutWeight(1)
          .height("100%")
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .background($r("app.color.grid_background"))
          .border({
            width: { right: 1, bottom: 1 },
            color: $r("app.color.grid_border"),
          });

        ForEach(dayjs.weekdays(), (day: string) => {
          Text($r(`app.string.${day}`))
            .fontSize(14)
            .layoutWeight(1)
            .height("100%")
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
            .background($r("app.color.grid_background"))
            .border({
              width: { right: 1, bottom: 1 },
              color: $r("app.color.grid_border"),
            });
        });
      }
      .size({ width: "100%", height: 25 });

      Scroll() {
        Row() {
          Column() {
            Text($r("app.string.morning"))
              .fontWeight(FontWeight.Bold)
              .fontSize(14)
              .layoutWeight(5)
              .width("100%")
              .textAlign(TextAlign.Center)
              .background($r("app.color.grid_background"))
              .border({
                width: { right: 1, bottom: 1 },
                color: $r("app.color.grid_border"),
              });

            Text($r("app.string.afternoon"))
              .fontWeight(FontWeight.Bold)
              .fontSize(14)
              .layoutWeight(5)
              .width("100%")
              .textAlign(TextAlign.Center)
              .background($r("app.color.grid_background"))
              .border({
                width: { right: 1, bottom: 1 },
                color: $r("app.color.grid_border"),
              });

            Text($r("app.string.evening"))
              .fontWeight(FontWeight.Bold)
              .fontSize(14)
              .layoutWeight(4)
              .width("100%")
              .textAlign(TextAlign.Center)
              .background($r("app.color.grid_background"))
              .border({
                width: { right: 1, bottom: 1 },
                color: $r("app.color.grid_border"),
              });
          }
          .height("100%")
          .layoutWeight(1);

          Column() {
            ForEach(commonClassTime.slice(1), (time: [string, string], index) => {
              Column() {
                Text(time[0])
                  .fontSize("8fp")
                  .visibility(this.hideTime ? Visibility.None : Visibility.Visible);

                // 把18:40到19:25单独空出来
                if(index !== 10) {
                  Text((index < 10 ? index + 1 : index).toString())
                    .fontWeight(FontWeight.Bold)
                    .fontSize(14)
                    .align(Alignment.Center);
                }

                Text(time[1])
                  .fontSize("8fp")
                  .visibility(this.hideTime ? Visibility.None : Visibility.Visible);
              }
              .clip(true)
              .size({ width: "100%", height: "100%" })
              .layoutWeight(1)
              .justifyContent(FlexAlign.SpaceBetween)
              .background($r("app.color.grid_background"))
              .padding({ top: 2, bottom: 2 })
              .border({
                width: { right: 1, bottom: 1 },
                color: $r("app.color.grid_border"),
              });
            });
          }
          .height("100%")
          .layoutWeight(1);

          Stack() {
            ForEach(this.lessons, (lesson: LessonInfo | LessonInfo[]) => {
              LessonCard({
                lesson: lesson,
                parentHeight: this.contentHeight,
              })
            })

            Row()
              .size({ width: "100%", height: 0.5 })
              .backgroundColor(Color.Red)
              .position({ x: 0, y: this.timeLineY })
          }
          .size({ width: "100%", height: "100%" })
          .layoutWeight(14)
        }
        .size({ width: "100%", height: this.contentHeight })
        .gesture(
          PinchGesture()
            .onActionStart(() => {
              this.baseContentHeight = this.contentHeight;
            })
            .onActionUpdate(e => {
              const h = this.baseContentHeight * e.scale;
              this.contentHeight = Math.max(this.minHeight, h);
              this.timeLineY = this.contentHeight * time2Percent(time2Seconds(dayjs().format("HH:mm"))) / 100;
            }),
        );
      }
      .size({ width: "100%", height: "100%" })
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Auto)
      .onAreaChange((_, newArea) => {
        if(!this.initialized) {
          this.contentHeight = newArea.height as number;
          this.minHeight = this.contentHeight;
          this.timeLineY = this.contentHeight * time2Percent(time2Seconds(dayjs().format("HH:mm"))) / 100;
          this.initialized = true;
        }
      })
    }
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }
}