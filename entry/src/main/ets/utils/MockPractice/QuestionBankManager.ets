/**
 * 题库模块：负责题库的创建、列举、重命名与删除，以及题目内容的读取（带内存缓存）。
 * 题库目录 MockPractice/<uuid>/ 是该题库全部数据的归属地，做题记录文件也存放在其中，
 * 因此 removeBank 删除整个目录时，该题库的做题记录随之一并丢失。
 */
import {
  BasicDir,
  BankAttributeFileName,
  QuestionFileName,
  singleQuestion,
  bankAttribute,
  bankAttributeUpdate
} from './constants';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';

function ensureBaseDir(): void {
  if (!fileIo.accessSync(BasicDir)) {
    fileIo.mkdirSync(BasicDir, true);
  }
}

function readAttribute(bankId: string): bankAttribute | null {
  const path = BasicDir + bankId + '/' + BankAttributeFileName;
  try {
    const text = fileIo.readTextSync(path);
    return JSON.parse(text) as bankAttribute;
  } catch (e) {
    console.error('Failed to read bank attribute for ' + bankId);
    return null;
  }
}

class QuestionBankStore {
  /** 题目内容缓存：作答期间高频读取题目，避免每次都做同步磁盘 IO */
  private questionsCache: Map<string, singleQuestion[]> = new Map();

  createBank(questions: singleQuestion[], name: string): string {
    ensureBaseDir();
    let uuid = util.generateRandomUUID();
    let dirPath = BasicDir + uuid + '/';
    while (fileIo.accessSync(dirPath)) {
      uuid = util.generateRandomUUID();
      dirPath = BasicDir + uuid + '/';
    }

    fileIo.mkdirSync(dirPath, true);
    let file = fileIo.openSync(dirPath + QuestionFileName,
      fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
    fileIo.writeSync(file.fd, JSON.stringify(questions));
    fileIo.closeSync(file);

    const attr: bankAttribute = {
      uuid: uuid,
      name: name,
      createTime: Date.now(),
      lastOpenTime: 0
    };
    file = fileIo.openSync(dirPath + BankAttributeFileName,
      fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
    fileIo.writeSync(file.fd, JSON.stringify(attr));
    fileIo.closeSync(file);

    this.questionsCache.set(uuid, questions);
    return uuid;
  }

  listBanks(): bankAttribute[] {
    const result: bankAttribute[] = [];
    ensureBaseDir();
    const allBankIds: string[] = fileIo.listFileSync(BasicDir);
    for (let i = 0; i < allBankIds.length; i++) {
      const attr = readAttribute(allBankIds[i]);
      if (attr !== null) {
        result.push(attr);
      }
    }
    // 最近导入的题库排在前面
    result.sort((a: bankAttribute, b: bankAttribute): number => b.createTime - a.createTime);
    return result;
  }

  getBankAttribute(bankId: string): bankAttribute | null {
    return readAttribute(bankId);
  }

  updateBankAttribute(bankId: string, patch: bankAttributeUpdate): void {
    const current = readAttribute(bankId);
    if (current === null) {
      return;
    }
    const updated: bankAttribute = {
      uuid: current.uuid,
      name: patch.name !== undefined ? patch.name : current.name,
      createTime: patch.createTime !== undefined ? patch.createTime : current.createTime,
      lastOpenTime: patch.lastOpenTime !== undefined ? patch.lastOpenTime : current.lastOpenTime
    };
    const path = BasicDir + bankId + '/' + BankAttributeFileName;
    const file = fileIo.openSync(path, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
    fileIo.writeSync(file.fd, JSON.stringify(updated));
    fileIo.closeSync(file);
  }

  /** 开始/恢复练习时调用，标记题库最近一次被使用 */
  touchBank(bankId: string): void {
    this.updateBankAttribute(bankId, { lastOpenTime: Date.now() });
  }

  getQuestions(bankId: string): singleQuestion[] {
    const cached = this.questionsCache.get(bankId);
    if (cached !== undefined) {
      return cached;
    }
    const path = BasicDir + bankId + '/' + QuestionFileName;
    try {
      const text = fileIo.readTextSync(path);
      const questions = JSON.parse(text) as singleQuestion[];
      this.questionsCache.set(bankId, questions);
      return questions;
    } catch (e) {
      console.error('Failed to read questions for ' + bankId);
      return [];
    }
  }

  getQuestionCount(bankId: string): number {
    return this.getQuestions(bankId).length;
  }

  bankExists(bankId: string): boolean {
    return fileIo.accessSync(BasicDir + bankId + '/' + BankAttributeFileName);
  }

  /** 删除题库（连同其目录内的全部做题记录）并清空缓存 */
  removeBank(bankId: string): void {
    this.questionsCache.delete(bankId);
    const dirPath = BasicDir + bankId + '/';
    if (fileIo.accessSync(dirPath)) {
      fileIo.rmdirSync(dirPath);
    }
  }
}

export const bankStore = new QuestionBankStore();
