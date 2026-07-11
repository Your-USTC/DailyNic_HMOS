import {
  BasicDir,
  QuestionFileName,
  singleQuestion,
  testAttribute,
  testAttributeUpdate,
  TestAttributeFileName
} from "./constants";
import { fileIo } from "@kit.CoreFileKit";
import { util } from '@kit.ArkTS';

function ensureBaseDir(): void {
  if (!fileIo.accessSync(BasicDir)) {
    fileIo.mkdirSync(BasicDir, true);
  }
}

export function createTest(questionsList: singleQuestion[], name: string): string {
  ensureBaseDir();
  let uuid = util.generateRandomUUID();
  let dirPath = BasicDir + uuid + '/';
  while (fileIo.accessSync(dirPath)) {
    uuid = util.generateRandomUUID();
    dirPath = BasicDir + uuid + '/';
  }

  fileIo.mkdirSync(dirPath, true);
  let file = fileIo.openSync(dirPath + QuestionFileName, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
  fileIo.writeSync(file.fd, JSON.stringify(questionsList));
  fileIo.closeSync(file);

  const basicInfo: testAttribute = {
    uuid: uuid,
    name: name,
    createTime: Date.now(),
    lastOpenTime: 0,
  };

  file = fileIo.openSync(dirPath + TestAttributeFileName, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
  fileIo.writeSync(file.fd, JSON.stringify(basicInfo));
  fileIo.closeSync(file);
  return uuid;
}

export function getAllTest(): testAttribute[] {
  const result: testAttribute[] = [];
  ensureBaseDir();
  const allTestUuid: string[] = fileIo.listFileSync(BasicDir);
  allTestUuid.forEach((singleTestUuid: string) => {
    const attributePath = BasicDir + singleTestUuid + '/' + TestAttributeFileName;
    if (!fileIo.accessSync(attributePath)) {
      return;
    }
    try {
      let content = fileIo.readTextSync(attributePath);
      if (content.trim()) {
        result.push(JSON.parse(content) as testAttribute);
      }
    } catch (e) {
      console.error('Failed to read test attribute for ' + singleTestUuid);
    }
  })
  return result;
}

export function getQuestions(uuid: string): singleQuestion[] {
  const path = BasicDir + uuid + '/' + QuestionFileName;
  try {
    const text = fileIo.readTextSync(path);
    return JSON.parse(text) as singleQuestion[];
  } catch (e) {
    console.error('Failed to read questions for ' + uuid);
    return [];
  }
}

export function getTestAttribute(uuid: string): testAttribute | null {
  const path = BasicDir + uuid + '/' + TestAttributeFileName;
  try {
    const text = fileIo.readTextSync(path);
    return JSON.parse(text) as testAttribute;
  } catch (e) {
    console.error('Failed to read test attribute for ' + uuid);
    return null;
  }
}

export function updateTestAttribute(uuid: string, attr: testAttributeUpdate): void {
  const path = BasicDir + uuid + '/' + TestAttributeFileName;
  const current = getTestAttribute(uuid);
  if (!current) {
    return;
  }
  const updated: testAttribute = {
    uuid: current.uuid,
    name: attr.name !== undefined ? attr.name : current.name,
    createTime: attr.createTime !== undefined ? attr.createTime : current.createTime,
    lastOpenTime: attr.lastOpenTime !== undefined ? attr.lastOpenTime : current.lastOpenTime,
  };
  const file = fileIo.openSync(path, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
  fileIo.writeSync(file.fd, JSON.stringify(updated));
  fileIo.closeSync(file);
}

export function updateQuestions(uuid: string, questions: singleQuestion[]): void {
  const path = BasicDir + uuid + '/' + QuestionFileName;
  if (!fileIo.accessSync(path)) {
    return;
  }
  const file = fileIo.openSync(path, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
  fileIo.writeSync(file.fd, JSON.stringify(questions));
  fileIo.closeSync(file);
}

export function removeTest(uuid: string): void {
  const dirPath = BasicDir + uuid + '/';
  if (fileIo.accessSync(dirPath)) {
    fileIo.rmdirSync(dirPath);
  }
}