
import UnifiedPreferences from './UnifyPreference';
import { fileIo, fileUri, ListFileOptions } from "@kit.CoreFileKit";
import { photoAccessHelper } from '@kit.MediaLibraryKit';

// [浅色标题背景，深色标题背景，通用按钮和进度条背景]
export const presetColor: string[][] = [
  ['#BEDCF0', '#102542', '#4A90E2', '冰山蓝调'],
  ['#D7CDF0', '#2A3166', '#6B5B9A', '深海回音'],
  ['#E6E6FA', '#4B0082', '#9B6BB6', '薰衣草田'],
  ['#ECEFF1', '#263238', '#5F7A8A', '冷石流云'],
  ['#F8F9FA', '#202124', '#5F6368', '纸墨绘世'],
  ['#F5D7D7', '#A11616', '#D81B60', '桃启绯英'],
  ['#FFF0F6', '#831843', '#EC407A', '樱吹甜心'],
  ['#FFD1D1', '#822727', '#B84D4D', '雪映残梅'],
  ['#FFF4E0', '#8B4513', '#C37B4A', '古卷檀香'],
  ['#FFDAB9', '#B94E2E', '#E07A4F', '落日熔金'],
  ['#FFF9C4', '#F57F17', '#F9A825', '流光掠影'],
  ['#FAFAD2', '#7A5B00', '#B8860B', '雨润杏帘'],
  ['#BEF0C8', '#556B2F', '#7C9C5E', '森屿青柠'],
  ['#F0FFF0', '#1B5E20', '#4C8B4C', '竹林月夜'],
  ['#E0F7FA', '#006064', '#2C8B9A', '青琉碧落']
];

class BackgroundImage {
  pic: ResourceStr | undefined = undefined;
  showImage: boolean = UnifiedPreferences.getBoolSync('ShowImage', false); // 是否展示
  imgPath: string = UnifiedPreferences.getSync('ImagePath', ''); // 图片路径
  basicDir: string = '/data/storage/el2/base/files';
  blurLevel: BlurStyle | undefined = undefined;
  opacityLevel: number = 1;
  backgroundBlur: boolean = UnifiedPreferences.getBoolSync('BackgroundBlur', true); // 选择背景模糊
  themeColor: number = UnifiedPreferences.getNumberSync('ThemeColor', 0);
  brightness: number = 1;

  avatar: ResourceStr = $r('app.media.avatar_placeholder');
  avatarPath: string = UnifiedPreferences.getSync('AvatarPath', '');
  /**
   * 初始化
   * @param context 传入上下文
   */
  async init(context: Context) {
    try {
      if (this.imgPath === '' || !fileIo.accessSync(this.imgPath))
        this.showImage = false;
    } catch {
      this.showImage = false;
    }
    if (this.showImage) {
      this.pic = fileUri.getUriFromPath(this.imgPath);
      if (this.backgroundBlur) { // 如果选择背景模糊
        this.blurLevel = UnifiedPreferences.getNumberSync('BlurLevel', BlurStyle.COMPONENT_REGULAR);
        // this.opacityLevel = 1;
      } else { // 如果选择背景透明
        // this.blurLevel = undefined;
        this.opacityLevel = UnifiedPreferences.getNumberSync('OpacityLevel', 100) / 100;
      }
      this.brightness = UnifiedPreferences.getNumberSync('BackgroundBrightness', 100) / 100;
    } else {
      this.pic = undefined;
      // this.blurLevel = undefined;
      // this.opacityLevel = 1;
    }

    if (this.avatarPath !== '') {
      this.avatar = fileUri.getUriFromPath(this.avatarPath);
    }
    this.basicDir = context.filesDir;
  }

  deleteBackgroundImage() {
    if (this.imgPath !== '' && fileIo.accessSync(this.imgPath)) {
      try {
        fileIo.unlinkSync(this.imgPath);
      } catch (e) {
        console.error('Failed to delete file');
      }
    }
    this.imgPath = '';
    this.showImage = false;
    UnifiedPreferences.putSync('ImagePath', '', false);
    UnifiedPreferences.putSync('ShowImage', false, false);
    UnifiedPreferences.flush();
  }

  async pickAvatar() {
    try {
      const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;
      const photoPicker = new photoAccessHelper.PhotoViewPicker();
      const photoSelectResult: photoAccessHelper.PhotoSelectResult = await photoPicker.select(photoSelectOptions);
      if (photoSelectResult.photoUris[0] !== undefined) {
        // 删除旧的
        const listFileOption: ListFileOptions = {
          filter: { displayName: ['avatarImage_*'] }
        };
        fileIo.listFileSync(this.basicDir, listFileOption).forEach((value, index) => {
          fileIo.unlinkSync(`${this.basicDir}/${value}`);
        });
        const oriImgPath = new fileUri.FileUri(photoSelectResult.photoUris[0]).path;
        this.avatarPath = this.basicDir + `/avatarImage_${Date.now()}`;
        fileIo.copyFileSync(oriImgPath, this.avatarPath);
        this.avatar = fileUri.getUriFromPath(this.avatarPath);
        UnifiedPreferences.putSync('AvatarPath', this.avatarPath);
      }
    } catch (error) {
      console.error(`PhotoViewPicker failed: ${JSON.stringify(error)}`);
    }
  }

  deleteAvatar() {
    if (this.avatarPath !== '') {
      try {
        fileIo.unlinkSync(this.avatarPath);
      } catch (e) {
        console.error('Failed to delete file');
      }
    }
    this.avatar = $r('app.media.avatar_placeholder');
    UnifiedPreferences.putSync('AvatarPath', '');
  }
}

export default new BackgroundImage();