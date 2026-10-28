// Headless CMAS tone player. Run via app_process:
//   CLASSPATH=play.dex app_process /system/bin Play <audio-file> [ms]
// Plays on the ALARM usage so it comes out loud like a real emergency alert.
import android.media.MediaPlayer;
import android.media.AudioAttributes;

public class Play {
    public static void main(String[] a) throws Exception {
        MediaPlayer mp = new MediaPlayer();
        mp.setAudioAttributes(new AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build());
        mp.setDataSource(a[0]);
        mp.setLooping(true);
        mp.prepare();
        mp.setVolume(1f, 1f);
        mp.start();
        Thread.sleep(a.length > 1 ? Integer.parseInt(a[1]) : 9000);
        mp.stop();
        mp.release();
    }
}
