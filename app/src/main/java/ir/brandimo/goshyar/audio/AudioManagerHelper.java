package ir.brandimo.goshyar.audio;

import android.content.Context;
import android.media.AudioAttributes;
import android.media.AudioFormat;
import android.media.AudioTrack;
import android.media.MediaPlayer;
import android.media.SoundPool;
import android.os.Handler;
import android.os.Looper;

public class AudioManagerHelper {

    private static AudioManagerHelper instance;
    private Context context;
    private SoundPool soundPool;
    private MediaPlayer bgMediaPlayer;
    private boolean isMusicEnabled = true;
    private boolean isSfxEnabled = true;

    private AudioManagerHelper() {}

    public static synchronized AudioManagerHelper getInstance() {
        if (instance == null) {
            instance = new AudioManagerHelper();
        }
        return instance;
    }

    public void init(Context context) {
        this.context = context.getApplicationContext();
        
        AudioAttributes audioAttributes = new AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_GAME)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build();

        soundPool = new SoundPool.Builder()
                .setMaxStreams(5)
                .setAudioAttributes(audioAttributes)
                .build();
    }

    public void playTone(double frequency, int durationMs) {
        if (!isSfxEnabled) return;

        new Thread(() -> {
            try {
                int sampleRate = 44100;
                int numSamples = (sampleRate * durationMs) / 1000;
                double[] sample = new double[numSamples];
                byte[] generatedSnd = new byte[2 * numSamples];

                for (int i = 0; i < numSamples; ++i) {
                    sample[i] = Math.sin(2 * Math.PI * i / (sampleRate / frequency));
                }

                int idx = 0;
                for (final double dVal : sample) {
                    final short val = (short) ((dVal * 32767));
                    generatedSnd[idx++] = (byte) (val & 0x00ff);
                    generatedSnd[idx++] = (byte) ((val & 0xff00) >> 8);
                }

                AudioTrack audioTrack = new AudioTrack.Builder()
                        .setAudioAttributes(new AudioAttributes.Builder()
                                .setUsage(AudioAttributes.USAGE_GAME)
                                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                                .build())
                        .setAudioFormat(new AudioFormat.Builder()
                                .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                                .setSampleRate(sampleRate)
                                .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                                .build())
                        .setBufferSizeInBytes(generatedSnd.length)
                        .setTransferMode(AudioTrack.MODE_STATIC)
                        .build();

                audioTrack.write(generatedSnd, 0, generatedSnd.length);
                audioTrack.play();

                new Handler(Looper.getMainLooper()).postDelayed(() -> {
                    audioTrack.release();
                }, durationMs + 100);

            } catch (Exception e) {
                e.printStackTrace();
            }
        }).start();
    }

    public void playSuccessSound() {
        playTone(523.25, 150); // C5
        new Handler(Looper.getMainLooper()).postDelayed(() -> playTone(659.25, 250), 150); // E5
    }

    public void playFailSound() {
        playTone(300.0, 200);
        new Handler(Looper.getMainLooper()).postDelayed(() -> playTone(220.0, 300), 200);
    }

    public void setMusicEnabled(boolean enabled) {
        this.isMusicEnabled = enabled;
    }

    public boolean isMusicEnabled() {
        return isMusicEnabled;
    }

    public void setSfxEnabled(boolean enabled) {
        this.isSfxEnabled = enabled;
    }

    public boolean isSfxEnabled() {
        return isSfxEnabled;
    }
}
