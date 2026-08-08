import { LINK, MultiLink, LinkSet } from '../constants/Links';
import { fileIo } from '@kit.CoreFileKit';

const MAX_RECORD_KEY = 'maxRecord';

let orderFilePath: string = '';
let clickDataCache: Record<string, number> | null = null;

/**
 * 初始化 FunctionOrder。必须在任何读写操作之前调用一次（EntryAbility.onCreate 中调用）。
 * @param context 应用上下文
 */
export function init(context: Context): void {
  orderFilePath = `${context.filesDir}/functionOrder.json`;
  const data = loadClickData();
  const storedMax = data[MAX_RECORD_KEY];
  if (typeof storedMax === 'number' && storedMax > 0) {
    maxRecord = Math.min(28, Math.trunc(storedMax));
  }
}

function loadClickData(): Record<string, number> {
  if (clickDataCache !== null) {
    return clickDataCache;
  }
  try {
    if (fileIo.accessSync(orderFilePath)) {
      clickDataCache = JSON.parse(fileIo.readTextSync(orderFilePath)) as Record<string, number>;
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
    const file = fileIo.openSync(orderFilePath, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
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
  const data = loadClickData();
  data[MAX_RECORD_KEY] = value;
  clickDataCache = data;
  flushClickData();
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
    if (key === MAX_RECORD_KEY) {
      continue;
    }
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

/**
 * 将旧版（2.1.1 及以前）保存在 UnifyPreference 中的最近使用数据导入本地 JSON 文件。
 * 点击次数与 maxRecord 都会被写入，且不会覆盖已存在的同名点击数据（取较大值）。
 * @param legacyData 旧版点击次数映射，键为 "{grid}.{index}"，值为点击次数
 * @param legacyMaxRecord 旧版「最多显示几个」值；无效（非正数）时不写入
 */
export function importLegacyData(legacyData: Record<string, number>, legacyMaxRecord: number): void {
  const data = loadClickData();
  for (const key of Object.keys(legacyData)) {
    if (key === MAX_RECORD_KEY ||
      legacyData[key] === undefined ||
      legacyData[key] <= 0 ||
      legacyData[key] > 2147483647) {
      continue;
    }
    const parts = key.split('.');
    if (parts.length !== 2) {
      continue;
    }
    const grid = Number(parts[0]);
    const idx = Number(parts[1]);
    if (!Number.isInteger(grid) || !Number.isInteger(idx) || grid < 0 || idx < 0) {
      continue;
    }
    const current = data[key];
    if (current === undefined || legacyData[key] > current) {
      data[key] = legacyData[key];
    }
  }
  if (typeof legacyMaxRecord === 'number' && legacyMaxRecord > 0 && legacyMaxRecord <= 28) {
    data[MAX_RECORD_KEY] = Math.trunc(legacyMaxRecord);
    maxRecord = data[MAX_RECORD_KEY];
  }
  clickDataCache = data;
  if (Object.keys(data).length > 0) {
    flushClickData();
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