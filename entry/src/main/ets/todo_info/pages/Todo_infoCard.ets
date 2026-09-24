import { CardListComponent } from '../view/CardListComponent';
import { CardListParameter } from '../viewmodel/CardListParameter';
import { TodoCardItem } from '../viewmodel/TodoCardItem';

let localStorage = new LocalStorage();

@Entry(localStorage)
@Component
struct Todo_infoCard {
  @LocalStorageProp('todoList') todoList: TodoCardItem[] = [];
  @LocalStorageProp('title') title: ResourceStr = '';
  @LocalStorageProp('count') count: number = 0;

  @LocalStorageProp('cardListParameter') cardListParameter: CardListParameter = new CardListParameter(
    /* backgroundColor          */ $r('sys.color.ohos_id_color_background'),
    /* title                    */ $r('app.string.todo_card_title'),
    /* backgroundImage          */ undefined,
    /* backgroundImageSize      */ ImageSize.Auto,
    /* isItemCount              */ true,
    /* itemCount                */ this.todoList.length,
    /* itemCountColor           */ $r('sys.color.ohos_id_color_emphasize'),
    /* itemCountBackgroundColor */ $r('app.color.list_item_count_background'),
    /* titleColor               */ undefined,
    /* isBottomIcon             */ false,
    /* bottomIcon               */ undefined
  )

  /** 重要度对应的徽章底色，数值越高越醒目（与 Todo 页面保持一致） */
  priorityColor(priority: number): Resource {
    if (priority >= 7) {
      return $r('app.color.minute');
    }
    if (priority >= 4) {
      return $r('app.color.hour');
    }
    return $r('app.color.green');
  }

  @Builder
  cardListBuilder() {
    if (this.todoList.length === 0) {
      ListItem() {
        Column() {
          Image($r('app.media.lying_on_lounge'))
            .height(75)
            .interpolation(ImageInterpolation.Medium)
          Text($r('app.string.no_todo_info1'))
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .height('100%')
      .padding({ top: 12, bottom: 12 })
    } else {
      ForEach(this.todoList, (item: TodoCardItem, index: number) => {
        Row() {
          Column({ space: 3 }) {
            Text(item.text)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .decoration({
                type: item.done ? TextDecorationType.LineThrough : TextDecorationType.None,
                color: Color.Gray
              })

            if (item.timeDesc !== '') {
              Text(item.timeDesc)
                .fontSize(12)
                .fontColor(item.overdue ? $r('app.color.minute') : $r('app.color.transparent_text'))
            }

            if (item.priority > 0 || item.isAssignment) {
              Row({ space: 5 }) {
                if (item.priority > 0) {
                  Text(`重要度 ${item.priority}`)
                    .fontSize(10)
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .borderRadius(5)
                    .fontColor(Color.White)
                    .backgroundColor(this.priorityColor(item.priority))
                }
                if (item.isAssignment) {
                  Text('作业')
                    .fontSize(10)
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .borderRadius(5)
                    .fontColor(Color.White)
                    .backgroundColor($r('app.color.hour'))
                }
              }
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .margin({ top: 7, bottom: 7 })

        if (index < this.todoList.length - 1) {
          Divider().width('95%');
        }
      })
    }
  }

  build() {
    Column() {
      CardListComponent({ cardListParameter: this.cardListParameter, title: this.title, count: this.count }) {
        this.cardListBuilder();
      }
    }
    .width('100%')
    .height('100%')
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: { message: 'add detail', router: 'Todo' }
      });
    })
  }
}
