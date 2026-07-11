import { LINK, MultiLink, LinkSet } from '../constants/Links';
import { fileIo } from '@kit.CoreFileKit';

const ORDER_FILE_PATH = '/data/storage/el2/base/haps/entry/files/functionOrder.json';

let clickDataCache: Record<string, number> | null = null;

function loadClickData(): Record<string, number> {
  if (clickDataCache !== null) {
    return clickDataCache;
  }
  try {
    if (fileIo.accessSync(ORDER_FILE_PATH)) {
      clickDataCache = JSON.parse(fileIo.readTextSync(ORDER_FILE_PATH)) as Record<string, number>;
    }
  } catch (e) {
    console.error('FunctionOrder: failed to load order file:', JSON.stringify(e));
  }
  if (clickDataCache === null) {
    clickDataCache = {};
  }
  return clickDataCache;
}

function flushClickData(): void {
  try {
    const file = fileIo.openSync(ORDER_FILE_PATH, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
    fileIo.writeSync(file.fd, JSON.stringify(clickDataCache ?? {}));
    fileIo.closeSync(file);
  } catch (e) {
    console.error('FunctionOrder: failed to save order file:', JSON.stringify(e));
  }
}

export let order: Array<[string, number]> = [];
export let maxRecord: number = 8;

export let mostUsedFunc: MultiLink[] = [];

export function setFunc(toClear: boolean = false): void {
  if (toClear) {
    mostUsedFunc = [{
      title: $r('app.string.empty'),
      icon: $r('app.media.default_function_icon'),
      url: []
    }];
    order = [];
    return;
  }
  let count = 0;
  const result: MultiLink[] = [];
  for (const entry of order) {
    const parts = entry[0].split('.');
    const gridIndex = Number(parts[0]);
    const index = Number(parts[1]);
    if (gridIndex < LINK.length && index < LINK[gridIndex].set.length) {
      result.push(LINK[gridIndex].set[index]);
      if (++count >= maxRecord) {
        break;
      }
    }
  }
  mostUsedFunc = result;
}

export function setMaxRecord(value: number): void {
  maxRecord = value;
}

export function recordClick(gridIndex: number, index: number): void {
  if (gridIndex === -1) {
    return;
  }
  const data = loadClickData();
  const key = `${gridIndex}.${index}`;
  const current = data[key] ?? 0;
  if (current < 2147483619) {
    data[key] = current + 1;
    clickDataCache = data;
    flushClickData();
  }
}

export function customizeClick(gridIndex: number, index: number, clickTimes: number): void {
  if (gridIndex === -1 || clickTimes > 2147483647) {
    return;
  }
  const data = loadClickData();
  data[`${gridIndex}.${index}`] = clickTimes;
  clickDataCache = data;
  flushClickData();
}

export function refreshFunc(): void {
  const data = loadClickData();
  order = [];
  for (const key of Object.keys(data)) {
    if (data[key] > 0) {
      order.push([key, data[key]] as [string, number]);
    }
  }
  if (order.length === 0) {
    setFunc(true);
  } else {
    order.sort((a, b) => b[1] - a[1]);
    setFunc();
  }
}

export function resetFunc(): void {
  clickDataCache = {};
  flushClickData();
  setFunc(true);
}

export function getClickCount(gridIndex: number, index: number): number {
  const data = loadClickData();
  return data[`${gridIndex}.${index}`] ?? 0;
}

export function gIndex_to_pic(gridIndex: number, index: number): ResourceStr {
  if (gridIndex === -1) {
    if (order.length <= index) {
      return $r('app.media.default_function_icon');
    }
    const parts = order[index][0].split('.');
    gridIndex = Number(parts[0]);
    index = Number(parts[1]);
  }
  if (gridIndex < LINK.length && index < LINK[gridIndex].set.length) {
    return LINK[gridIndex].set[index].icon;
  }
  return $r('app.media.default_function_icon');
}