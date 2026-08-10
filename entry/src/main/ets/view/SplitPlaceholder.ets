/* const curHour = new Date().getHours();
let text = '';
if (curHour > 5 && curHour < 9) {
  text = '早上好';
} else if (curHour < 11) {
  text = '上午好';
} else if (curHour < 14) {
  text = '中午好';
} else if (curHour < 18) {
  text = '下午好';
} else {
  text = '晚上好';
} */
const text = '我会一直一直看着你...'

@Builder export function SplitPlaceholder() {
  Column() {
    Image($r('app.media.peek'))
      .height('234px')
      .width('234px')
    Text(text)
  }
  .width('100%')
  .height('100%')
  .justifyContent(FlexAlign.Center)
}