import { readDataFromCsv, getObjectFromCsv } from './DataTransformer';
import { createTest } from './TestManager';
import { singleQuestion } from './constants';
import { hostContext } from '../../constants/BasicConstants';

export async function importNewTest(title: string, context: UIContext) {
  const data: singleQuestion[] = getObjectFromCsv(await readDataFromCsv(hostContext()));
  if (data.length === 0) {
    return;
  }
  createTest(data, title);
}