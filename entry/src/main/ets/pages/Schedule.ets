
import { PopoverDialog, Popup } from '@kit.ArkUI';
import * as ScheduleSources from '../constants/ScheduleSources';
import { classAttribute, semesterAttribute, exportSemester, exportedData } from '../constants/ScheduleSources';
import * as tools from '../utils/tools';
import { handleOverlappedLessons, weekTranslate } from '../utils/tools';
import UnifiedPreferences, { millisecondsPerWeek } from '../utils/UnifyPreference';
import BackgroundImage, { presetColor } from '../utils/BgImageManager';
import RenameDialog from '../view/RenameDialog';
import { JSON } from '@kit.ArkTS';
import { currentScheduleVersion, FULL_TIME_FORMAT } from '../constants/BasicConstants';
import MessageDialog from '../view/MessageDialog';
import { jwClient } from "../utils/clients/JWClient";
import { catalogClient } from "../utils/clients/CatalogClient";
import { LessonInfo, SemesterInfo } from "../utils/ScheduleData";
import dayjs from "dayjs";
import { scheduleManager } from "../utils/storage/ScheduleManager";
import { ScheduleContent } from "./schedule/ScheduleContent";

@Builder
export function ScheduleBuilder() {
  Schedule()
  // if (param)
  //   Schedule({ gridHeight: param, maxLinesH: Math.max(1, (param / 13 - classAndTeacher) / font13fpHeight) });
  // else
  //   Schedule({ gridHeight: UnifiedPreferences.getNumberSync('GridHeight', 500) })
}

function isIncludingToday(semester: SemesterInfo | undefined, week: number) {
  return semester !== undefined && dayjs().utcOffset(0, true)
    .isBetween(
      dayjs.utc(semester.start).weekday(0).add(week - 1, "week"),
      dayjs.utc(semester.start).weekday(6).add(week - 1, "week"),
      "day", "[]"
    );
}

function displayWeekString(semester: SemesterInfo | undefined, week: number) {
  return semester === undefined ? "" : `${
    dayjs.utc(semester.start).weekday(0).add(week - 1, "week").format("YYYY/MM/DD")
  } ~ ${
    dayjs.utc(semester.start).weekday(6).add(week - 1, "week").format("YYYY/MM/DD")
  }`
}

@Entry
@Component
struct Schedule {
  @State ready: boolean = false;

  initGridHeight: number = 0;
  @State gridHeight: number = 0; // 课表grid高度
  @State hideTime: boolean = false;
  gridMinHeight: number = 0;
  @State maxLinesH: number = 1; // H意为height

  @State displaySemester?: SemesterInfo = undefined;
  @State weekSchedule: Array<LessonInfo | LessonInfo[]> = [];
  @State displayWeek: number = 0;
  maxWeek: number = 0;

  async aboutToAppear() {
    this.ready = false;
    const semester = await jwClient.inSemester();
    if(semester === undefined) {
      return;
    }
    await this.changeSemester(semester);
    this.ready = true;
  }

  async changeSemester(semester: SemesterInfo) {
    this.ready = false;
    this.displaySemester = semester;
    this.displayWeek = 1;
    this.maxWeek = dayjs(semester.end).diff(dayjs(semester.start), "week") + 1;
    this.weekSchedule = handleOverlappedLessons(await scheduleManager.getSchedule(semester.id, 1));
    this.ready = true;
  }

  msgDialogController?: CustomDialogController;
  @State showXiuHint: boolean = false;
  @Builder xiuHintPopup() {
    Row() {
      Popup({
        icon: { image: $r('app.media.lightbulb') },
        message: { text: $r('app.string.back_to_current_week') },
        showClose: false,
        buttons: [{
          text: $r('app.string.next_hint'),
          action: () => {
            this.showXiuHint = false;
            this.showPinchHint = true;
          }
        }]
      })}
  }
  @State showPinchHint: boolean = false;
  @Builder pinchHintPopup() {
    Row() {
      Popup({
        icon: { image: $r('app.media.lightbulb') },
        message: { text: $r('app.string.pinch_to_scale') },
        showClose: false,
        buttons: [{
          text: $r('app.string.no_reminding'),
          action: () => {
            UnifiedPreferences.putSync('ShowPinchHint', false);
            this.showPinchHint = false;
          }
        }]
      })
    }
  }
  @State showColorHint: boolean = false;
  @Builder colorHintPopup() {
    Row() {
      Popup({
        icon: { image: $r('app.media.lightbulb') },
        message: { text: $r('app.string.more_color_option') },
        showClose: false,
        buttons: [{
          text: $r('app.string.next_hint'),
          action: () => {
            this.showColorHint = false;
            this.showScrollHint = true;
          }
        }]
      })
    }
  }
  @State showScrollHint: boolean = false;
  @Builder scrollHintPopup() {
    Row() {
      Popup({
        icon: { image: $r('app.media.lightbulb') },
        message: { text: $r('app.string.change_detail_size') },
        showClose: false,
        buttons: [{
          text: $r('app.string.no_reminding'),
          action: () => {
            UnifiedPreferences.putSync('ShowColorHint', false);
            this.showScrollHint = false;
          }
        }]
      })
    }
  }


  /**
   * 详情弹窗部分
   */
  @State showSheet: boolean = false;

  @State isWeeksLegal: boolean = true;
  @State weekOfTerm: number[] = tools.getContArray([[2, 4], [6, 10], [14, 16]]) as number[];
  @State isColorLegal: boolean = true;
  private changeAllColor: boolean = true;

  private colorARGB: number[] = [255, 255, 199, 205];
  @State classColor: string = '#FFC7CD';
  @State showColorPicker: boolean = false;
  @State colorDialogText: string = '#FFC7CD';
  @Builder colorPicker() {
    Column() {
      Text(this.colorDialogText)
        .fontColor('#000000')
        .backgroundColor(this.colorDialogText)
        .textAlign(TextAlign.Center)
        .height(24)
        .width(110)
        .borderRadius(12)

      Row() {
        Text($r('app.string.transparent'))
        Slider({
          value: this.colorARGB[0],
          min: 0,
          max: 255,
          style: SliderStyle.InSet
        })
          .layoutWeight(1)
          .selectedColor($r('app.color.transparent'))
          .trackColor(new LinearGradient([
            { color: `#00${this.colorDialogText.slice(3, 9)}`, offset: 0 },
            { color: `#FF${this.colorDialogText.slice(3, 9)}`, offset: 1 }
          ]))
          .onChange((value: number) => {
            this.colorARGB[0] = value;
            this.colorDialogText = '#' + this.colorARGB[0].toString(16).padStart(2, '0').toUpperCase()
              + this.colorARGB[1].toString(16).padStart(2, '0').toUpperCase()
              + this.colorARGB[2].toString(16).padStart(2, '0').toUpperCase()
              + this.colorARGB[3].toString(16).padStart(2, '0').toUpperCase();
          });
      }

      Row() {
        Text($r('app.string.red'))
        Slider({
          value: this.colorARGB[1],
          min: 0,
          max: 255,
          style: SliderStyle.InSet
        })
          .layoutWeight(1)
          .selectedColor($r('app.color.transparent'))
          .trackColor(new LinearGradient([
            { color: `#00${this.colorDialogText.slice(5, 9)}`, offset: 0 },
            { color: `#FF${this.colorDialogText.slice(5, 9)}`, offset: 1 }]))
          .onChange((value: number) => {
            this.colorARGB[1] = value;
            this.colorDialogText = '#' + this.colorARGB[0].toString(16).padStart(2, '0').toUpperCase()
              + this.colorARGB[1].toString(16).padStart(2, '0').toUpperCase()
              + this.colorARGB[2].toString(16).padStart(2, '0').toUpperCase()
              + this.colorARGB[3].toString(16).padStart(2, '0').toUpperCase();
          });
      }

      Row() {
        Text($r('app.string.green'))
        Slider({
          value: this.colorARGB[2],
          min: 0,
          max: 255,
          style: SliderStyle.InSet
        })
          .layoutWeight(1)
          .selectedColor($r('app.color.transparent'))
          .trackColor(new LinearGradient([
            { color: `#${this.colorDialogText.slice(3, 5)}00${this.colorDialogText.slice(7, 9)}`, offset: 0 },
            { color: `#${this.colorDialogText.slice(3, 5)}FF${this.colorDialogText.slice(7, 9)}`, offset: 1 }]))
          .onChange((value: number) => {
            this.colorARGB[2] = value;
            this.colorDialogText = '#' + this.colorARGB[0].toString(16).padStart(2, '0').toUpperCase()
              + this.colorARGB[1].toString(16).padStart(2, '0').toUpperCase()
              + this.colorARGB[2].toString(16).padStart(2, '0').toUpperCase()
              + this.colorARGB[3].toString(16).padStart(2, '0').toUpperCase();
          });
      }

      Row() {
        Text($r('app.string.blue'))
        Slider({
          value: this.colorARGB[3],
          min: 0,
          max: 255,
          style: SliderStyle.InSet
        })
          .layoutWeight(1)
          .selectedColor($r('app.color.transparent'))
          .trackColor(new LinearGradient([
            { color: `#${this.colorDialogText.slice(3, 7)}00`, offset: 0 },
            { color: `#${this.colorDialogText.slice(3, 7)}FF`, offset: 1 }]))
          .onChange((value: number) => {
            this.colorARGB[3] = value;
            this.colorDialogText = '#' + this.colorARGB[0].toString(16).padStart(2, '0').toUpperCase()
              + this.colorARGB[1].toString(16).padStart(2, '0').toUpperCase()
              + this.colorARGB[2].toString(16).padStart(2, '0').toUpperCase()
              + this.colorARGB[3].toString(16).padStart(2, '0').toUpperCase();
          });
      }

      Row() {
        Toggle( { isOn: this.changeAllColor, type: ToggleType.Checkbox })
          .onChange((value: boolean) => {
            this.changeAllColor = value;
          });
        Text($r('app.string.change_all_color'))
      }
    }
    .padding(16)
    .width('100%')
    // .height(250)
    .justifyContent(FlexAlign.Center)
  }


  /**
   * 菜单部分
   */
  @State showSemesterSelector: boolean = false;
  @State semesters: SemesterInfo[] = [];
  @Builder editMenu() {
    Menu() {
      MenuItem({ content: $r('app.string.class_detail_new'), startIcon: $r('app.media.plus_square') })
        .onClick(() => {
          // TODO
        });
      MenuItem({ content: $r('app.string.online_schedule'), startIcon: $r('app.media.cloud_download')})
        .onClick(async() => {
          if(this.displaySemester) {
            await scheduleManager.deleteSchedule(this.displaySemester.id);
            this.ready = false;
            this.weekSchedule = handleOverlappedLessons(
              await scheduleManager.getSchedule(this.displaySemester.id, this.displayWeek)
            );
            this.ready = true;
          } else {
            this.semesters = (await catalogClient.getSemesters())
              .sort((a, b) => b.start.localeCompare(a.start));
            this.showSemesterSelector = true;
          }
        })
      MenuItem({ content: $r('app.string.search_in_all_courses'), startIcon: $r('app.media.search') })
        .onClick(() => {
          this.pathStack.pushPath({ name: 'GetClassByName' })
        });
      // MenuItem({ startIcon: $r('app.media.archive'), content: "导入和导出", builder: this.archiveMenu() })
    }
    .subMenuExpandingMode(SubMenuExpandingMode.STACK_EXPAND)
  }

  @Builder SemesterSelector() {
    Column() {
      Row() {
        Text($r('app.string.select_semesters'))
          .fontWeight(FontWeight.Bold)
          .fontSize(20)
          .width("100%")
          .layoutWeight(1)
          .margin({ left: 8 })

        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.refresh'))
            .height(24)
            .width(24)
            .draggable(false)
        }
        .width(42)
        .height(42)
        .margin({ right: 8 })
        .onClick(async() => {
          this.semesters = (await catalogClient.getSemesters(true))
            .sort((a, b) => b.start.localeCompare(a.start));
        })

        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.close'))
            .size({ width: 24, height: 24})
            .draggable(false)
        }
        .size({ width: 42, height: 42})
        .onClick(() => {
          this.showSemesterSelector = false;
        })
      }
      .margin({ bottom: 5 })

      List({ space: 14 }) {
        ForEach(this.semesters, (s: SemesterInfo) => {
          ListItem() {
            Column({ space: 4 }) {
              Text(s.nameZh)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .textAlign(TextAlign.Center)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.MARQUEE })

              Row({ space: 4 }) {
                Image($r("app.media.calendar"))
                  .width(18)
                Column() {
                  Text(s.start)
                    .fontSize(8)
                    .textAlign(TextAlign.Start)
                  Text(s.end)
                    .fontSize(8)
                    .textAlign(TextAlign.Start)
                }
              }
              .alignSelf(ItemAlign.Start)
              .margin({ left: 20 })
            }
            .width("100%")
            .padding({ top: 5, bottom: 5 })
            .borderRadius(20)
            .backgroundColor($r("sys.color.comp_background_list_card"))
          }
          .width("100%")
          .transition(
            TransitionEffect.move(TransitionEdge.BOTTOM).animation({ duration: 600, curve: Curve.Ease })
          )
          .onClick(() => {
            this.changeSemester(s);
            this.showSemesterSelector = false;
          })
        })
      }
      .lanes(2, 10)
      .size({ width: "100%", height: "100%" })
      .layoutWeight(1)
      .borderRadius(20)
    }
    .padding(16)
  }

  // @Builder archiveMenu() {
  //   Menu() {
  //     MenuItem({ content: $r('app.string.import_schedule'), startIcon: $r('app.media.import') })
  //       .onClick(() => {
  //         tools.readStringFromFile(this.getUIContext(), '数据交换格式|.json').then(result => {
  //           if (result === 'null') {
  //             this.getUIContext().getPromptAction().showToast({ message: $r('app.string.read_file_cancel') });
  //           } else {
  //             try {
  //               console.log('1!!!');
  //               console.log('!!!' + result);
  //               const rawImportedData = JSON.parse(result) as exportedData;
  //               const checkResult = ScheduleSources.validateExportedData(rawImportedData);
  //               if (checkResult === '') {
  //                 const oldNum: number = ScheduleManager.semesters.length;
  //                 let currentTime = Date.now();
  //                 rawImportedData.semesters.forEach(importSemester => {
  //                   ScheduleManager.newSemester(importSemester.attribute.name, importSemester.attribute.source, importSemester.attribute.beginTime, ++currentTime, importSemester.attribute.totalWeekNum, importSemester.courses);
  //                 })
  //                 if (rawImportedData.semesters.length > 0) {
  //                   ScheduleManager.switchTempSemester(oldNum + rawImportedData.defaultSemester);
  //                   this.initSchedule();
  //                 }
  //                 this.showSemesters = true;
  //                 this.getUIContext().getPromptAction().showToast({ message: '导入成功' });
  //               } else {
  //                 this.getUIContext().getPromptAction().showToast({ message: checkResult });
  //               }
  //             } catch(error) {
  //               console.log('!!!' + JSON.stringify(error));
  //               this.getUIContext().getPromptAction().showToast({ message: $r('app.string.read_file_format_error') });
  //             }
  //           }
  //         });
  //       });
  //
  //     MenuItem({ content: $r('app.string.export_schedule'), startIcon: $r('app.media.export') })
  //       .onClick(() => {
  //         const saveTime: number = Math.trunc(Date.now() / 1000);
  //         let userContent: exportedData = {
  //           exportTime: saveTime,
  //           scheduleVersion: currentScheduleVersion,
  //           defaultSemester: ScheduleManager.defaultSemester,
  //           semesters: Array.from(ScheduleManager.semesters, (semester) => {
  //             return {
  //               attribute: semester,
  //               courses: JSON.parse(UnifiedPreferences.getSync('SemesterDataAt' + String(semester.createTime), '[]'))
  //             } as exportSemester;
  //           })
  //         };
  //
  //         tools.saveStringToFile(this.getUIContext(), "DailyNicSchedule_" + String(saveTime) + ".json", '数据交换格式|.json', JSON.stringify(userContent));
  //       });
  //   }
  // }

  /**
   * 切换学期弹窗
   */
  @State showSemesters: boolean = false;
  @State localSemesters: SemesterInfo[] = [];
  @Builder SemesterDetail() {
    Column() {
      Row() {
        Column() {
          Text($r('app.string.all_semesters'))
            .fontWeight(FontWeight.Bold)
            .fontSize(20)
            .width('100%')
        }
        .layoutWeight(1)
        .margin({ left: 8 });

        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.plus_square'))
            .height(24)
            .width(24)
            .draggable(false)
        }
        .width(42)
        .height(42)
        .margin({ right: 8 })
        .onClick(async() => {
          this.showSemesters = false;
          this.semesters = (await catalogClient.getSemesters())
            .sort((a, b) => b.start.localeCompare(a.start));
          this.showSemesterSelector = true;
        })

        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.close'))
            .height(24)
            .width(24)
            .draggable(false)
        }
        .width(42)
        .height(42)
        .onClick(() => { this.showSemesters = false; })
      }
      .margin({ bottom: 5 })

      List({ space: 14 }) {
        ForEach(this.localSemesters, (semester: SemesterInfo) => {
          ListItem() {
            Column({ space: 4 }) {
              Row({ space: 5 }) {
                Text(semester.nameZh)
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .margin({ left: 10 })
                  .layoutWeight(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.MARQUEE })

                Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
                  Image($r('app.media.trash_red'))
                    .height(22)
                    .width(22)
                }
                .height(40)
                .width(40)
                .enabled(this.displaySemester?.id === semester.id)
                .onClick(() => {
                  // this.msgDialogController = new CustomDialogController({
                  //   builder: MessageDialog({
                  //     message: $r('app.string.delete_semester_or_not'),
                  //     onConfirm: () => {
                  //       ScheduleManager.deleteSemester(index);
                  //       this.displayTerm = ScheduleManager.displaySemester;
                  //       this.defaultSemester = ScheduleManager.defaultSemester;
                  //       this.semesters = ScheduleManager.semesters;
                  //     }
                  //   }),
                  //   autoCancel: true,
                  //   gridCount: 4
                  // });
                  // this.msgDialogController.open();
                })
              }

              Row() {
                Text($r('app.string.all_semesters_start_date'))
                Button(semester.start)
                  .buttonStyle(ButtonStyleMode.NORMAL)
                  .height(30)
                  .borderRadius(15)
                  .fontColor(presetColor[BackgroundImage.themeColor][2])
              }
              .margin({ left: 15 })

              Text($r('app.string.all_semesters_total_week', dayjs(semester.end).diff(semester.start, "week") + 1))
                .margin({ left: 15 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .padding(this.displaySemester?.id === semester.id ? 7 : 10)
            .borderRadius(20)
            .borderColor(this.displaySemester?.id === semester.id ? presetColor[BackgroundImage.themeColor][2] : undefined)
            .borderWidth(this.displaySemester?.id === semester.id ? 3 : undefined)
            .backgroundColor($r('app.color.grid_background'))
            .onClick(() => { this.changeSemester(semester); })
          }
          .width('100%')
          .transition(TransitionEffect.move(TransitionEdge.BOTTOM).animation({ duration: 600, curve: Curve.Ease }))
        });
      }
      .size({ width: "100%", height: "100%"})
      .layoutWeight(1)
      .borderRadius(20)
    }
    .size({ width: "100%", height: "100%"})
    .padding(16)
  }

  pathStack: NavPathStack = new NavPathStack();
  build() {
    NavDestination() {
      ScheduleContent({
        lessons: this.weekSchedule,
      })
    }
    .backgroundColor(BackgroundImage.showImage ? '#00d00721' : $r('app.color.normal_background'))
    .hideBackButton(true)
    .title({ builder: this.customTitle, height: 73 }, {
      backgroundBlurStyle: BackgroundImage.blurLevel,
      backgroundColor: (BackgroundImage.blurLevel === undefined ? $r('app.color.shaded_background' + String(BackgroundImage.themeColor)) : '#00d00721')
    })
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
      // setTimeout(() => this.showXiuHint = UnifiedPreferences.getBoolSync('ShowPinchHint', true), 0);
    });
  }

  @Builder customTitle() {
    Column() {
      Row({ space: 6 }) { // 上边距3，高度40
        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.close'))
            .height(22)
            .draggable(false)
        }
        .height(40)
        .width(40)
        .onClick(() => {
          this.pathStack.pop();
        })

        Column() {
          Text(this.displaySemester?.nameZh ?? $r("app.string.none"))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .maxLines(1)
            .margin({ bottom: 1 })
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text($r('app.string.local_schedule_daily_nic'))
            .fontSize(12)
            .fontColor($r('app.color.transparent_text'))
            .width('100%')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)

        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.calendar'))
            .height(22)
            .draggable(false)
        }
        .width(40)
        .height(40)
        .onClick(() => {
          scheduleManager.getStoredSemesters()
            .then(val => {
              this.localSemesters = val;
              this.localSemesters.sort((a, b) => b.start.localeCompare(a.start));
              this.showSemesters = true;
            })
        })
        .bindSheet($$this.showSemesters, this.SemesterDetail, {
          // 如果与 gridItem 绑定，会弹出很多个！
          detents: [SheetSize.LARGE, SheetSize.MEDIUM],
          preferType: SheetType.CENTER,
          showClose: false,
          scrollSizeMode: ScrollSizeMode.FOLLOW_DETENT,
          backgroundColor: '#00d00721',
          blurStyle: BlurStyle.Regular
        })

        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.get'))
            .height(22)
            .draggable(false)
        }
        .width(40)
        .height(40)
        .bindMenu(this.editMenu())
        .bindSheet($$this.showSemesterSelector, this.SemesterSelector, {
          detents: [SheetSize.LARGE, SheetSize.MEDIUM],
          preferType: SheetType.CENTER,
          showClose: false,
          scrollSizeMode: ScrollSizeMode.FOLLOW_DETENT,
          backgroundColor: '#00d00721',
          blurStyle: BlurStyle.Regular
        })
      }
      .padding({ left: 12, right: 12, top: 3 })
      .width('100%')

      /**
       * 周数信息与翻页
       */
      Row() { // 高度30
        Text(displayWeekString(this.displaySemester, this.displayWeek) ?? "")
          .id('week_of_term_span')
          .fontWeight(FontWeight.Bold)
          .fontSize(14)
          .onClick(() => {
            CalendarPickerDialog.show({
              selected: new Date(
                dayjs(this.displaySemester!.start).weekday(0).add(this.displayWeek - 1, "week").valueOf()
              ),
              start: new Date(this.displaySemester!.start),
              end: new Date(this.displaySemester!.end),
              onAccept: async(value) => {
                this.ready = false;
                this.displayWeek = dayjs(value).diff(this.displaySemester!.start, "week") + 1;
                this.weekSchedule = handleOverlappedLessons(
                  await scheduleManager.getSchedule(this.displaySemester!.id, this.displayWeek)
                );
                this.ready = true;
              }
            })
          })

        Blank()

        Image($r('app.media.arrow_left_circle'))
          .height(18)
          .padding({ left: 20, right: 20 })
          .draggable(false)
          .opacity(this.displayWeek > 1 && this.ready ? 1 : 0.4)
          .enabled(this.displayWeek > 1 && this.ready)
          .onClick(async() => {
            this.ready = false;
            this.displayWeek--;
            this.weekSchedule = handleOverlappedLessons(
              await scheduleManager.getSchedule(this.displaySemester!.id, this.displayWeek)
            );
            this.ready = true;
          })

        Text(this.displaySemester ? $r('app.string.week_of_term_no_d', this.displayWeek) : "")
          .id('week_of_term_no')
          .fontWeight(FontWeight.Bold)
          .fontSize(14)
          .enabled(this.displaySemester !== undefined)
          .onClick(() => {
            this.getUIContext().showTextPickerDialog({
              range: tools.getContArray([[1, this.maxWeek]], true) as string[],
              selected: this.displayWeek - 1,
              canLoop: false,
              onAccept: async(value) => {
                this.ready = false;
                this.displayWeek = Number(value.value);
                this.weekSchedule = handleOverlappedLessons(
                  await scheduleManager.getSchedule(this.displaySemester!.id, this.displayWeek)
                );
                this.ready = true;
              }
            });
          })

        Image($r('app.media.arrow_right_circle'))
          .height(18)
          .padding({ left: 20, right: 20 })
          .objectFit(ImageFit.Contain)
          .draggable(false)
          .opacity(this.displayWeek < this.maxWeek && this.ready ? 1 : 0.4)
          .enabled(this.displayWeek < this.maxWeek && this.ready)
          .onClick(async() => {
            this.ready = false;
            this.displayWeek++;
            this.weekSchedule = handleOverlappedLessons(
              await scheduleManager.getSchedule(this.displaySemester!.id, this.displayWeek)
            );
            this.ready = true;
          })
      }
      .width('100%')
      .height(30)
      .padding({ left: 15, right: 5 })
    }
    .height(70)
    .width('100%')
  }


  // @Builder ClassDetailDialog() {
  //   Column() {
  //     Row({ space: 6 }) {
  //       Text(this.isChangeSchedule ? $r('app.string.class_detail') : $r('app.string.class_detail_new'))
  //         .fontWeight(FontWeight.Bold)
  //         .fontSize(24)
  //         .layoutWeight(1)
  //         .margin({ left: 8 })
  //
  //       if (this.isChangeSchedule) {
  //         Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
  //           Image($r('app.media.trash_red'))
  //             .height(24)
  //             .width(24)
  //         }
  //         .width(42)
  //         .height(42)
  //         .onClick(() => {
  //           this.msgDialogController = new CustomDialogController({
  //             builder: MessageDialog({
  //               message: $r('app.string.delete_class_or_not'),
  //               onConfirm: () => {
  //                 ScheduleManager.deleteClassFromSemester(this.displayTerm, this.oriClassInfo);
  //                 this.refreshGrid();
  //                 this.showSheet = false;
  //               }
  //             }),
  //             autoCancel: true,
  //             gridCount: 4
  //           });
  //           this.msgDialogController.open();
  //         })
  //
  //         Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
  //           Image($r('app.media.copy'))
  //             .height(24)
  //             .width(24)
  //         }
  //         .enabled(this.isWeeksLegal && this.isColorLegal)
  //         .width(42)
  //         .height(42)
  //         .onClick(() => {
  //           this.classInfo.weekOfTerm = [...this.weekOfTerm];
  //           if (this.rectifyTimeSpan[0] > this.rectifyTimeSpan[1]) {
  //             let swapTemp = this.rectifyTimeSpan[0];
  //             this.rectifyTimeSpan[0] = this.rectifyTimeSpan[1];
  //             this.rectifyTimeSpan[1] = swapTemp;
  //           }
  //           this.classInfo.timeSpan = tools.getContArray([this.rectifyTimeSpan]) as number[];
  //           ScheduleManager.addClassToSemester(this.displayTerm, this.classInfo, this.changeAllColor);
  //           this.refreshGrid();
  //           this.showSheet = false;
  //         })
  //       }
  //
  //       Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
  //         Image($r('app.media.close'))
  //           .height(24)
  //           .width(24)
  //       }
  //       .width(42)
  //       .height(42)
  //       .onClick(() => {
  //         this.classInfo.weekOfTerm = [...this.weekOfTerm];
  //         if (this.rectifyTimeSpan[0] > this.rectifyTimeSpan[1]) {
  //           let swapTemp = this.rectifyTimeSpan[0];
  //           this.rectifyTimeSpan[0] = this.rectifyTimeSpan[1];
  //           this.rectifyTimeSpan[1] = swapTemp;
  //         }
  //         this.classInfo.timeSpan = tools.getContArray([this.rectifyTimeSpan]) as number[];
  //         if (!areClassAttributesEqual(this.oriClassInfo, this.classInfo)) {
  //           this.msgDialogController = new CustomDialogController({
  //             builder: MessageDialog({
  //               mainTitle: $r('app.string.unsaved_change'),
  //               message: $r('app.string.back_to_schedule_or_not'),
  //               onConfirm: () => {
  //                 this.showSheet = false;
  //               }
  //             }),
  //             autoCancel: true,
  //             gridCount: 4
  //           });
  //           this.msgDialogController.open();
  //         } else {
  //           this.showSheet = false;
  //         }
  //       })
  //
  //       Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
  //         Image(this.isChangeSchedule ? $r('app.media.save') : $r('app.media.checkmark'))
  //           .height(24)
  //           .width(24)
  //       }
  //       .width(42)
  //       .height(42)
  //       .enabled(this.isWeeksLegal && this.isColorLegal)
  //       .onClick(() => {
  //         this.classInfo.weekOfTerm = [...this.weekOfTerm];
  //         if (this.rectifyTimeSpan[0] > this.rectifyTimeSpan[1]) {
  //           let swapTemp = this.rectifyTimeSpan[0];
  //           this.rectifyTimeSpan[0] = this.rectifyTimeSpan[1];
  //           this.rectifyTimeSpan[1] = swapTemp;
  //         }
  //         this.classInfo.timeSpan = tools.getContArray([this.rectifyTimeSpan]) as number[];
  //         if (this.isChangeSchedule) {
  //           if (!areClassAttributesEqual(this.oriClassInfo, this.classInfo)) {
  //             ScheduleManager.deleteClassFromSemester(this.displayTerm, this.oriClassInfo);
  //             ScheduleManager.addClassToSemester(this.displayTerm, this.classInfo, this.changeAllColor);
  //             this.refreshGrid();
  //           }
  //         } else {
  //           ScheduleManager.addClassToSemester(this.displayTerm, this.classInfo, this.changeAllColor);
  //           this.refreshGrid();
  //         }
  //         this.showSheet = false;
  //       });
  //     }
  //     .margin({ bottom: 7 })
  //     .bindPopup(this.showScrollHint, {
  //       builder: this.scrollHintPopup(),
  //       placement: Placement.Bottom,
  //       width: 300,
  //       onStateChange: (status) => {
  //         if (!status.isVisible) {
  //           this.showScrollHint = false;
  //         }
  //       }
  //     });
  //
  //     Scroll() {
  //       Column() {
  //         Row() {
  //           Text($r('app.string.class_detail_name'));
  //           TextInput({ text: this.classInfo.name })
  //             .layoutWeight(1)
  //             .textOverflow(TextOverflow.Ellipsis)
  //             .onChange((input: string) => this.classInfo.name = input)
  //             .selectAll(true);
  //         }
  //         .margin({ bottom: 5 });
  //
  //         Row() {
  //           Text($r('app.string.class_detail_teacher'));
  //           TextInput({ text: this.classInfo.teacher })
  //             .layoutWeight(1)
  //             .textOverflow(TextOverflow.Ellipsis)
  //             .onChange((input: string) => this.classInfo.teacher = input)
  //             .selectAll(true);
  //         }
  //         .margin({ bottom: 5 });
  //
  //         Row() {
  //           Text($r('app.string.class_detail_location'));
  //           TextInput({ text: this.classInfo.location })
  //             .layoutWeight(1)
  //             .textOverflow(TextOverflow.Ellipsis)
  //             .onChange((input: string) => this.classInfo.location = input)
  //             .selectAll(true);
  //         }
  //         .margin({ bottom: 5 });
  //
  //         Row() {
  //           Text($r('app.string.class_detail_id'));
  //           TextInput({ text: this.classInfo.id })
  //             .layoutWeight(1)
  //             .textOverflow(TextOverflow.Ellipsis)
  //             .onChange((input: string) => this.classInfo.id = input)
  //             .selectAll(true);
  //         }
  //         .margin({ bottom: 5 });
  //
  //         Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
  //           Row() {
  //             Text($r('app.string.class_detail_time'))
  //               .textAlign(TextAlign.Start);
  //             Select(this.createArray(1, 13))
  //               .value(this.rectifyTimeSpan[0].toString())
  //               .onSelect((index: number) => {
  //                 this.rectifyTimeSpan[0] = index + 1;
  //               });
  //             Text(' ~ ');
  //             Select(this.createArray(1, 13))
  //               .value(this.rectifyTimeSpan[1].toString())
  //               .onSelect((index: number) => {
  //                 this.rectifyTimeSpan[1] = index + 1;
  //               });
  //           }
  //           .margin({ bottom: 5, right: 10 })
  //
  //           Row() {
  //             Text($r('app.string.class_detail_day_of_week'))
  //               .textAlign(TextAlign.Start);
  //             Select([{ value: $r('app.string.sunday') }, { value: $r('app.string.monday') }, { value: $r('app.string.tuesday') },
  //               { value: $r('app.string.wednesday') }, { value: $r('app.string.thursday') }, { value: $r('app.string.friday') }, { value: $r('app.string.saturday') }])
  //               .value(tools.weekTranslate[this.classInfo.dayOfWeek])
  //               .onSelect((index: number) => {
  //                 this.classInfo.dayOfWeek = index;
  //               });
  //           }
  //           .margin({ bottom: 5 })
  //         }
  //
  //         Row() {
  //           Text('学分：')
  //             .textAlign(TextAlign.Start);
  //           TextInput({ text: this.classInfo.credits })
  //             .layoutWeight(1)
  //             .type(InputType.NUMBER_DECIMAL)
  //             .textOverflow(TextOverflow.Ellipsis)
  //             .onChange((input: string) => this.classInfo.credits = input)
  //             .selectAll(true);
  //         }
  //         .margin({ bottom: 5 })
  //
  //         Row() {
  //           Text($r('app.string.class_detail_color'))
  //             .textAlign(TextAlign.Start);
  //           Stack({ alignContent: Alignment.End }) {
  //             TextInput({ text: this.classColor })
  //               .textOverflow(TextOverflow.Ellipsis)
  //               .onChange((input: string) => {
  //                 // console.log('test'); 此处证明了this.classColor = input;不会导致死循环
  //                 if (/^#([A-Fa-f0-9]{3}|[A-Fa-f0-9]{4}|[A-Fa-f0-9]{6}|[A-Fa-f0-9]{8})$/.test(input)) {
  //                   this.isColorLegal = true;
  //                   this.classInfo.color = input;
  //                   this.colorARGB = tools.stringToRgba(input);
  //                 } else {
  //                   this.isColorLegal = false;
  //                 }
  //                 this.classColor = input;
  //               })
  //               .width('100%')
  //               .selectAll(true);
  //             Circle()
  //               .fill(this.isColorLegal ? this.classColor : '#00d00721')
  //               .width(32)
  //               .height(32)
  //               .offset({ x: -4 })
  //               .stroke(this.isColorLegal ? $r('app.color.grid_border') : $r('app.color.red'))
  //               .bindPopup(this.showColorHint, {
  //                 builder: this.colorHintPopup(),
  //                 placement: Placement.Left,
  //                 width: 300,
  //                 onStateChange: (status) => {
  //                   if (!status.isVisible) {
  //                     this.showColorHint = false;
  //                   }
  //                 }
  //               });
  //             Image($r('app.media.paintpalette'))
  //               .height(25)
  //               .offset({ x: -7 })
  //               .onClick(() => {
  //                 if (this.classColor.length === 4) {
  //                   this.colorDialogText = this.classColor[0] + this.classColor[1] + this.classColor[1]
  //                     + this.classColor[2] + this.classColor[2] + this.classColor[3] + this.classColor[3];
  //                 } else if (this.classColor.length === 5) {
  //                   this.colorDialogText = this.classColor[0] + this.classColor[1] + this.classColor[1]
  //                     + this.classColor[2] + this.classColor[2] + this.classColor[3] + this.classColor[3]
  //                     + this.classColor[4] + this.classColor[4];
  //                 } else {
  //                   this.colorDialogText = this.classColor;
  //                 }
  //                 this.colorARGB = tools.stringToRgba(this.colorDialogText);
  //                 if (this.colorDialogText.length === 7)
  //                   this.colorDialogText = `#FF${this.colorDialogText.slice(1,7)}`;
  //                 this.showColorPicker = true;
  //               });
  //           }
  //           .layoutWeight(1);
  //           PopoverDialog({
  //             visible: this.showColorPicker,
  //             targetBuilder: () => {},
  //             popover: {
  //               width: 300,
  //               placement: Placement.Top,
  //               arrowPointPosition: ArrowPointPosition.END,
  //               builder: () => { this.colorPicker() },
  //               onStateChange: (popup) => {
  //                 if (!popup.isVisible) {
  //                   // 关闭弹窗后记录颜色值
  //                   this.showColorPicker = false;
  //                   if (this.colorARGB[0] === 255) {
  //                     this.classColor = '#' + this.colorARGB[1].toString(16).padStart(2, '0').toUpperCase()
  //                       + this.colorARGB[2].toString(16).padStart(2, '0').toUpperCase()
  //                       + this.colorARGB[3].toString(16).padStart(2, '0').toUpperCase();
  //                   } else {
  //                     this.classColor = '#' + this.colorARGB[0].toString(16).padStart(2, '0').toUpperCase()
  //                       + this.colorARGB[1].toString(16).padStart(2, '0').toUpperCase()
  //                       + this.colorARGB[2].toString(16).padStart(2, '0').toUpperCase()
  //                       + this.colorARGB[3].toString(16).padStart(2, '0').toUpperCase();
  //                   }
  //                   this.classInfo.color = this.classColor;
  //                 }
  //               }
  //             },
  //           })
  //         }
  //         // .margin({ bottom: 5 })
  //
  //         Row() {
  //           Text($r('app.string.class_detail_weeks', tools.shrinkContArrayToString(this.weekOfTerm)))
  //             .textAlign(TextAlign.Start)
  //             .layoutWeight(1)
  //             .maxLines(2)
  //             .textOverflow({ overflow: TextOverflow.Ellipsis });
  //           CheckboxGroup({ group: `checkboxGroup${this.checkBoxGroup}` })
  //             .checkboxShape(CheckBoxShape.ROUNDED_SQUARE)
  //             .selectedColor(presetColor[BackgroundImage.themeColor][2])
  //             .onChange((itemName: CheckboxGroupResult) => {
  //               let selectAny: boolean = false;
  //               this.weekOfTerm = [];
  //               for (let weekRepeat = 1; weekRepeat <= 20; weekRepeat++) {
  //                 if (this.rectifyWeekOfTerm[weekRepeat]) {
  //                   this.weekOfTerm.push(weekRepeat);
  //                   selectAny = true;
  //                 }
  //               }
  //               this.isWeeksLegal = selectAny;
  //             });
  //           Text($r('app.string.select_all'));
  //         }
  //         .width('100%');
  //
  //         Flex({ wrap: FlexWrap.Wrap, alignContent: FlexAlign.SpaceAround }) {
  //           ForEach(tools.getContArray([[1, 20]]), (checkboxId: number) => {
  //             Row() {
  //               Checkbox({ name: checkboxId.toString(), group: `checkboxGroup${this.checkBoxGroup}` })
  //                 .shape(CheckBoxShape.ROUNDED_SQUARE)
  //                 .select(this.rectifyWeekOfTerm[checkboxId])
  //                 .selectedColor(presetColor[BackgroundImage.themeColor][2])
  //                 .onChange((value: boolean) => {
  //                   this.rectifyWeekOfTerm[checkboxId] = value;
  //                 });
  //               Text((checkboxId).toString()).width(20);
  //             }
  //           });
  //         }
  //
  //         Row() {
  //           Text($r('app.string.class_detail_priority'))
  //           Slider({ min: 0, max: 10, value: this.oriClassInfo.priority, step: 1, style: SliderStyle.InSet })
  //             .showSteps(true)
  //             .selectedColor(presetColor[BackgroundImage.themeColor][2])
  //             .layoutWeight(1)
  //             .onChange((value: number) => {
  //               this.classInfo.priority = value;
  //             })
  //         }
  //       }
  //       .alignItems(HorizontalAlign.Start)
  //       .width('90%');
  //     }
  //     .fadingEdge(true)
  //     .width('100%')
  //     .layoutWeight(1)
  //     .align(Alignment.Top)
  //     .scrollBar(BarState.Auto)
  //     .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false });
  //   }
  //   .padding({ top: 16, left: 16, right: 16})
  //   .width('100%')
  //   .height('100%')
  // }
}
