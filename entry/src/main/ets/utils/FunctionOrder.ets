
import { LinkAddress } from '../constants/Links';
import { LINK } from '../constants/Links'
import UnifiedPreferences from './UnifyPreference';

export let mostUsedFunc: GridData = new GridData($r('app.string.ZuiJinShiYong'), [ $r('app.string.empty') ]);
export let order: Array<[string, number]> = [];
export let maxRecord: number = UnifiedPreferences.getNumberSync('maxRecord', 8) as number;

export function setFunc(toClear: boolean = false): void {
  // toClear: 是否清空，默认为 false
  if (toClear) {
    mostUsedFunc = new GridData($r('app.string.ZuiJinShiYong'), [ $r('app.string.empty') ]);
    order = [];
    return;
  }
  mostUsedFunc.gridItemList = [];
  maxRecord = UnifiedPreferences.getNumberSync('maxRecord', 8) as number;
  let maxCount: number = 0;
  for (let singleFunc of order) {
    let index_to_name = LINK.get(singleFunc[0])?.title;
    if (index_to_name === undefined) {
      continue;
    }
    mostUsedFunc.gridItemList.push(index_to_name);
    maxCount++;
    if (maxCount >= maxRecord)
      break;
  }
}

export function setMaxRecord(value: number) {
  maxRecord = value;
  UnifiedPreferences.putSync('maxRecord', value);
}

export function recordClick(gridIndex: number, index: number): void {
  if (gridIndex == -1) // 常用区 (-1) 不记录
    return;
  let preName: string = gridIndex.toString() + '.' + index.toString(); // 按钮对应首选项名称
  let latestTime: number = UnifiedPreferences.getNumberSync(preName, 0); // 读取点击次数

  if (latestTime < 2147483619) {
    latestTime++; // 点击次数+1
    UnifiedPreferences.putSync(preName, latestTime); // 保存新的点击次数
  }
}

export function customizeClick(gridIndex: number, index: number, clickTimes: number): void {
  if (gridIndex == -1 || clickTimes > 2147483647) // 常用区 (-1) 不记录，数据过大不记录
    return;

  if (clickTimes > 0)
    UnifiedPreferences.putSync(gridIndex.toString() + '.' + index.toString(), clickTimes); // 按钮对应首选项名称
  else
    UnifiedPreferences.deleteSync(gridIndex.toString() + '.' + index.toString());
}

export function refreshFunc(): void {
  order = []
  for (let gridIndex = 0; gridIndex < totalGridNum; gridIndex++) {
    for (let index = 0; index < eachGridNum[gridIndex]; index++) {
      let preName: string = gridIndex.toString() + '.' + index;
      if (UnifiedPreferences.hasSync(preName)) {
        let preTimes: number = UnifiedPreferences.getNumberSync(preName, 0);
        order.push([preName, preTimes]);
      }
    }
  }
  if (order.length == 0)
    setFunc(true);
  else {
    order.sort((a, b) => b[1] - a[1]);
    setFunc();
  }
}

export function resetFunc(): void { // 重置"最常访问"
  for (let gridIndex = 0; gridIndex < totalGridNum; gridIndex++) {
    for (let index = 0; index < eachGridNum[gridIndex]; index++) {
      let preName: string = gridIndex.toString() + '.' + index;
      if (UnifiedPreferences.hasSync(preName)) {
        UnifiedPreferences.deleteSync(preName);
      }
    }
  }
  setFunc(true);
}

export function gIndex_to_pic(gridIndex: number, index: number): ResourceStr { // 最常访问部分映射
  if (gridIndex == -1){
    if (order.length <= index)
      return $r('app.media.default_function_icon');
    let preName: string = order[index][0];
    gridIndex = Number(preName.split('.')[0]);
    index = Number(preName.split('.')[1]);
  }
  let result = index_to_pic.get(gridIndex.toString() + '.' + index.toString());
  if (result == undefined)
    return $r('app.media.default_function_icon');
  else
    return result;
}
