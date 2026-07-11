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

interface answerMark {
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

export interface answerSessionAttribute {
  lastAnswerTime: number,
  mode: 'ordered' | 'random' | 'incorrect',
  starred: boolean,
  marks: answerMark[],
  questionNO?: number[] // 仅针对错题 incorrect
}

export interface testAttribute {
  name: string,
  createTime: number,
  lastOpenTime: number, // 0 表示未作答过
  uuid: string,
}