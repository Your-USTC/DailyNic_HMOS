import { common } from "@kit.AbilityKit";
import { fileIo, fileUri, picker } from "@kit.CoreFileKit";
import { BusinessError } from "@kit.BasicServicesKit";
import { LessonInfo } from "./ScheduleData";
import { commonClassStamp } from "../constants/ScheduleSources";

/**
 * 提取文件路径的扩展名（不含分隔符`.`）
 * @param filePath 字符串格式的文件路径
 * @returns 扩展名（无扩展名返回空字符串）
 */
function getFileExtension(filePath: string): string {
  // 处理空字符串、纯空格等无效路径
  if (!filePath || filePath.trim() === '') {
    return '';
  }

  // 统一处理路径分隔符（兼容 Windows\ 和 Unix/），转为小写便于统一判断
  const normalizedPath = filePath.trim().toLowerCase();

  // 定位最后一个`.`的位置（扩展名的分隔符）
  const lastDotIndex = normalizedPath.lastIndexOf('.');
  // 定位最后一个路径分隔符的位置（区分文件名和路径）
  const lastSeparatorIndex = Math.max(
    normalizedPath.lastIndexOf('/'),
    normalizedPath.lastIndexOf('\\')
  );

  // 核心判断逻辑：
  // 1. 最后一个`.`必须在路径分隔符之后（排除路径中的`.`，如 /dir.name/file.txt）
  // 2. 不能是文件名的第一个字符（排除 `.gitignore` 这类无扩展名的隐藏文件）
  // 3. 不能是最后一个字符（排除 `file.` 这类无效格式）
  if (
    lastDotIndex > lastSeparatorIndex &&
      lastDotIndex !== normalizedPath.length - 1 &&
      lastDotIndex !== 0
  ) {
    // 提取扩展名（从`.`的下一位到末尾）
    return normalizedPath.slice(lastDotIndex + 1);
  }

  // 无有效扩展名返回空字符串
  return '';
}

/**
 * 复制（提取）文件扩展名（包含分隔符`.`）
 * @param filePath 字符串格式的文件路径
 * @returns 带`.`的扩展名（无扩展名返回空字符串）
 */
function copyFileExtension(filePath: string): string {
  const ext = getFileExtension(filePath);
  return ext ? `.${ext}` : '';
}

export const colorSet: string[] = [
  "#FF89", "#FFFFF5C4", "#FFFF2C75",
  "#FF00F5C4", "#FFCCBBFF", "#FFAEDEFF", "#FFD0",
  "#FFB7FFFA", "#FFA4FFD6", "#FFD7FF9C", "#FFFFE690",
  "#FFFFAF9C", "#FFFF9100", "#FFCAE1E6", "#FF0093AB",
  "#FF7D6FFF", "#FF4377FF", "#FF66B78B", "#FF66E5FF",
  "#FFF0DFCC", "#FF8C96FF", "#FF2196F3", "#FF1DE9B6",
  "#FFFF1720", "#FF7DACFF", "#FF6AE1E6", "#FFFFC7CD",
  "#FF7BD8E3", "#FF009348", "#FFFF7FB6", "#FFAE3EFF"
];
export const colorSetLen = colorSet.length;

/**
 * 将 #RGB 系列颜色值转换为 RGBA 数值（0-255 范围）
 * @param color 支持格式：#RGB、#RGBA、#RRGGBB、#RRGGBBAA（必须以 # 开头）
 * @returns number[] [r: number; g: number; b: number; a: number] RGBA 数值对象（范围 0-255）
 * @throws 无效颜色格式时抛出错误
 */
export function stringToRgba(color: string): number[] {
  // 正则表达式匹配所有合法格式（忽略大小写）
  const regex = /^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{4}|[0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$/;
  const match = color.match(regex);
  let r = 255, g = 199, b = 205, a = 255; // 默认不透明
  if (!match) {
    return [a, r, g, b];
  }
  let hex = match[1].toLowerCase();
  // 处理短格式（#RGB / #RGBA）：扩展为长格式
  if (hex.length === 3 || hex.length === 4) {
    hex = hex.split('').map(char => char.repeat(2)).join('');
  } else if (hex.length === 8) {
    // 提取各通道值（16进制转10进制）
    a = parseInt(hex.slice(0, 2), 16);
    r = parseInt(hex.slice(2, 4), 16);
    g = parseInt(hex.slice(4, 6), 16);
    b = parseInt(hex.slice(6, 8), 16);
  } else {
    r = parseInt(hex.slice(0, 2), 16);
    g = parseInt(hex.slice(2, 4), 16);
    b = parseInt(hex.slice(4, 6), 16);
  }
  // 确保 RGB 值在 0-255 范围内（防止异常值）
  a = Math.max(0, Math.min(255, a));
  r = Math.max(0, Math.min(255, r));
  g = Math.max(0, Math.min(255, g));
  b = Math.max(0, Math.min(255, b));
  return [a, r, g, b];
}

export const weekTranslate: ResourceStr[] = [$r('app.string.Sunday'), $r('app.string.Monday'), $r('app.string.Tuesday'), $r(
  'app.string.Wednesday'),
                                             $r('app.string.Thursday'), $r('app.string.Friday'), $r(
                                               'app.string.Saturday')];

export function getRandomInt(min: number, max: number): number {
  min = Math.ceil(min);
  max = Math.floor(max);
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

/**
 * 构造连续整数数组
 * (可以在调用的后面加上 as number[] 或 as string[] )
 * @param range 取值范围 (例如: 输入 [[1,3],[5,6]], 返回 [1,2,3,5,6] )
 * @param returnString 返回类型 (默认返回 number[], 为 true 则返回 string[] )
 */
export function getContArray(range: number[][], returnString: boolean = false): string[] | number[] {
  if (returnString) {
    let res: string[] = [];
    for (let single of range) {
      for (let i = single[0]; i <= single[1]; i++) {
        res.push(i.toString());
      }
    }
    return res;
  } else {
    let res: number[] = [];
    for (let single of range) {
      for (let i = single[0]; i <= single[1]; i++) {
        res.push(i);
      }
    }
    return res;
  }
}

export function shrinkContArrayToString(array: number[]):string {
  if (array.length == 0) {
    return '---';
  }
  let res: string = array[0].toString();
  let i: number;
  for (i = 1; i < array.length; i++)
    if (array[i] != array[i - 1] + 1)
      res = res + `-${array[i - 1]}, ${array[i]}`;
  return res + `-${array[i - 1]}`;
}

export function getClassTimestamp(termBeginDate: number, week: number, day: number, surplus: number): number {
  return termBeginDate
    + (week - 1) * 604800000    // 第几周
    + day * 86400000            // 第几天，不-1是因为教务系统中一周从周日开始
    + surplus;                  // 第几节课结束
}

export function areNumberArraysEqual(arr1: number[], arr2: number[]): boolean {
  // 先比较长度，长度不同直接返回 false
  if (arr1.length !== arr2.length) return false;
  // 逐个比较元素
  for (let i = 0; i < arr1.length; i++) {
    if (arr1[i] !== arr2[i]) return false;
  }
  return true;
}

/**
 * 格式化时间差
 * 根据指定的类型返回两个时间戳之间相差的天数、小时数或分钟数
 *
 * @param start - 开始时间戳（毫秒）
 * @param end - 结束时间戳（毫秒）
 * @param type - 计算类型：
 *               0 = 返回相差的天数
 *               1 = 返回相差的小时数（除去整天后的剩余小时）
 *               2 = 返回相差的分钟数（除去整小时后的剩余分钟）
 *
 * @returns 根据类型返回对应的时间差值（向下取整）
 */
export function formatTimeDiff(start: number, end: number, type: number): number {
  const diffSec = Math.abs(end - start) / 1000;
  switch(type) {
    case 0:
      return Math.floor(diffSec / 86400);
    case 1:
      return Math.floor((diffSec % 86400) / 3600);
    case 2:
      return Math.floor((diffSec % 3600) / 60);
  }
  return 0;
}

/**
 * 直接修改原升序无重复数字数组，插入指定数后保持升序且无重复
 * @param sortedArr 已升序排序、无重复的数字原数组（会被直接修改）
 * @param num 待插入的数字
 */
function insertIntoSortedArray(sortedArr: number[], num: number): void {
  if (sortedArr.includes(num)) {
    return;
  }

  // 二分查找核心逻辑：找第一个大于num的元素索引
  let left = 0;
  let right = sortedArr.length - 1;
  let insertIndex = sortedArr.length; // 默认插尾部

  while (left <= right) {
    const mid = Math.floor((left + right) / 2);
    if (sortedArr[mid] > num) {
      insertIndex = mid; // 记录可能的插入位置，继续向左找
      right = mid - 1;
    } else {
      left = mid + 1; // 继续向右找
    }
  }

  // 直接修改原数组
  sortedArr.splice(insertIndex, 0, num);
}

/**
 * 将长度值（Length类型）转换为数字类型的长度值
 * @param length - 待转换的长度值，支持数字类型、字符串类型，或undefined
 * @param defaultLen - 当length为undefined或无法转换时返回的默认数字长度
 * @returns 转换后的数字类型长度值：
 *          1. 若length是数字，直接返回该数字
 *          2. 若length是字符串，尝试转换为整数后返回
 *          3. 若length是undefined，返回传入的默认值defaultLen
 * @note 字符串转换仅使用parseInt，会自动忽略非数字前缀后的内容（如"123px"会转为123）
 */
export function LengthToNumber(length: Length | undefined, defaultLen: number): number {
  if (typeof length === "number")
    return length;
  else if (typeof length === "string")
    return parseInt(length);
  else
    return defaultLen;
}

/**
 * 增强版字节格式化函数
 * @param bytes 字节数
 * @param decimals 保留小数位数
 * @param useBinary 是否使用二进制进制（1024），默认true
 * @returns 格式化后的字符串
 */
export function formatBytes(bytes: number, decimals: number = 2, useBinary: boolean = true): string {
  if (bytes === 0) return '0 B';

  const k = useBinary ? 1024 : 1000;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = useBinary ? ['B', 'KB', 'MB', 'GB', 'TB', 'PB'] : ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];

  const i = Math.floor(Math.log(bytes) / Math.log(k));

  return `${(bytes / Math.pow(k, i)).toFixed(dm)} ${sizes[i]}`;
}

/**
 * 从课表页面分离课程编号和学分
 * @param inputStr 输入字符串，格式如 "CS1000.H1 [3]"
 * @returns 受限于要求，返回一个大小为2的字符串数组，下标0为编号，1为学分；提取失败时，[0]为原字符串，[1]为'0'
 */
export function extractCredits(inputStr: string): string[] {
  const regex = /(.*?)\s*\[(\d+\.?\d*)\]/;
  const matchResult = inputStr.match(regex);

  if (matchResult && matchResult.length >= 3) {
    const numValue = Number(matchResult[2]);
    // 额外验证：确保转换后的数字是有效的（避免空字符串/非数字）
    if (!isNaN(numValue)) {
      return [matchResult[1], matchResult[2]];
    }
  }
	return [inputStr, '0'];
}


/**
 * 截断字符串：长度超过最大长度则取最大长度加省略号，否则返回原字符串
 * @param str 待处理的字符串（支持空值，会转为空字符串处理）
 * @param maxLen 最大长度
 * @returns 处理后的字符串
 */
export function truncateString(str: string = '', maxLen: number): string {
  if (str.length > maxLen) {
    return str.substring(0, maxLen) + '...';
  }
  return str;
}

export function saveStringToFile(context: UIContext, fileName: string, suffixChoices: string, saveData: string) {
  try {
    const documentSaveOptions = new picker.DocumentSaveOptions();
    documentSaveOptions.newFileNames = [fileName];
    documentSaveOptions.defaultFilePathUri = "file://docs/storage/Users/currentUser/";
    documentSaveOptions.fileSuffixChoices = [suffixChoices];
    const documentViewPicker = new picker.DocumentViewPicker(context.getHostContext() as common.UIAbilityContext);
    documentViewPicker.save(documentSaveOptions).then((documentSaveResult: string[]) => {
      if (documentSaveResult.length > 0) {
        let uri: string = documentSaveResult[0];
        let file = fileIo.openSync(uri, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
        /*let writeLen: number = */
        fileIo.writeSync(file.fd, saveData);
        fileIo.closeSync(file);
        context.getPromptAction().showToast({ message: $r('app.string.save_file_success', decodeURI(uri.slice(38))), duration: 5000 });
      } else {
        context.getPromptAction().showToast({ message: $r('app.string.save_file_cancel') });
      }
    });
  } catch(err) {
    context.getPromptAction().showToast({ message: $r('app.string.save_file_cancel') });
  }
}

export async function readStringFromFile(context: UIContext, suffixChoices: string): Promise<string> {
  try {
    const documentSelectOptions = new picker.DocumentSelectOptions();
    documentSelectOptions.maxSelectNumber = 1;
    documentSelectOptions.fileSuffixFilters = [suffixChoices];
    const documentViewPicker = new picker.DocumentViewPicker(context.getHostContext() as common.UIAbilityContext);
    const documentSelectResult: string[] = await documentViewPicker.select(documentSelectOptions);
    if (documentSelectResult.length > 0) {
      const result = fileIo.readTextSync(new fileUri.FileUri(documentSelectResult[0]).path);
      return result;
    } else {
      return 'null';
    }
  } catch(err) {
    return 'null';
  }
}

export function handleOverlappedLessons(lessons: LessonInfo[]): Array<LessonInfo | LessonInfo[]> {
  return lessons.sort((a, b) => (a.weekday - b.weekday) || (a.start - b.start))
    .reduce((acc, l) => {
      const p = acc.length > 0 ? acc[acc.length - 1] : undefined;
      if(Array.isArray(p)) {
        if(p.some(a => a.weekday === l.weekday && a.end > l.start)) {
          p.push(l);
        } else {
          acc.push(l);
        }
      } else if(p?.weekday === l.weekday && p.end > l.start) {
        acc.pop();
        acc.push([p, l]);
      } else {
        acc.push(l);
      }
      return acc;
    }, [] as Array<LessonInfo | LessonInfo[]>);
}

export function time2Seconds(time: string): number {
  const hs = time.split(':').map(Number);
  return hs.length === 2 ? hs[0] * 3600 + hs[1] * 60 : 0;
}

export function seconds2Time(seconds: number): string {
  return `${Math.floor(seconds / 3600).toString().padStart(2, "0")}:${(seconds % 3600 / 60).toString().padStart(2, "0")}`;
}

export function time2Percent(time: number, regionLeft?: number, regionRight?: number): number {
  regionLeft = regionLeft ?? commonClassStamp[1][0] / 1000;
  regionRight = regionRight ?? commonClassStamp[14][1] / 1000;
  let total = 0, acc = 0;
  commonClassStamp.slice(1).forEach(se => {
    let left = Math.max(se[0] / 1000, regionLeft!), right = Math.min(se[1] / 1000, regionRight!);
    if(right > left) {
      total += right - left;
    }
    let accRight = Math.min(se[1] / 1000, time);
    if(accRight > left) {
      acc += accRight - left;
    }
  })
  return acc / total * 100;
}

export const fillInformationJS = `
(() => {
    const inputUID = infoProvider.getUID();
    const inputPwd = infoProvider.getPassword();
    const main = () => {
        const nodeUID = document.getElementById('nameInput');
        const nodePassword = document.querySelector('input[type="password"][maxlength="200"]');
        if (nodeUID && nodePassword) {
            if (inputPwd) {
              document.querySelector('div.eyes-icon.ng-star-inserted').style.pointerEvents = 'none';
            }
            nodeUID.focus();
            nodeUID.value = infoProvider.getUID();
            nodeUID.dispatchEvent(new Event('input', { bubbles: true }));
            nodePassword.focus();
            nodePassword.value = infoProvider.getPassword();
            nodePassword.dispatchEvent(new Event('input', { bubbles: true }));
            document.getElementById('submitBtn').dispatchEvent(
                new MouseEvent('click', { bubbles: true, cancelable: true })
            );
            return true;
        } else { return false; }
    }
    if (main()) { return; }
    const observer = new MutationObserver(() => {
        if (main()) { observer.disconnect(); }
    });
    observer.observe(document.body, { childList: true, subtree: true });
})();
`

// 删除智慧门户中的AI助手
export const deleteAIHelper: string = `
function removeTargetElement() {
    const targetElement = Array.from(document.querySelectorAll('.dh-cl-item-name')).find(
        el => el.textContent.trim() === "AI助手"
    );
    if (targetElement) {
        const parentItem = targetElement.closest('.dh-cl-item');
        if (parentItem) {
            parentItem.remove();
            return true;
        }
    }
    return false;
}
const isRemoved = removeTargetElement();
if (!isRemoved || true) {
    const observerConfig = {
        childList: true,
        subtree: true
    };
    const callback = function(mutationsList) {
        for(let mutation of mutationsList) {
            if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
                removeTargetElement();
            }
        }
    };
    const observer = new MutationObserver(callback);
    const targetNode = document.querySelector('.hd-zs') || document.body;
    observer.observe(targetNode, observerConfig);
    setTimeout(() => {
        observer.disconnect();
        console.log('监听超时，已停止');
    }, 10000);
}
`
