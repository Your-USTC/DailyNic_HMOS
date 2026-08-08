import {
  BasicDir,
  AnswerFileName,
  singleQuestion,
  answerMark,
  answerRecord,
  answerSession,
  answerSessionAttribute,
  sessionSummary,
  questionStatus,
  AnswerStatus,
  PracticeMode
} from './constants';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { getQuestions } from './TestManager';

function ensureDir(uuid: string): void {
  const dirPath = BasicDir + uuid + '/';
  if (!fileIo.accessSync(dirPath)) {
    fileIo.mkdirSync(dirPath, true);
  }
}

function readSessionsFromDisk(uuid: string): answerSession[] {
  const filePath = BasicDir + uuid + '/' + AnswerFileName;
  try {
    const text = fileIo.readTextSync(filePath);
    return JSON.parse(text) as answerSession[];
  } catch (e) {
    return [];
  }
}

function writeSessionsToDisk(uuid: string, sessions: answerSession[]): void {
  ensureDir(uuid);
  const filePath = BasicDir + uuid + '/' + AnswerFileName;
  const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
  fileIo.writeSync(file.fd, JSON.stringify(sessions));
  fileIo.closeSync(file);
}

function buildShuffledOrder(count: number): number[] {
  const pool: number[] = [];
  for (let i = 0; i < count; i++) {
    pool.push(i);
  }
  const order: number[] = [];
  while (pool.length > 0) {
    const rand = Math.floor(Math.random() * pool.length);
    order.push(pool[rand]);
    pool.splice(rand, 1);
  }
  return order;
}

export class AnswerSessionStore {
  private sessions: Map<string, answerSession[]> = new Map();
  private dirty: Set<string> = new Set();

  private isLoaded(uuid: string): boolean {
    return this.sessions.has(uuid);
  }

  private ensureLoaded(uuid: string): void {
    if (!this.isLoaded(uuid)) {
      this.load(uuid);
    }
  }

  get(uuid: string, sessionId: string): answerSession | null {
    this.ensureLoaded(uuid);
    const list = this.sessions.get(uuid)!;
    for (let i = 0; i < list.length; i++) {
      if (list[i].sessionId === sessionId) {
        return list[i];
      }
    }
    return null;
  }

  list(uuid: string): answerSession[] {
    this.ensureLoaded(uuid);
    return this.sessions.get(uuid)!;
  }

  create(uuid: string, mode: PracticeMode, starredOnly: boolean): string {
    const questions = getQuestions(uuid);
    if (questions.length === 0) {
      return '';
    }

    this.ensureLoaded(uuid);
    const list = this.sessions.get(uuid)!;

    const marks: answerMark[] = questions.map((q: singleQuestion): answerMark => ({
      starred: false,
      ignore: false
    }));

    const questionNO: number[] = mode === 'ordered'
      ? Array.from<number, number>({ length: questions.length }, (_, i) => i)
      : buildShuffledOrder(questions.length);

    const sessionId = util.generateRandomUUID();
    list.push({
      sessionId: sessionId,
      lastAnswerTime: 0,
      mode: mode,
      starred: starredOnly,
      marks: marks,
      questionNO: questionNO,
      answers: [],
      currentIndex: 0
    });

    this.dirty.add(uuid);
    return sessionId;
  }

  submitAnswer(uuid: string, sessionId: string, userAnswer: string): boolean {
    const session = this.get(uuid, sessionId);
    if (!session || !session.questionNO || session.currentIndex >= session.questionNO.length) {
      return false;
    }

    const questions = getQuestions(uuid);
    const qIndex = session.questionNO[session.currentIndex];
    if (qIndex < 0 || qIndex >= questions.length) {
      return false;
    }

    const correctAnswer = questions[qIndex].answer.trim().toUpperCase();
    const isCorrect = userAnswer.trim().toUpperCase() === correctAnswer;

    session.answers.push({
      questionIndex: qIndex,
      userAnswer: userAnswer,
      isCorrect: isCorrect,
      timestamp: Date.now()
    });
    session.currentIndex++;
    session.lastAnswerTime = Date.now();

    this.dirty.add(uuid);
    return isCorrect;
  }

  toggleStar(uuid: string, sessionId: string, questionIndex: number): void {
    const session = this.get(uuid, sessionId);
    if (!session || questionIndex < 0 || questionIndex >= session.marks.length) {
      return;
    }
    session.marks[questionIndex].starred = !session.marks[questionIndex].starred;
    this.dirty.add(uuid);
  }

  getCurrentQuestion(uuid: string, sessionId: string): singleQuestion | null {
    const session = this.get(uuid, sessionId);
    if (!session || !session.questionNO || session.currentIndex >= session.questionNO.length) {
      return null;
    }
    const questions = getQuestions(uuid);
    const qIndex = session.questionNO[session.currentIndex];
    if (qIndex < 0 || qIndex >= questions.length) {
      return null;
    }
    return questions[qIndex];
  }

  isFinished(uuid: string, sessionId: string): boolean {
    const session = this.get(uuid, sessionId);
    if (!session || !session.questionNO) {
      return true;
    }
    return session.currentIndex >= session.questionNO.length;
  }

  getProgress(uuid: string, sessionId: string): sessionSummary {
    const session = this.get(uuid, sessionId);
    if (!session) {
      return { sessionId: '', total: 0, answered: 0, correct: 0, wrong: 0 };
    }
    const answered = session.answers.length;
    let correct = 0;
    for (let i = 0; i < session.answers.length; i++) {
      if (session.answers[i].isCorrect) {
        correct++;
      }
    }
    return {
      sessionId: session.sessionId,
      total: session.questionNO ? session.questionNO.length : 0,
      answered: answered,
      correct: correct,
      wrong: answered - correct
    };
  }

  getSummaries(uuid: string): sessionSummary[] {
    this.ensureLoaded(uuid);
    const list = this.sessions.get(uuid)!;
    const summaries: sessionSummary[] = [];
    for (let i = 0; i < list.length; i++) {
      summaries.push(this.getProgress(uuid, list[i].sessionId));
    }
    return summaries;
  }

  createRetry(uuid: string, originalSessionId: string,
    retryIncorrect: boolean, retryStarred: boolean): string {
    const original = this.get(uuid, originalSessionId);
    if (!original) {
      return '';
    }

    const questions = getQuestions(uuid);
    const targetIndices: number[] = [];

    for (let i = 0; i < questions.length; i++) {
      let include = false;

      if (retryIncorrect) {
        for (let j = 0; j < original.answers.length; j++) {
          if (original.answers[j].questionIndex === i && !original.answers[j].isCorrect) {
            include = true;
            break;
          }
        }
      }

      if (retryStarred && original.marks[i] && original.marks[i].starred) {
        include = true;
      }

      if (include) {
        targetIndices.push(i);
      }
    }

    if (targetIndices.length === 0) {
      return '';
    }

    this.ensureLoaded(uuid);
    const list = this.sessions.get(uuid)!;

    const marks: answerMark[] = questions.map((q: singleQuestion): answerMark => ({
      starred: false,
      ignore: false
    }));

    const sessionId = util.generateRandomUUID();
    list.push({
      sessionId: sessionId,
      lastAnswerTime: 0,
      mode: 'incorrect',
      starred: retryStarred && !retryIncorrect,
      marks: marks,
      questionNO: targetIndices,
      answers: [],
      currentIndex: 0
    });

    this.dirty.add(uuid);
    return sessionId;
  }

  deleteSession(uuid: string, sessionId: string): void {
    this.ensureLoaded(uuid);
    const list = this.sessions.get(uuid)!;
    for (let i = 0; i < list.length; i++) {
      if (list[i].sessionId === sessionId) {
        list.splice(i, 1);
        this.dirty.add(uuid);
        return;
      }
    }
  }

  jumpTo(uuid: string, sessionId: string, targetIndex: number): singleQuestion | null {
    const session = this.get(uuid, sessionId);
    if (!session || !session.questionNO || targetIndex < 0 || targetIndex >= session.questionNO.length) {
      return null;
    }
    session.currentIndex = targetIndex;
    this.dirty.add(uuid);
    return this.getCurrentQuestion(uuid, sessionId);
  }

  getRecords(uuid: string, sessionId: string): answerRecord[] {
    const session = this.get(uuid, sessionId);
    return session ? session.answers : [];
  }

  getQuestionStatus(uuid: string, sessionId: string): questionStatus[] {
    const session = this.get(uuid, sessionId);
    if (!session || !session.questionNO) {
      return [];
    }
    const answerMap: Record<number, answerRecord> = {};
    for (let i = 0; i < session.answers.length; i++) {
      answerMap[session.answers[i].questionIndex] = session.answers[i];
    }
    const result: questionStatus[] = [];
    for (let i = 0; i < session.questionNO.length; i++) {
      const qIndex = session.questionNO[i];
      const record = answerMap[qIndex];
      result.push({
        questionIndex: qIndex,
        status: record ? (record.isCorrect ? 'correct' : 'wrong') : 'unanswered',
        starred: session.marks[qIndex]?.starred ?? false,
        userAnswer: record ? record.userAnswer : undefined
      });
    }
    return result;
  }

  load(uuid: string): void {
    const list = readSessionsFromDisk(uuid);
    this.sessions.set(uuid, list);
    this.dirty.delete(uuid);
  }

  save(uuid: string): void {
    const list = this.sessions.get(uuid);
    if (list === undefined) {
      return;
    }
    writeSessionsToDisk(uuid, list);
    this.dirty.delete(uuid);
  }

  saveAll(): void {
    const keys = Array.from(this.dirty);
    for (let i = 0; i < keys.length; i++) {
      this.save(keys[i]);
    }
  }

  isDirty(uuid: string): boolean {
    return this.dirty.has(uuid);
  }

  release(uuid: string): void {
    this.sessions.delete(uuid);
    this.dirty.delete(uuid);
  }
}

export const answerStore = new AnswerSessionStore();