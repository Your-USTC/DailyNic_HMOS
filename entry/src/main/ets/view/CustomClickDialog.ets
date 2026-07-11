
import { CounterComponent, CounterType } from '@kit.ArkUI';
import { customizeClick, gIndex_to_pic } from '../utils/FunctionOrder';
import UnifiedPreferences from '../utils/UnifyPreference';
import { GridData } from '../constants/Links';
import { refreshFunc, mostUsedFunc } from '../utils/FunctionOrder';
import { presetColor } from '../utils/BgImageManager';
import BackgroundImage from '../utils/BgImageManager';

@CustomDialog
export default struct CustomClick {
  dialogController: CustomDialogController;
  gridIndex: number = 0;
  index: number = 0;
  clickTimes: number = 0;
  @Link copyMostUsedFunc: GridData;

  build() {
    Column() {
      Row() {
        Image(gIndex_to_pic(this.gridIndex, this.index))
          .height(30)
          .margin({ right: 5 });

        Text(otherGridDataList[this.gridIndex].gridItemList[this.index])
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });

        CounterComponent({
          options: {
            type: CounterType.INLINE,
            inlineOptions: {
              value: UnifiedPreferences.getNumberSync(`${this.gridIndex}.${this.index}`, 0),
              min: 0, step: 1, max: 2147483647,
              onChange: (value: number) => { this.clickTimes = value; }
            }
          }
        })
      }
      .width('95%')
      .margin({ bottom: 5 })

      Text($r('app.string.custom_click_into_s', otherGridDataList[this.gridIndex].gridItemList[this.index]))
        .width('90%')
        .wordBreak(WordBreak.BREAK_ALL)

      Row() {
        Button($r('app.string.cancel'))
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .width('50%')
          .onClick(() => this.dialogController.close())
          .fontColor(presetColor[BackgroundImage.themeColor][2])

        Button($r('app.string.ok'))
          .buttonStyle(ButtonStyleMode.EMPHASIZED)
          .width('50%')
          .backgroundColor(presetColor[BackgroundImage.themeColor][2])
          .onClick(() => {
            customizeClick(this.gridIndex, this.index, this.clickTimes);
            refreshFunc(); // 刷新点击次数显示
            this.copyMostUsedFunc = mostUsedFunc;
            this.dialogController.close();
          })
      }
      .margin({ top: 5 })
    }
    .width('100%')
    .padding(16)
  }
}