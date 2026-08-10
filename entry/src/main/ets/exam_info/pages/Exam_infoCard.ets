import { CardListComponent } from '../view/CardListComponent';
import { CardListParameter } from '../viewmodel/CardListParameter';
import { examAttribute } from '../../utils/ExamStorage';
import * as tools from '../../utils/tools';

let localStorage = new LocalStorage();

@Entry(localStorage)
@Component
struct Class_schedule_dailyCard {
  @LocalStorageProp('examInfo') examInfo: examAttribute[] = [];
  @LocalStorageProp('title') title: ResourceStr = '';
  @LocalStorageProp('count') count: number = 0;

  @LocalStorageProp('cardListParameter') cardListParameter: CardListParameter = new CardListParameter(
    /* backgroundColor          */ $r('sys.color.ohos_id_color_background'),
    /* title                    */ $r('app.string.schedule_card_title'),
    /* backgroundImage          */ undefined,
    /* backgroundImageSize      */ ImageSize.Auto,
    /* isItemCount              */ true,
    /* itemCount                */ this.examInfo.length,
    /* itemCountColor           */ $r('sys.color.ohos_id_color_emphasize'),
    /* itemCountBackgroundColor */ $r('app.color.list_item_count_background'),
    /* titleColor               */ undefined,
    /* isBottomIcon             */ false,
    /* bottomIcon               */ undefined
  )
  @LocalStorageProp('currentTime') currentTime: number = Date.now();

  @Builder
  cardListBuilder() {
    if (this.examInfo.length === 0) {
      Column() {
        Image($r('app.media.no_exam1'))
          .height(75)
          .interpolation(ImageInterpolation.Medium)
        Text($r('app.string.no_exam_info1'));
      }
      .margin({ top: 12, bottom: 12 });
    } else {
      ForEach(this.examInfo, (singleExam: examAttribute, index: number) => {
        Row() {
          if (this.currentTime < singleExam.beginTimeStamp) {
            if (singleExam.beginTimeStamp - this.currentTime >= 86400000)
              Text() {
                Span(tools.formatTimeDiff(this.currentTime, singleExam.beginTimeStamp, 0).toString())
                  .fontSize(36)
                Span($r('app.string.day'))
                  .fontSize(18)
              }
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.green'))
              .textAlign(TextAlign.Center)
              .width('30%');
            else
              Text() {
                Span(Number((tools.formatTimeDiff(this.currentTime, singleExam.beginTimeStamp, 1)
                  + tools.formatTimeDiff(this.currentTime, singleExam.beginTimeStamp, 2) / 60).toExponential(1)).toString())
                  .fontSize(28)
                Span($r('app.string.hour'))
                  .fontSize(14)
              }
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.hour'))
              .textAlign(TextAlign.Center)
              .width('30%');
          } else {
            Text($r('app.string.exam_processing'))
              .fontSize(18)
              .fontColor($r('app.color.transparent_text'))
              .width('30%')
              .textAlign(TextAlign.Center);
          }

          Column() {
            Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.End }) {
              Text(singleExam.name)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ right: 5 })
              Text(singleExam.type)
                .fontSize(13)
            }
            .margin({ bottom: 5 })

            Text('\udb80\uddb8 ' + singleExam.campus + singleExam.building + singleExam.classroom)
              .fontSize(13)
              .visibility(singleExam.campus + singleExam.building + singleExam.classroom == '' ? Visibility.None : Visibility.Visible);
            Text('\udb80\udfdc ' + singleExam.date)
              .fontSize(13)
              .visibility(singleExam.date == '' ? Visibility.None : Visibility.Visible);
          }
          .width('70%')
          .alignItems(HorizontalAlign.Start);
        }
        //.width('90%')
        .margin({ top: 7, bottom: 7 })

        if (index < this.examInfo.length - 1) {
          Divider().width('95%');
        }
      })
    }
  }

  build() {
    Column() {
      CardListComponent({ cardListParameter: this.cardListParameter, title: this.title, count: this.count}) {
        this.cardListBuilder();
      }
    }
    .width('100%')
    .height('100%')
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: { message: 'add detail', router: 'ExamDetail'}
      });
    })
  }
}