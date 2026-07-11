import { BasicDir, QuestionFileName, singleQuestion, testAttribute, TestAttributeFileName } from "./constants";
import { fileIo } from "@kit.CoreFileKit";
import { util } from '@kit.ArkTS';

export function createTest(questionsList: singleQuestion[]): string {
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
    name: 'test',
    createTime: Date.now(),
    lastOpenTime: 0,
  };

  file = fileIo.openSync(dirPath + TestAttributeFileName, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
  fileIo.writeSync(file.fd, JSON.stringify(basicInfo));
  return uuid;
}

export function getAllTest(): testAttribute[] {
  const result: testAttribute[] = [];
  const allTestUuid: string[] = fileIo.listFileSync(BasicDir);
  allTestUuid.forEach((singleTestUuid: string) => {
    const testDir: string = BasicDir + singleTestUuid + '/';
    console.log('excel ' + testDir);
    result.push(JSON.parse(fileIo.readTextSync(testDir + TestAttributeFileName)) as testAttribute);
  })
  return result;
}

export function removeTest(uuid: string) {
  fileIo.rmdir(BasicDir + uuid);
}