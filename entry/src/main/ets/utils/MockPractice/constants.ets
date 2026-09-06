export const BasicDir = '/data/storage/el2/base/files/MockPractice/';
export const TestAttributeFileName = 'Attributes.json';
export const QuestionFileName = 'QuestionList.json';
export const AnswerFileName = 'AnswerRounds.json';

/** 表示 CSV 导入时某一列不参与映射 */
export const CSV_UNUSED_COLUMN: number = -1;

/**
 * CSV 各列的语义映射，取值为从 1 开始的列号，CSV_UNUSED_COLUMN 表示不使用。
 * optionStart 为第一道选项（如"选项A"）所在列，选项按其后的连续列依次读取。
 */
export interface csvColumnMapping {
  section: number,
  type: number,
  context: number,
  answer: number,
  analysis: number,
  difficulty: number,
  knowledgePoint: number,
  optionCount: number,
  optionStart: number
}

export interface csvImportConfig {
  /** 第一条数据所在行（从 1 开始计数） */
  startRow: number,
  columns: csvColumnMapping
}

/**
 * 目录结构：
 * - MockPractice
 *   - uuid1
 *     - Attributes.json   // 基本属性
 *     - QuestionList.json // 问题列表
 *     - AnswerRounds.json // 作答情况
 *   - uuid2
 */

export interface answerMark {
  starred: boolean,
  ignore: boolean
}

export interface singleQuestion extends answerMark {
  section: string,
  context: string,
  type: 'single' | 'multiple' | 'blank',
  answer: string,
  analysis?: string,
  difficulty?: string,
  knowledgePoint?: string,
  optionCount: number,
  options: string[]
}

export type PracticeMode = 'ordered' | 'random' | 'incorrect'

export interface answerSessionAttribute {
  lastAnswerTime: number,
  mode: PracticeMode,
  starred: boolean,
  marks: answerMark[],
  questionNO?: number[]
}

export interface answerRecord {
  questionIndex: number
  userAnswer: string
  isCorrect: boolean
  timestamp: number
}

export interface answerSession extends answerSessionAttribute {
  sessionId: string
  answers: answerRecord[]
  currentIndex: number
}

export interface sessionSummary {
  sessionId: string
  total: number
  answered: number
  correct: number
  wrong: number
}

export interface testAttributeUpdate {
  name?: string,
  createTime?: number,
  lastOpenTime?: number,
}

export interface testAttribute {
  name: string,
  createTime: number,
  lastOpenTime: number,
  uuid: string,
}

export interface fullID {
  name: string
  test: string
  answer: string
}

export type AnswerStatus = 'correct' | 'wrong' | 'unanswered'

export interface questionStatus {
  questionIndex: number
  status: AnswerStatus
  starred: boolean
  userAnswer?: string
}