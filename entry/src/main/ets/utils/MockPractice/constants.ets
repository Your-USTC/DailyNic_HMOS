export const BasicDir = '/data/storage/el2/base/files/MockPractice/';
export const TestAttributeFileName = 'Attributes.json';
export const QuestionFileName = 'QuestionList.json';
export const AnswerFileName = 'AnswerRounds.json';

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