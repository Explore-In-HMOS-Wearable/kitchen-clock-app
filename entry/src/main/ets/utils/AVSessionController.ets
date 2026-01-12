import { common, wantAgent } from '@kit.AbilityKit';
import { avSession } from '@kit.AVSessionKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { SongData } from '../model/SongData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { audioDomain, audioPrefix, MediaController } from './MediaController';

export class AVSessionController {
  private context: common.UIAbilityContext | undefined = undefined;
  private avSession: avSession.AVSession | undefined = undefined;
  private songList: SongData[] = [];
  private musicIndex: number | undefined = undefined;
  private mediaController: MediaController | undefined = undefined;

  constructor() {
    let list: SongData[] | undefined = AppStorage.get('songList');
    if (list) {
      this.songList = list;
    }
    this.initAVSession();
  }

  public static getInstance(): AVSessionController {
    let avSessionController: AVSessionController | undefined = AppStorage.get('AVSessionController');
    if (!avSessionController) {
      avSessionController = new AVSessionController();
      AppStorage.setOrCreate<AVSessionController>('AVSessionController', avSessionController);
    }
    return avSessionController;
  }


  private async initAVSession() {
    this.context = AppStorage.get('context');
    if (!this.context) {
      hilog.info(audioDomain, audioPrefix, `session create failed : conext is undefined`);
      return;
    }
    this.mediaController = AppStorage.get('mediaController');
    if (!this.mediaController) {
      hilog.info(audioDomain, audioPrefix, `session create failed : mediaController is undefined`);
      return;
    }
    this.avSession = await avSession.createAVSession(this.context, 'PLAY_AUDIO', 'audio');
    await this.avSession.activate();
    hilog.info(audioDomain, audioPrefix, `session create successed : sessionId : ${this.avSession.sessionId}`);
    await this.setAVMetadata();
    this.setLaunchAbility();
    this.setListenerForMesFromController();
  }

  private setLaunchAbility() {
    if (!this.context) {
      return;
    }
    let wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: this.context.abilityInfo.bundleName,
          abilityName: this.context.abilityInfo.name
        }
      ],
      actionType: wantAgent.OperationType.START_ABILITIES,
      requestCode: 0,
      wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };
    wantAgent.getWantAgent(wantAgentInfo).then((agent) => {
      if (this.avSession) {
        this.avSession.setLaunchAbility(agent);
      }
    });
  }

  private getFirst(): boolean | undefined {
    if (!this.mediaController) {
      return undefined;
    }
    return this.mediaController.getFirst();
  }

  public async setAVMetadata() {
    this.musicIndex = AppStorage.get('selectIndex');
    hilog.info(audioDomain, audioPrefix, `current musicIndex is:  ${this.musicIndex}`);
    if (this.musicIndex === undefined) {
      this.musicIndex = 0;
    }
    try {
      if (this.context) {
        let metadata: avSession.AVMetadata = {
          assetId: `${this.musicIndex}`,
          title: this.songList[this.musicIndex].title,
          artist: this.songList[this.musicIndex].artist,
          duration: this.getDuration()
        };
        if (this.avSession) {
          this.avSession.setAVMetadata(metadata).then(() => {
            hilog.info(audioDomain, audioPrefix, 'SetAVMetadata successfully');
          }).catch((err: BusinessError) => {
            hilog.error(audioDomain, audioPrefix,
              `SetAVMetadata BusinessError: code: ${err.code}, message: ${err.message}`);
          });
        }
      }
    } catch (error) {
      hilog.error(audioDomain, audioPrefix, `SetAVMetadata try: code: ${(error as BusinessError).code}`);
    }
  }

  async setListenerForMesFromController() {
    if (!this.avSession) {
      return;
    }
    this.avSession.on('play', this.playCall);
    this.avSession.on('pause', this.pauseCall);
    this.avSession.on('playNext', this.playNextCall);
    this.avSession.on('playPrevious', this.playPreviousCall);
    this.avSession.on('seek', this.seekCall);
  }

  private playCall: () => void = () => {
    hilog.info(audioDomain, audioPrefix, `on play , do play task`);
    if (!this.mediaController) {
      hilog.error(audioDomain, audioPrefix, 'mediaController is undefined in playCall');
      return;
    }
    if (this.getFirst()) {
      this.mediaController.startByIndex();
    } else {
      this.mediaController.resume()
    }
  }
  private pauseCall: () => void = () => {
    hilog.info(audioDomain, audioPrefix, `on pause , do pause task`);
    if (!this.mediaController) {
      hilog.error(audioDomain, audioPrefix, 'mediaController is undefined in pauseCall');
      return;
    }
    this.mediaController.pause();
  }
  private playNextCall: () => void = () => {
    hilog.info(audioDomain, audioPrefix, `on playNext , do playNext task`);
    if (!this.mediaController) {
      hilog.error(audioDomain, audioPrefix, 'mediaController is undefined in playNextCall');
      return;
    }
    this.mediaController.playNext();
  }
  private playPreviousCall: () => void = () => {
    hilog.info(audioDomain, audioPrefix, `on playPrevious , do playPrevious task`);
    if (!this.mediaController) {
      hilog.error(audioDomain, audioPrefix, 'mediaController is undefined in playPreviousCall')
      return;
    }
    this.mediaController.playPrevious();
  }
  private seekCall: (curMs: number) => void = (curMs: number) => {
    hilog.info(audioDomain, audioPrefix, `on seek , do seek task`);
    if (!this.mediaController) {
      hilog.error(audioDomain, audioPrefix, 'mediaController is undefined in seekCall');
      return;
    }
    this.mediaController.seek(curMs);
  }

  private getDuration(): number | undefined {
    let duration: number | undefined = AppStorage.get('totalMsTime');
    if (!duration) {
      hilog.error(audioDomain, audioPrefix, 'get duration failed');
      return undefined;
    }
    return duration;
  }

  public setProgressState(ms: number) {
    if (this.avSession) {
      this.avSession.setAVPlaybackState({
        position: {
          elapsedTime: ms,
          updateTime: new Date().getTime()
        }
      }, (err: BusinessError) => {
        if (err) {
          hilog.error(audioDomain, audioPrefix,
            `SetAVPlaybackState BusinessError: code: ${err.code}, message: ${err.message}`);
        }
      });
    }
  }

  public setPlayState(isPlay: boolean) {
    if (this.avSession) {
      this.avSession.setAVPlaybackState({
        state: isPlay ? avSession.PlaybackState.PLAYBACK_STATE_PLAY : avSession.PlaybackState.PLAYBACK_STATE_PAUSE
      }, (err: BusinessError) => {
        if (err) {
          hilog.error(audioDomain, audioPrefix,
            `SetAVPlaybackState BusinessError: code: ${err.code}, message: ${err.message}`);
        } else {
          hilog.info(audioDomain, audioPrefix, 'SetAVPlaybackState successfully');
        }
      });
    }
  }

  async unregisterSessionListener() {
    if (!this.avSession) {
      return;
    }
    this.avSession.off('play');
    this.avSession.off('pause');
    this.avSession.off('playNext');
    this.avSession.off('playPrevious');
    this.avSession.off('seek');
  }
}